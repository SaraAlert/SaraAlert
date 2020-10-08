# Sara Alert API

<a name="overview"/>

## Overview
Sara Alert strives to support interoperability standards in public health, and as a result provides a [FHIR](https://www.hl7.org/fhir/overview.html) RESTful API for reading, writing, and updating monitoree data. The data format accepted and returned by the API corresponds to [FHIR version R4](https://hl7.org/fhir/R4/).

The Sara Alert API does this by following SMART on FHIR API [standards and profiles](http://docs.smarthealthit.org/), as described [here](https://smarthealthit.org/smart-on-fhir-api/):
> A key innovation in the SMART on FHIR platform is the use of a standards-based data layer building on the emerging FHIR API and resource definitions. SMART on FHIR, provides a health app interface based on open standards including HL7’s FHIR, OAuth2, and OpenID Connect. FHIR provides a detailed set of “core” data models, but leaves many fields optional and vocabularies under-constrained, in order to support diverse requirements across varied regions and use cases. But to enable substitutable health apps as well as third-party application services, developers need stronger contracts. To this end, SMART on FHIR applies a set of “profiles” that provide developers with expectations about the vocabularies that will be used to express medications, problems, labs, and other clinical data.

This API is intended for use by public health organizations using Sara Alert, and thus Sara  Alert admins maintain a registered list of supported client applications. For access to a live production or demonstration environment, please contact system administrators at `sarasupport@aimsplatform.com` to discuss adding your client application to the approved list.

## Contents
- [Overview](#overview)
- [Get Started Using the Sara Alert API](#get-started)
	- [Supported Workflows](#workflows)
	- [SMART-on-FHIR App Launch Framework "Standalone Launch" Workflow](#standalone-launch)
	- [SMART on FHIR Backend Services Workflow](#backend-services)
- [API Specification](#api-spec)
	- [Data Representation](#data-representation)
	- [Supported Scopes](#supported-scopes)
	- [CapabilityStatement and Well-Known Uniform Resource Identifiers](#cap)
	  - [GET [base]/metadata](#cap-get)
	  - [GET [base]/.well-known/smart-configuration](#wk-get)
	- [Reading](#read)
	  - [GET [base]/Patient/[:id]](#read-get-pat)
	  - [GET [base]/Observation/[:id]](#read-get-obs)
	  - [GET [base]/QuestionaireResponse/[:id]](#read-get-que)
	  - [GET [base]/Patient/[:id]/$everything](#read-get-all)
	- [Creating](#create)
	  - [Extensions](#create-ext)
	  - [POST [base]/Patient](#create-post-pat)
	- [Updating](#update)
	  - [PUT [base]/Patient/[:id]](#update-put-pat)
	- [Searching](#search)
	  - [GET [base]/Patient?parameter(s)](#search-get)
    - [GET [base]/QuestionnaireResponse?subject=Patient/[:id]](#search-questionnaire-subj)
	  - [GET [base]/Observation?subject=Patient/[:id]](#search-observation-subj)
	  - [GET [base]/Patient?_count=2](#search-all)
	
<a name="get-started"/>

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
	https://demo.saraalert.org//oauth/authorize?client_id=CLIENT_ID&redirect_uri=REDIRECT&response_type=code&scope=SCOPES&state=STATE&aud=AUD
	```
2. Once the end-user has authorized the request, Sara Alert will redirect back to the application using the redirect_uri given upon registration with the authorization code provided as a parameter.

3. Once the authorization code is retrieved by the client application, it can be used to get an access token. This step is  also described in detail [here](http://hl7.org/fhir/smart-app-launch/index.html#step-3-app-exchanges-authorization-code-for-access-token). Note that the authorization code does expire after 10 minutes as is necessary.

	##### POST `/oauth/token`

	**Request** Body

	```json
	{
	  "client_id": "<CLIENT_ID>",
	  "client_secret": "<CLIENT_SECRET>",
	  "code": "<AUTHORIZATION_CODE>",
	  "grant_type": "authorization_code",
	  "redirect_uri": "<CLIENT_REDIRECT_URI>"
	}
	```

	**Response**

	```json
	{
	  "access_token": "<TOKEN>",
	  "token_type": "Bearer",
	  "expires_in": 7200,
	  "scope": "<CLIENT_SCOPES>",
	  "created_at": 1589830122
	}
	```

#### Authentication
The obtained token can then be used for all subsequent requests, via Authorization header, i.e. `'Authorization': "Bearer <TOKEN>"` and will be used to authenticate the user.

Note that access tokens expire after two hours, and after a given access token expires the client application must go through the authorization process once more. Currently Sara Alert does not support issuing refresh tokens for this flow, but that may be supported in the future as described [here](http://hl7.org/fhir/smart-app-launch/index.html#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token).

Example request using access token:

##### GET `[base]/Patient/[:id]`

**Request Headers**

```json
{
  "Content-Type": "application/x-www-form-urlencoded",
  "Authorization": "Bearer <ACCESS_TOKEN>"
}
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
- Step-by-step process for using this new workflow with a local version of Sara Alert [here](https://github.com/SaraAlert/saraalert-fhir-ig/wiki/Step-by-Step-Instructions-For-Local-Testing:-SMART-on-FHIR-Backend-Services-Workflow).
- Example Ruby client for interacting with the API via this new workflow can be found [here](https://github.com/SaraAlert/saraalert-fhir-ig/tree/master/examples/ruby).

#### Registration
The registration step of this workflow requires more information up front. It is recommended that the details of this step in the process first be read in the formal SMART on FHIR profile [here](https://hl7.org/fhir/uv/bulkdata/authorization/index.html#registering-a-smart-backend-service-communicating-public-keys).

The key takeaway is the following:
> Before a SMART client can run against a FHIR server, the client SHALL generate or obtain an asymmetric key pair and SHALL register its public key set with that FHIR server’s authorization service...No matter how a client registers with a FHIR authorization service, the client SHALL register the public key the client will use to authenticate itself to the SMART FHIR authorization server. The public key SHALL be conveyed to the FHIR authorization server in a JSON Web Key (JWK) structure presented within a JWK Set, as defined in JSON Web Key Set (JWKS). The client SHALL protect the associated private key from unauthorized disclosure and corruption.

*Generating JWKS*

A JSON Web Key (JWK) is a JSON data structure that represents a cryptographic key or keypair. They can hold both public and private information about the key.

The client must generate an assymetric public/private key pair and then provide the *public* key in the form of a JSON Web Key Set. Read more about JWK and JWKS [here](https://tools.ietf.org/html/rfc7517), and see an example of this what a JWKS with public keys looks like [here](https://hl7.org/fhir/uv/bulkdata/authorization/sample-jwks/RS384.public.json).

The JSON Web Algorithm (JWA) for generating the JWKS must be RS384, as that is the only algorithm currently supported by the Sara Alert API. This may be enhanced to include ES384 in the future.

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
  - The `exp` value, as state with the other requirements in the protocol, should be no more than 5 minutes in the future. 
2. Request a new access token via HTTP POST to the FHIR authorization server’s token endpoint URL which is again `<ENVIRONMENT_BASE_URL>/oauth/token`
3. Once the end-user has authorized the request, Sara Alert will respond with an access token.

	##### POST `/oauth/token`

	**Request** Headers

  ```json
  {
    "Content-Type": "application/x-www-form-urlencoded"
  }
  ```
	**Request** Body

	```json
	{
	  "client_assertion": "<CLIENT_SIGNED_JWT_ASSERTION>",
	  "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
	  "grant_type": "client_credentials",
	  "scope": "<CLIENT_SCOPES>"
	}
	```

	**Response**

	```json
	{
	  "access_token": "<TOKEN>",
	  "token_type": "Bearer",
	  "expires_in": 7200,
	  "scope": "<CLIENT_SCOPES>",
	  "created_at": 1589830122
	}
	```


#### Authentication
The obtained token can then be used for all subsequent requests, via Authorization header, i.e. `'Authorization': "Bearer <TOKEN>"` and will be used to authenticate the user.

Note that access tokens expire after two hours, and after a given access token expires the client application must go through the authorization process once more. Because the authorization process is automated - this workflow can still be fully automated.

Example request using access token:

##### GET `[base]/Patient/[:id]`

**Request Headers**

```json
{
  "Content-Type": "application/x-www-form-urlencoded",
  "Authorization": "Bearer <ACCESS_TOKEN>"
}
```

#### Testing
Sara Alert has a script that generates demo data for testing provided in the source code [here](https://github.com/SaraAlert/SaraAlert/blob/master/lib/tasks/demo.rake). This demo data includes a read/write OAuth 2.0 application for testing this workflow.

Developers can use the same syntax to create a test application with a `jurisdiction_id`, a `user_id` and a `public_key_set`.
NOTE: The public_key_set *must* be serialized into a JSON string using `to_json` before storing.

Fortunately, there are many tools available and is easy to generate JWKS at https://mkjwk.org/ for the public key set, which also then be used to create a JWT at https://jwt.io.

It is also recommended to use a tool such as Postman to interact with the Sara Alert API for testing this workflow.

<a name="api-spec"/>

## API Specification

For the purposes of this documentation, when describing an API route, [base] includes `/fhir/r4`.
JSON is currently the only supported format. Please make use of the `application/fhir+json` mime type for the Accept header. The Content-Type header must also correspond to this mime type.

<a name="data-representation"/>

### Data Representation
Because the Sara Alert API follows the FHIR specification, there is a mapping between known kinds of Sara Alert data and their associated FHIR resources.

| Sara Alert                | FHIR Resource |
| :---------------          | :------------ |
| Monitoree                 | [Patient](https://hl7.org/fhir/R4/patient.html)|
| Monitoree Lab Result      | [Observation](https://hl7.org/fhir/R4/observation.html)|
| Monitoree Daily Report    | [QuestionnaireResponse](https://www.hl7.org/fhir/questionnaireresponse.html)|

<a name="supported-scopes"/>

### Supported Scopes
For applications following the [SMART-on-FHIR App Launch Framework "Standalone Launch" Workflow](#standalone-launch), these are the available scopes:

* `user/Patient.read`,
* `user/Patient.write`,
* `user/Patient.*`, (for both read and write access to this resource)
* `user/Observation.read`,
* `user/QuestionnaireResponse.read`,

For applications following the [SMART on FHIR Backend Services Workflow](#backend-services), these are the available scopes:

* `system/Patient.read`,
* `system/Patient.write`,
* `system/Patient.*`, (for both read and write access to this resource)
* `system/Observation.read`,
* `system/QuestionnaireResponse.read`,

<a name="cap"/>

### CapabilityStatement and Well-Known Uniform Resource Identifiers

<a name="cap-get"/>

A capability statement is available at `[base]/metadata`:

#### GET `[base]/metadata`

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "status": "active",
  "date": "2020-05-28T00:00:00+00:00",
  "kind": "instance",
  "software": {
    "name": "Sara Alert",
    "version": "v1.4.1"
  },
  "implementation": {
    "description": "Sara Alert API"
  },
  "fhirVersion": "4.0.1",
  "format": [
    "json"
  ],
  "rest": [
    {
      "mode": "server",
      "security": {
        "extension": [
          {
            "extension": [
              {
                "url": "token",
                "valueUri": "http://localhost:3000/oauth/token"
              },
              {
                "url": "authorize",
                "valueUri": "http://localhost:3000/oauth/authorize"
              },
              {
                "url": "introspect",
                "valueUri": "http://localhost:3000/oauth/introspect"
              },
              {
                "url": "revoke",
                "valueUri": "http://localhost:3000/oauth/revoke"
              }
            ],
            "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris"
          }
        ],
        "cors": true,
        "service": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/restful-security-service",
                "code": "SMART-on-FHIR"
              }
            ],
            "text": "OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org"
          }
        ]
      },
      "resource": [
        {
          "type": "Patient",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "create"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "family",
              "type": "string"
            },
            {
              "name": "given",
              "type": "string"
            },
            {
              "name": "telecom",
              "type": "string"
            },
            {
              "name": "email",
              "type": "string"
            },
            {
              "name": "active",
              "type": "boolean"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "Observation",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "subject",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "QuestionnaireResponse",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "subject",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        }
      ]
    }
  ],
  "resourceType": "CapabilityStatement"
}
```
</details>

<a name="wk-get"/>

A Well Known statement is also available at `/.well-known/smart-configuration` or `[base]/.well-known/smart-configuration`:

#### GET `[base]/.well-known/smart-configuration`

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
    "authorization_endpoint": "http://localhost:3000/oauth/authorize",
    "token_endpoint": "http://localhost:3000/oauth/token",
    "introspection_endpoint": "http://localhost:3000/oauth/introspect",
    "revocation_endpoint": "http://localhost:3000/oauth/revoke",
    "scopes_supported": [
        "user/*.read",
        "user/*.write",
        "user/*.*"
    ],
    "capabilities": [
        "launch-standalone"
    ]
}
```
</details>

<a name="read"/>

### Reading

The API supports reading monitorees, monitoree lab results, and monitoree daily reports.

<a name="read-get-pat"/>

#### GET `[base]/Patient/[:id]`

Get a monitoree via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": 5,
  "meta": {
    "lastUpdated": "2020-05-29T00:19:18+00:00"
  },
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
</details>


<a name="read-get-obs"/>

#### GET `[base]/Observation/[:id]`

Get a monitoree lab result via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": 1,
  "meta": {
    "lastUpdated": "2020-05-29T00:49:33+00:00"
  },
  "status": "final",
  "subject": {
    "reference": "Patient/956"
  },
  "effectiveDateTime": "2020-05-07T00:00:00+00:00",
  "valueString": "negative",
  "resourceType": "Observation"
}
```
</details>


<a name="read-get-que"/>

#### GET `[base]/QuestionnaireResponse/[:id]`

Get a monitoree daily report via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": 3,
  "meta": {
    "lastUpdated": "2020-05-29T00:42:54+00:00"
  },
  "status": "completed",
  "subject": {
    "reference": "Patient/3"
  },
  "item": [
    {
      "linkId": "0",
      "text": "cough",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "1",
      "text": "difficulty-breathing",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "2",
      "text": "fever",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "3",
      "text": "used-a-fever-reducer",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "4",
      "text": "chills",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "5",
      "text": "repeated-shaking-with-chills",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "6",
      "text": "muscle-pain",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "7",
      "text": "headache",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "8",
      "text": "sore-throat",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "9",
      "text": "new-loss-of-taste-or-smell",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    }
  ],
  "resourceType": "QuestionnaireResponse"
}
```
</details>


<a name="read-get-all"/>

#### GET `[base]/Patient/[:id]/$everything`

Use this route to retrieve a FHIR Bundle containing the monitoree, all their lab results, and all their daily reports.

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": "96d2ff15-8c55-4d3e-bf04-d3f46064a7cd",
  "meta": {
    "lastUpdated": "2020-05-28T20:52:15-04:00"
  },
  "type": "searchset",
  "total": 2,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/3",
      "resource": {
        "id": 3,
        "meta": {
          "lastUpdated": "2020-05-29T00:42:54+00:00"
        },
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2028-9",
                  "display": "Asian"
                }
              },
              {
                "url": "text",
                "valueString": "Asian"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2135-2",
                  "display": "Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "F"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "E-mailed Web Link"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2020-05-16"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
            "valueDate": "2020-05-11"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Jakubowski48",
            "given": [
              "Lakeesha28",
              "Bartell13"
            ]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 2
          },
          {
            "system": "email",
            "value": "7858879250fake@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1971-01-21",
        "address": [
          {
            "line": [
              "3718 Nestor Unions"
            ],
            "city": "Port Leigh",
            "state": "Massachusetts",
            "postalCode": "00423-5596"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/QuestionnaireResponse/3",
      "resource": {
        "id": 3,
        "meta": {
          "lastUpdated": "2020-05-29T00:42:54+00:00"
        },
        "status": "completed",
        "subject": {
          "reference": "Patient/3"
        },
        "item": [
          {
            "linkId": "0",
            "text": "cough",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "1",
            "text": "difficulty-breathing",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "2",
            "text": "fever",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "3",
            "text": "used-a-fever-reducer",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "4",
            "text": "chills",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "5",
            "text": "repeated-shaking-with-chills",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "6",
            "text": "muscle-pain",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "7",
            "text": "headache",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "8",
            "text": "sore-throat",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "9",
            "text": "new-loss-of-taste-or-smell",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          }
        ],
        "resourceType": "QuestionnaireResponse"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
</details>


<a name="create"/>

### Creating

The API supports creating new monitorees.

#### Extensions

<a name="create-ext"/>

Along with supporting the US Core extensions for race, ethnicity, and birthsex, Sara Alert includes four additional extensions for things specific to the Sara Alert workflows.

Use `http://saraalert.org/StructureDefinition/preferred-contact-method` for specifying the monitorees Sara Alert preferred contact method (options are: `E-mailed Web Link`, `SMS Texted Weblink`, `Telephone call`, `SMS Text-message`, `Opt-out`, and `Unknown`).

```json
{
  "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
  "valueString": "E-mailed Web Link"
}
```

Use `http://saraalert.org/StructureDefinition/preferred-contact-time` for specifying the monitorees Sara Alert preferred contact time (options are: `Morning`, `Afternoon`, and `Evening`).

```json
{
  "url": "http://saraalert.org/StructureDefinition/preferred-contact-time",
  "valueString": "Morning"
}
```

Use `http://saraalert.org/StructureDefinition/symptom-onset-date` to specify when the monitoree's first symptoms appeared for use in the Sara Alert isolation workflow.

```json
{
  "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
  "valueDate": "2020-05-23"
}
```

Use `http://saraalert.org/StructureDefinition/last-exposure-date` to specify when the monitoree's last exposure occurred for use in the Sara Alert exposure workflow.


```json
{
  "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
  "valueDate": "2020-05-18"
}
```

Use `http://saraalert.org/StructureDefinition/isolation` to specify if the monitoree should be in the isolation workflow (omitting this extension defaults this value to false, leaving the monitoree in the exposure workflow).

```json
{
  "url": "http://saraalert.org/StructureDefinition/isolation",
  "valueBoolean": false
}
```

#### POST `[base]/Patient`

<a name="create-post-pat"/>

To create a new monitoree, simply POST a FHIR Patient resource.

##### Request Body

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
</details>


#### Response

On success, the server will return the newly created resource with an id. This is can be used to retrieve or update the record moving forward.

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": 1109,
  "meta": {
    "lastUpdated": "2020-05-29T00:56:18+00:00"
  },
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
</details>


<a name="update"/>

### Updating

The API supports updating existing monitorees.

<a name="update-put-pat"/>

#### PUT `[base]/Patient/[:id]`

#### Request Body

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": true
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
</details>


#### Response

On success, the server will update the existing resource given the id.

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": 1109,
  "meta": {
    "lastUpdated": "2020-05-29T00:57:40+00:00"
  },
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": true
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
</details>


<a name="search"/>

### Searching

The API supports searching for monitorees.

<a name="search-get"/>

#### GET `[base]/Patient?parameter(s)`

The current parameters allowed are: `given`, `family`, `telecom`, `email`, `active`, `subject`, and `_id`. Search results will be paginated by default (see: https://www.hl7.org/fhir/http.html#paging), although you can request a different page size using the `_count` param (defaults to 10, but will allow up to 500). Utilize the `page` param to navigate through the results, as demonstrated in the `[base]/Patient?_count=2` example below under the `link` entry.

GET `[base]/Patient?given=testy&family=mctest`

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": "8d4291fa-4d32-4136-be28-9cbdd2461378",
  "meta": {
    "lastUpdated": "2020-05-28T21:07:11-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/3",
      "resource": {
        "id": 3,
        "meta": {
          "lastUpdated": "2020-05-29T00:42:54+00:00"
        },
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2028-9",
                  "display": "Asian"
                }
              },
              {
                "url": "text",
                "valueString": "Asian"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2135-2",
                  "display": "Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "F"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "E-mailed Web Link"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2020-05-16"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
            "valueDate": "2020-05-11"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          }
        ],
        "active": true,
        "name": [
          {
            "family": "mctest",
            "given": [
              "Lakeesha28",
              "testy"
            ]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 2
          },
          {
            "system": "email",
            "value": "7858879250fake@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1971-01-21",
        "address": [
          {
            "line": [
              "3718 Nestor Unions"
            ],
            "city": "Port Leigh",
            "state": "Massachusetts",
            "postalCode": "00423-5596"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
</details>

#### GET `[base]/QuestionnaireResponse?subject=Patient/[:id]`
You can use search to find Monitoree daily reports by using the `subject` parameter.

<a name="search-questionnaire-sub"/>

GET `[base]/QuestionnaireResponse?subject=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": 1,
  "meta": {
      "lastUpdated": "2020-10-05T21:48:43+00:00"
  },
  "status": "completed",
  "subject": {
      "reference": "Patient/231"
  },
  "item": [
    {
      "linkId": "0",
      "text": "cough",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "1",
      "text": "difficulty-breathing",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "2",
      "text": "new-loss-of-smell",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "3",
      "text": "new-loss-of-taste",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "4",
      "text": "shortness-of-breath",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "5",
      "text": "fever",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "6",
      "text": "used-a-fever-reducer",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "7",
      "text": "chills",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "8",
      "text": "repeated-shaking-with-chills",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "9",
      "text": "muscle-pain",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "10",
      "text": "headache",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "11",
      "text": "sore-throat",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "12",
      "text": "nausea-or-vomiting",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "13",
      "text": "diarrhea",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "14",
      "text": "fatigue",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "15",
      "text": "congestion-or-runny-nose",
      "answer": [
        {
          "valueBoolean": true
        }
      ]
    },
    {
      "linkId": "16",
      "text": "pulse-ox",
      "answer": [
        {
          "valueDecimal": -4.0
        }
      ]
    }
  ],
  "resourceType": "QuestionnaireResponse"
}
```
</details>

#### GET `[base]/Observation?subject=Patient/[:id]`

You can also use search to find Monitoree laboratory results by using the `subject` parameter.

<a name="search-observation-subj"/>

GET `[base]/Observation?subject=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": "6b62097c-eb38-4098-ae2b-6f56a20ec658",
  "meta": {
    "lastUpdated": "2020-05-28T21:09:07-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Observation/1",
      "resource": {
        "id": 1,
        "meta": {
          "lastUpdated": "2020-05-29T00:49:33+00:00"
        },
        "status": "final",
        "subject": {
          "reference": "Patient/956"
        },
        "effectiveDateTime": "2020-05-07T00:00:00+00:00",
        "valueString": "negative",
        "resourceType": "Observation"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
</details>

#### GET `[base]/Patient`

By not specifying any search parameters, you can request all resources of the specified type.

<a name="search-all"/>

GET `[base]/Patient?_count=2`

<details>
  <summary>Click to expand JSON snippet</summary>

```json
{
  "id": "803eeebb-be5b-44e8-8430-0021d122cb77",
  "meta": {
    "lastUpdated": "2020-05-28T21:03:28-04:00"
  },
  "type": "searchset",
  "total": 472,
  "link": [
    {
      "relation": "next",
      "url": "http://localhost:3000/fhir/r4/Patient?_count=2&page=2"
    },
    {
      "relation": "last",
      "url": "http://localhost:3000/fhir/r4/Patient?_count=2&page=236"
    }
  ],
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/12",
      "resource": {
        "id": 12,
        "meta": {
          "lastUpdated": "2020-05-29T00:43:06+00:00"
        },
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2106-3",
                  "display": "White"
                }
              },
              {
                "url": "text",
                "valueString": "White"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "M"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "E-mailed Web Link"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2020-05-18"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
            "valueDate": "2020-05-12"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": false
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Waelchi90",
            "given": [
              "Dwight94",
              "Schulist42"
            ]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 2
          },
          {
            "system": "email",
            "value": "3898888718fake@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1946-12-05",
        "address": [
          {
            "line": [
              "2338 Letisha Center"
            ],
            "city": "Hegmannside",
            "state": "Arizona",
            "postalCode": "33245-0671"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/26",
      "resource": {
        "id": 26,
        "meta": {
          "lastUpdated": "2020-05-29T00:43:14+00:00"
        },
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2076-8",
                  "display": "Native Hawaiian or Other Pacific Islander"
                }
              },
              {
                "url": "text",
                "valueString": "Native Hawaiian or Other Pacific Islander"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "M"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "E-mailed Web Link"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2020-05-19"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
            "valueDate": "2020-05-15"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Connelly52",
            "given": [
              "Kenton63",
              "Kuhlman78"
            ]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "(333) 333-3333",
            "rank": 2
          },
          {
            "system": "email",
            "value": "8065771328fake@example.com",
            "rank": 1
          }
        ],
        "birthDate": "2014-10-04",
        "address": [
          {
            "line": [
              "7842 Luke Fork"
            ],
            "city": "Millshaven",
            "state": "Rhode Island",
            "postalCode": "79857"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
</details>

