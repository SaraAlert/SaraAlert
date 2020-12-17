---
layout: default
title: Getting Started
parent: API
nav_order: 3
---
<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

## Get Started Using the Sara Alert API
No matter the workflow, in order to use the Sara Alert API and ensure security of application data, the client must go through a three-step process before reading or writing any data.

1. **Registration**: Register as a Client Application with Sara Alert (one-time step). The registration process allows Sara Alert to pre-authorize and curate the clients that will be using the Sara Alert API. Registration is a manual step, as is [traditional](https://tools.ietf.org/html/draft-ietf-oauth-dyn-reg-30).
2. **Authorization**: Go through an authorization process to obtain access token for API requests.
3. **Authentication**: Use obtained access token to make API requests to Sara Alert API.

While each of these steps must be followed, they vary depending on the client workflow to support different use cases. Therefore, this documentation will describe these steps per workflow.

<a name="workflows"/>

### Supported Workflows
Sara Alert currently supports two different workflows for API use. Both of these workflows are [SMART-on-FHIR standards](http://docs.smarthealthit.org/).

1. [**SMART on FHIR App Launch Framework "standalone launch"**](#standalone-launch). This expects and requires a user in the loop.
2. [**SMART on FHIR Backend Services**](#backend-services). This is complementary to the above flow, and does not require a user in the loop.

In theory, a client application can be registered to support both workflows if it provides the needed registration information for both workflows up front. This is not an expected or understood use case, however, so please notify admins about the need for this upon registration request. In this case, the client application cannot access the API through both workflows simultaneously: i.e. if there is a logged in user who does not have API access enabled, they still cannot access the API even if the client application is registered for the system flow.

<a name="standalone-launch"/>

### SMART on FHIR App Launch Framework "Standalone Launch" Workflow
This workflow supports user-facing client applications launched by a user to access the Sara Alert API and requires a Sara Alert user to give explicit permission for their registered client application to use their Sara Alert user account for authentication purposes when using the API. If you are looking for server-to-server API use, the [SMART on FHIR Backend Services Workflow](#backend-services) may better suit your needs.

The data that is accessible by this workflow is determined by the data available to the authenticated user. For example, if the authenticated user only has access to data for monitorees that they have enrolled in Sara Alert (i.e. the Enroller role), that is the level of access granted to the application. Additionally, admins have the option to toggle API access to their added user. If API access is not enabled for a user, they will see a 403 forbidden response status.

Client application developers can utilize existing open source libraries for FHIR/SMART-on-FHIR to integrate with this workflow, such as:

* [Python SMART on FHIR client](https://github.com/smart-on-fhir/client-py)
* [JavaScript SMART on FHIR client](https://github.com/smart-on-fhir/client-js)
* [Official .NET FHIR API](https://github.com/FirelyTeam/fhir-net-api)
* [Java HAPI FHIR API](https://hapifhir.io/)

Before going further, it is highly recommended to read the profile for this workflow detailed [here](http://hl7.org/fhir/smart-app-launch/index.html).


#### Registration
The registration process for this workflow is fairly straightforward.

The client must have the following information first before taking any additional steps:

* Which environment to register the client application for (demo or production)
* What scopes the application needs access to. See list of supported scopes [here](#supported-scopes).
* The redirect URI (used for redirecting back to the client application after authorization)

Steps:

1. Contact Sara Alert administrators at `sarasupport@aimsplatform.com` with a request to register a client application for API use using this workflow. At this time, the client must provide the information listed above.
1. Once Sara Alert administrators approve the request, they will pass along an assigned client ID and client secret specific to the newly registered client application. The client should make sure to store the client secret securely.

#### Authorization
Once a client application is registered, a user must authorize the client application to use the API and obtain an authorization code. This process is also described in detail [here](http://hl7.org/fhir/smart-app-launch/index.html#step-1-app-asks-for-authorization).

1. The registered client application must build a request for an authorization code. The request parameters are detailed in the specification for this flow [here](http://hl7.org/fhir/smart-app-launch/index.html#step-1-app-asks-for-authorization). This will cause the app to be redirected to the authorization endpoint and require the user to login to Sara Alert. For example, the following (once populated with the appropriate params), would navigate the client application to the Sara Alert demo server's authorization endpoint:

	```
	https://demo.saraalert.org/oauth/authorize?client_id=CLIENT_ID&redirect_uri=REDIRECT&response_type=code&scope=SCOPES&state=STATE&aud=AUD
	```
2. Once the end-user has authorized the request, Sara Alert will redirect back to the application using the redirect_uri given upon registration with the authorization code provided as a parameter.

3. Once the authorization code is retrieved by the client application, it can be used to get an access token. This step is  also described in detail [here](http://hl7.org/fhir/smart-app-launch/index.html#step-3-app-exchanges-authorization-code-for-access-token). Note that the authorization code does expire after 10 minutes as is necessary.

##### POST `/oauth/token`

**Request** Headers

    Content-Type: application/x-www-form-urlencoded

**Request** Body

    client_id: <CLIENT_ID>,
    client_secret: <CLIENT_SECRET>,
    code: <AUTHORIZATION_CODE>,
    grant_type: authorization_code,
    redirect_uri: <CLIENT_REDIRECT_URI>

**Response**

    access_token: <TOKEN>,
    token_type: "Bearer",
    expires_in: 7200,
    scope: <CLIENT_SCOPES>,
    created_at: 1589830122

#### Authentication
The obtained token can then be used for all subsequent requests, via Authorization header, i.e. `'Authorization': "Bearer <TOKEN>"` and will be used to authenticate the user.

Note that access tokens expire after two hours, and after a given access token expires the client application must go through the authorization process once more. Currently Sara Alert does not support issuing refresh tokens for this flow, but that may be supported in the future as described [here](http://hl7.org/fhir/smart-app-launch/index.html#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token).

Example request using access token:

##### GET `[base]/Patient/[:id]`

**Request Headers**

```
  Content-Type: application/x-www-form-urlencoded,
  Accept: application/fhir+json,
  Authorization": Bearer <ACCESS_TOKEN>
```

#### Testing
Sara Alert has a script that generates demo data for testing provided in the source code [here](https://github.com/SaraAlert/SaraAlert/blob/master/lib/tasks/demo.rake). This demo data includes a read/write OAuth 2.0 application for testing this workflow. The client id is `demo-oauth-app-uid` and the client secret is `demo-oauth-app-secret`. User accounts `state1_epi@example.com` and `state1_epi_enroller@example.com` both have API access enabled.

For testing locally (developers), the following url can be used to get to the authorization endpoint and retrieve the authorization code if the Sara Alert application is running locally at `localhost:3000`:

```
http://localhost:3000/oauth/authorize?client_id=demo-oauth-app-uid&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fredirect&response_type=code&scope=user%2FPatient.%2A+user%2FObservation.read+user%2FQuestionnaireResponse.read&state=blah&aud=http%3A%2F%2Flocalhost%3A3000%2Ffhir%2Fr4
```

<a name="backend-services"/>

### SMART on FHIR Backend Services Workflow
This workflow supports backend client applications to use the Sara Alert API without an end-user in the loop. It is ideal for automated workflows that do not require a user-facing application launch.

The data that is accessible by this workflow is determined by jurisdiction provided upon registration. For example, if the client application is registered with access to "USA, State 1" then it will have access to all patients in "USA, State 1" and its subjurisdictions.

This workflow does not require an authenticated end user, but when creating monitoree records it is expected that there is an associated "creator" user. As a result, upon registration a user account will be created that is associated with the client application. The email associated with this user (provided upon registration) will be shown in the History if edits to the monitoree data are made via this workflow. This user account is solely for associating a user creator of the monitoree and cannot be logged into.

Because of the nature of this workflow, there is a lot of flexibility when implementing the client-side of this workflow. It only really requires the following capabilities:
- For registration: Generate and store JWKS (NOTE: generation can be done with a third-party tool if need be)
- For authorization: Make POST authorization requests with a signed JWT and receive access token responses
- For authentication and API interaction: Make API requests

Before going further, it is highly recommended to read the profile for this workflow detailed [here](https://hl7.org/fhir/uv/bulkdata/authorization/index.html). Specifically, the [worked example](https://hl7.org/fhir/uv/bulkdata/authorization/index.html#worked-example) is particularly useful.

Additionally, we have provided the following resources for this workflow:
- Step-by-step process for using this new workflow with a local version of Sara Alert [here](walkthrough-testing-the-backend-services-workflow).
- Example Ruby client for interacting with the API via this new workflow can be found [here](https://github.com/SaraAlert/saraalert-fhir-ig/tree/master/examples/ruby).

#### Registration
The registration step of this workflow requires more information up front. It is recommended that the details of this step in the process first be read in the formal SMART on FHIR profile [here](https://hl7.org/fhir/uv/bulkdata/authorization/index.html#registering-a-smart-backend-service-communicating-public-keys).

The key takeaway is the following:
> Before a SMART client can run against a FHIR server, the client SHALL generate or obtain an asymmetric key pair and SHALL register its public key set with that FHIR server’s authorization service...No matter how a client registers with a FHIR authorization service, the client SHALL register the public key the client will use to authenticate itself to the SMART FHIR authorization server. The public key SHALL be conveyed to the FHIR authorization server in a JSON Web Key (JWK) structure presented within a JWK Set, as defined in JSON Web Key Set (JWKS). The client SHALL protect the associated private key from unauthorized disclosure and corruption.

*Generating JWKS*

A JSON Web Key (JWK) is a JSON data structure that represents a cryptographic key or keypair. They can hold both public and private information about the key.

The client must generate an assymetric public/private key pair and then provide the *public* key in the form of a JSON Web Key Set. Read more about JWK and JWKS [here](https://tools.ietf.org/html/rfc7517), and see an example of this what a JWKS with public keys looks like [here](https://hl7.org/fhir/uv/bulkdata/authorization/sample-jwks/RS384.public.json).

**The JSON Web Algorithm (JWA) for generating the JWKS must be RS384**, as that is the only algorithm currently supported by the Sara Alert API. This may be enhanced to include ES384 in the future.

JWKS can be easily generated with tools such as [this](https://mkjwk.org/), which allow you to specify an algorithm, use (signature), and more. See a Javascript example of generating a JWKS on the official SMART on FHIR GitHub [here](https://github.com/smart-on-fhir/bulk-data-server/blob/master/generator.js).

The client is then entirely responsible for securely storing the private key, as it is never shared with Sara Alert. In the future, the Sara Alert API may support storing urls to public JWKS hosted by the client as discussed [here](https://hl7.org/fhir/uv/bulkdata/authorization/index.html#registering-a-smart-backend-service-communicating-public-keys).


The client must have the following information first before taking any additional steps:

* Which environment to register the client application for (demo or production)
* What scopes the application needs access to. See list of supported scopes [here](#supported-scopes).
* The jurisdiction this client application will have access to.
* The generated *public* key set in the form of a JSON Web Key Set (JWKS).
* The email the client would like associated with this application for logging monitoree updates in the system

Steps:

1. Contact Sara Alert administrators at `sarasupport@aimsplatform.com` with a request to register a client application for API use using this workflow. At this time, the client must provide the information listed above.
2. Once Sara Alert administrators approve the request, they will pass along a client ID specific to the newly registered client application.

#### Authorization
Once the client is securely registered, it does not require a manual authorization step. Instead, it must do the following to request an access token for the Sara Alert API.
Details about each of these steps and the expected parameter is clearly outlined in the protocol [here](https://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details).

1. Generate an authentication JSON Web Token (JWT).
  - First, this JWT must container the headers and body parameters shown [here](https://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details).
	- A recommended Ruby library for generating JWT assertions is [ruby-jwt](https://github.com/jwt/ruby-jwt).
	- The `client_id` referenced in the protocol documentation for both the `sub` and `iss` values should be the `client_id` issued to the client upon registration.
	- The `aud` value that is expected in incoming JWT assertions is the Sara Alert token endpoint.
		- Development: `http://localhost:3000/oauth/token`
		- Demo: `https://demo.saraalert.org/oauth/token`
		- Production: `https://sara.public.saraalert.org/oauth/token`
    - The `jti` value should be a string value that uniquely identifies the JWT among requests from the client application. Therefore how it is generated is up to the client application. It's even okay to make it as simple as a counter, but the client application must ensure it will never be used twice on two different JWTs. 
    - The `exp` value must be epoch time in *seconds* and should be no more than 5 minutes in the future. 
2. Request a new access token via HTTP POST to the FHIR authorization server’s token endpoint URL which is again `<ENVIRONMENT_BASE_URL>/oauth/token`
3. Once the end-user has authorized the request, Sara Alert will respond with an access token.

##### POST `/oauth/token`

**Request** Headers

    Content-Type: application/x-www-form-urlencoded

**Request** Body

    client_assertion: <CLIENT_SIGNED_JWT_ASSERTION>,
    client_assertion_type: urn:ietf:params:oauth:client-assertion-type:jwt-bearer,
    grant_type: client_credentials,
    scope: <CLIENT_SCOPES (space separated)>

**Response**

    access_token: <TOKEN>,
    token_type: "Bearer",
    expires_in: 7200,
    scope: <CLIENT_SCOPES>,
    created_at: 1589830122

#### Authentication
The obtained token can then be used for all subsequent requests, via Authorization header, i.e. `'Authorization': "Bearer <TOKEN>"` and will be used to authenticate the user.

Note that access tokens expire after two hours, and after a given access token expires the client application must go through the authorization process once more. Because the authorization process is automated - this workflow can still be fully automated.

Example request using access token:

##### GET `[base]/Patient/[:id]`

**Request Headers**

```
  Content-Type: application/x-www-form-urlencoded,
  Accept: application/fhir+json,
  Authorization": Bearer <ACCESS_TOKEN>
```

#### Testing
Sara Alert has a script that generates demo data for testing provided in the source code [here](https://github.com/SaraAlert/SaraAlert/blob/master/lib/tasks/demo.rake). This demo data includes a read/write OAuth 2.0 application for testing this workflow.

Developers can use the same syntax to create a test application with a `jurisdiction_id`, a `user_id` and a `public_key_set`.
NOTE: The public_key_set *must* be serialized into a JSON string using `to_json` before storing.

Fortunately, there are many tools available and is easy to generate JWKS at <https://mkjwk.org> for the public key set, which also then be used to create a JWT at <https://jwt.io>.

It is also recommended to use a tool such as Postman to interact with the Sara Alert API for testing this workflow.
