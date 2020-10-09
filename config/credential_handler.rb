require 'jwt'

# This module is used in the Doorkeeper initializer for extracting client credentials upon
# access token request.
module CredentialHandler
  # This method is called automatically by Doorkeeper upon client request for an access token.
  def self.call(request)
    grant_flow = request.parameters[:grant_type]
    raise Doorkeeper::Errors::InvalidTokenStrategy unless grant_flow.present?

    # Extract and handle credentials based on specified grant flow.
    case grant_flow
    when Doorkeeper::OAuth::AUTHORIZATION_CODE
      # Simply extract the sent client id and secret - continued validation of these credentials
      # as well as authorization code validation will happen after automatically for this flow. 
      return request.parameters[:client_id], request.parameters[:client_secret]
    when Doorkeeper::OAuth::CLIENT_CREDENTIALS
      # This flow does not require an authorization code but instead requires JWT validation using JWK sets.
      # This is not functionality supported by Doorkeeper intrinsically, so the custom validation is implemented here.
      # Once the validation handled here passes, the client id and secret are sent along and no further validation is
      # required before Doorkeeper sends an access token for this flow.
      handle_client_credentials_flow(request)
    else
      # Unsupported grant type.
      # NOTE: It should be impossible to get here with Doorkeeper's initial validation.
      raise Doorkeeper::Errors::InvalidTokenStrategy
    end
  end

  # Sara Alert supports the Smart on FHIR Backend Services protocol
  # as described here: https://hl7.org/fhir/uv/bulkdata/authorization/index.html
  # This requires the use client_credentials grant flow with JWT assertions.
  # This method handles authorizing the client by decoding the JWT assertion for the supported client credentials flow. 
  def self.handle_client_credentials_flow(request)
    # Extract signed JWT assertion from client_assertion param.
    # This is what is signed with the client secret and will be used to authorize this request.
    signed_token = request.parameters[:client_assertion]
    raise_missing_param_error('client_assertion') unless signed_token.present?

    # Extract shared client ID.
    if request.parameters[:client_id].present?
      # Check to see if client_id included in params (optional)
      client_id = request.parameters[:client_id]
    else
      # If not, decode the signed token first without validation to obtain the client ID.
      decoded_assertion = JWT.decode(signed_token, nil, false)
      # Grab the JWT payload from the decode output array
      payload = decoded_assertion&.first
      # Both the iss and sub fields should contain the client ID.
      client_id = payload && payload["iss"] ? payload["iss"] : payload["sub"]
    end
    raise_standard_doorkeeper_error("JWT is invalid. Could not extract client ID from iss or sub fields.") unless client_id.present?

    # Find the associated client application. 
    # Return if not found - Doorkeeper will automatically throw invalid_client error in this case.
    client_application = OauthApplication.find_by(uid: client_id)
    return unless client_application.present?
    
    # Find the registered public key set for this client application to decode the JWT assertion.
    if client_application[:public_key_set].present?
      # Public key is stored as JSON, so must be parsed upon retrieval.
      public_key_set = HashWithIndifferentAccess.new(JSON.parse(client_application[:public_key_set]))
      raise_invalid_JWK_error unless public_key_set.present? && public_key_set[:keys].present?
    else
      raise_invalid_JWK_error
    end

    # Get expected JWT aud value: the request token endpoint.
    aud = request.original_url

    # Begin process of decoding and validating JWT assertion required for this flow.
    begin
      # Use JWT library for decoding and validation.
      decoded_token = JWT.decode(
        signed_token,
        nil,
        true,
        { 
          algorithms: ['RS384'],
          jwks: public_key_set,
          iss: client_id,
          verify_iss: true,
          sub: client_id, 
          verify_sub: true,
          aud: aud,
          verify_aud: true,
          verify_jti: proc { |jti| validate_jti(jti, client_application.id) }
        }
      )
  
    rescue JWT::JWKError
      raise_invalid_JWK_error
    rescue JWT::ExpiredSignature
      raise_standard_doorkeeper_error(
        "JWT signature has expired."
      )
    rescue JWT::InvalidIssuerError
      raise_standard_doorkeeper_error(
        "JWT iss is invalid."
      )
    rescue JWT::InvalidSubError
      raise_standard_doorkeeper_error(
        "JWT sub is invalid."
      )
    rescue JWT::InvalidAudError
      raise_standard_doorkeeper_error(
        "JWT aud is invalid."
      )
    rescue JWT::ImmatureSignature
      raise_standard_doorkeeper_error(
        "JWT signature is immature."
      )
    rescue JWT::InvalidJtiError
      raise_standard_doorkeeper_error(
        "JWT jti is invalid. JWT jti value must be unique for your client application."
      )
    rescue JWT::InvalidIatError
      raise_standard_doorkeeper_error(
        "JWT iat is invalid."
      )
    rescue JWT::DecodeError => e
      # Handle other decode related issues e.g. no kid in header, no matching public key found etc.
      raise_standard_doorkeeper_error(
        "Issue decoding JWT assertion. Please verify the correct private key is being used to sign the JWT, and
        that the correct public key(s) are registered with the application. Error message: #{e&.message}"
      )
    end

    # Grab the JWT payload from the decode output array
    payload = decoded_token&.first

    # If the payload is nil for some reason, throw standard error.
    if payload.nil?
      raise_standard_doorkeeper_error(
        "Issue decoding JWT assertion. Please verify the correct private key is being used to sign the JWT, and
        that the correct public key(s) are registered with the application."
      )
    end

    # Validate expiration value is no more than 5 minutes in the future.
    token_expiration = payload["exp"]
    parsed_exp_date = Time.at(token_expiration)

    if parsed_exp_date > Time.now + 5.minutes
      raise_standard_doorkeeper_error(
        "JWT signature is too far in the future. Must be a maximum of 5 minutes in the future."
      )
    end

    # ---- PASSED VALIDATION ----

    # Add jti to table to keep track of previously encountered jti values to prevent replay attacks
    save_jti(payload["jti"], client_application, parsed_exp_date)

    # Find the associated client secret so Doorkeeper can continue with this flow.
    # For the Sara Alert use of this particular flow, the real client secret is not required or used for validation
    # as it is kept by the client and used to sign the asserted JWT. Doorkeeper generates a secret anyway that is used
    # to finish out this flow. 
    client_secret = client_application[:secret]
    return client_id, client_secret
  end

  # Creates a new record in the JwtIdentifier table in the DB to track encountered jti values for a given application
  def self.save_jti(jti, client_app, parsed_exp_date)
    # Create new JWT Identifier for this client oauth app
    client_app.jwt_identifiers.create!(value: jti, expiration_date: parsed_exp_date)
  end

  # Verifies this JTI has not been encountered before
  def self.validate_jti(jti, app_id)
    # Get JTI values for this application - should only be at most 1
    matching_jti_values = JwtIdentifier.where(application_id: app_id, value: jti)
    if matching_jti_values.exists?
      # This is an issue - should not see the same jti within a JWT lifetime. 
      # Do not allow to prevent replay attacks. 
      return false
    end
    return true
  end

  # Commonly raised error for invalid JWK.
  def self.raise_invalid_JWK_error
    raise_standard_doorkeeper_error(
      "Found public JWK set for this application is invalid. Please contact administrators to register valid public key set."
    )
  end

  # Raise a missing param Doorkeeper error. Doorkeeper will handle accordingly. 
  def self.raise_missing_param_error(missing_param)
    raise Doorkeeper::Errors::MissingRequiredParameter.new(missing_param)
  end

  # Raise a standard Doorkeeper error. Doorkeeper will handle accordingly. 
  def self.raise_standard_doorkeeper_error(message)
    raise Doorkeeper::Errors::DoorkeeperError.new(message)
  end
end
