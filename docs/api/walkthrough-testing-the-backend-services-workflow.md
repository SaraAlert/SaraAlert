---
layout: default
title: "Walkthrough: Testing the Backend Services Workflow"
parent: API
nav_order: 5
---
This page documents a set of steps to connect to the Sara Alert FHIR API using the SMART on FHIR Backend Services Workflow as described in  [Getting Started](api-getting-started#smart-on-fhir-backend-services-workflow).

**If you are testing against a local instance of Sara Alert, follow all of the instructions below. If you are testing against the demo server, ignore sections with (LOCAL TESTING ONLY), and note that some numbers in the list of instructions will be skipped.**

## Setup the Environment (LOCAL TESTING ONLY)
If you are testing on the demo server, skip to the next section.
<details>
<summary>Expand only if testing on a LOCAL instance of Sara Alert</summary>
<div markdown="1">

**1.** Clone and run Sara Alert following the steps in the [README](https://github.com/SaraAlert/SaraAlert/blob/master/README.md) for local setup. Make sure to have the database, Redis, and Sidekiq running for the full experience. At a minimum, the database and Redis need to be running.

**2.** Optionally, connect to the database to query some of the tables as we go through the workflow using `mysql --user=disease_trakker`
</div>
</details>

## Create a JSON Web Key (JWK)

**3.** For this tutorial, use <https://mkjwk.org>. Create a JWK with the following settings: Key Size `2048`, Key Use `Signature`, Algorithm `RS384`, Key ID `SHA-256`, Show X.509 `Yes`. Click the "Generate" button.

![mkjwk example](/SaraAlert/assets/images/mkjwk.png)

Either keep this tool open with the generated values or save off all of the displayed values somewhere:
- Public and Private Keypair
- Public and Private Keypair Set
- Public Key
- Private Key (X.509 PEM Format)
- Self-Signed Certificate
- Public Key (X.509 PEM Format)

## Register a New API Client Application (LOCAL TESTING ONLY)
If you are testing on the demo server, skip to the next section.

<details>
<summary>Expand only if testing on a LOCAL instance of Sara Alert</summary>
<div markdown="1">

**4.** Run the `admin:create_oauth_app_for_backend_services_workflow` rake task to both create a new "shadow user" to be used by this new application when creating/updating records, and to create the new OAuth application as well. This rake task requires that you first set an environment variable called `API_FILE_PATH` to the path of a json file that contains needed data. 

For example, if there is a file named `api_data.json` that looks like the following:
```
{
  "app_name": "test-m2m-app",
  "email":  "testapp@example.com",
  "jurisdiction_path": "USA",
  "public_key_set": {
    "keys": [<PUBLIC_KEY>]
  },
  "scopes": "system/Patient.* system/Observation.read system/QuestionnaireResponse.read user/Patient.* user/Observation.read user/QuestionnaireResponse.read",
  "redirect_uri": "urn:ietf:wg:oauth:2.0:oob"
}
```
You can then set the environment variable:
```
export API_FILE_PATH="path/to/api_data.json"
```

and then run the rake task. 
```
bundle exec rake admin:create_oauth_app_for_backend_services_workflow
```

You will see the Client ID of the shadow user and OAuth Application as part of the output:
```
Successfully created user with ID <GENERATED_USER_ID> and email testapp@example.com!
Successfully created user with OAuth Application!
Client ID: <GENERATED_CLIENT_ID>
```

**5.** OPTIONAL: Verify the application was properly registered by querying the database.

```
mysql> select * from oauth_applications;
+----+-----------+--------------------+-----------------------+--------------------------------+-----------------------------------+--------------+----------------------------+----------------------------+---------------------+-----------------+
| id | name      | uid                | secret                | redirect_uri                   | scopes                            | confidential | created_at                 | updated_at                 | public_key_set      | jurisdiction_id |
+----+-----------+--------------------+-----------------------+--------------------------------+-----------------------------------+--------------+----------------------------+----------------------------+---------------------+-----------------+
|  1 | demo      | demo-oauth-app-uid | demo-oauth-app-secret | http://localhost:4000/redirect | user/Patient.*                    |            1 | 2020-06-02 13:22:47.550013 | 2020-06-02 13:22:47.550013 | NULL                |            NULL |
|    |           |                    |                       |                                | user/Observation.read             |              |                            |                            |                     |                 |
|    |           |                    |                       |                                | user/QuestionnaireResponse.read   |              |                            |                            |                     |                 |
|  4 | myTestApp | myTestApp          | <ABRIDGED>            | urn:ietf:wg:oauth:2.0:oob      | system/Patient.*                  |            1 | 2020-09-08 20:15:11.183139 | 2020-09-08 20:15:11.183139 | ---keys: <ABRIDGED> |               1 |
|    |           |                    |                       |                                | system/Observation.read           |              |                            |                            |                     |                 |
|    |           |                    |                       |                                | system/QuestionnaireResponse.read |              |                            |                            |                     |                 |
+----+-----------+--------------------+-----------------------+--------------------------------+-----------------------------------+--------------+----------------------------+----------------------------+---------------------+-----------------+
2 rows in set (0.00 sec)
```
</div>
</details>

## Request Access Token: Create a Signed JWT

**6.** We need a signed JWT to request an access token. In the tutorial use <https://jwt.io/#debugger-io>

In the `Decoded` section, enter the following `HEADER`:

```json
{
  "alg":"RS384",
  "kid":"<KID FROM PUBLIC KEY>",
  "typ":"JWT"
}
```

In the `PAYLOAD` section enter:

If using DEMO server:
```javascript
{
  "iss":"myTestApp",
  "sub":"myTestApp",
  "aud":"http://demo.saraalert.org/oauth/token",
  "exp":1599600491, // Make sure this time is in the future otherwise you will see a SignatureExpired error
  "jti":1599600191
}
```

<details>
<summary> OR: Expand if using LOCAL server</summary>
<div markdown="1">

```javascript
{
  "iss":"myTestApp",
  "sub":"myTestApp",
  "aud":"http://localhost:3000/oauth/token",
  "exp":1599600491, // Make sure this time is in the future otherwise you will see a SignatureExpired error
  "jti":1599600191
}
```
</div>
</details>

![jwt.io example](/SaraAlert/assets/images/jwtio.png)

Set the `"exp"` field to be 5 minutes in the future (this is time in seconds since 1 Jan 1970), and set the `"jti"` to be random non-repeating number.

In the `VERIFY SIGNATURE` field, enter your `PUBLIC KEY` and `PRIVATE KEY` from the `Public Key (X.509 PEM Format)` and `Private Key (X.509 PEM Format)` fields that you generated in Step #3.

Copy the JWT from the `Encoded` field. It should look garbled like this:

```
eyJhbGciOiJSUzM4NCIsImtpZCI6IjNpYlRWLUk0NFppNExza3hIellYeHpVNWpfNThqX0NxRzJiY3lKT0Z1bnciLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJteVRlc3RBcHAiLCJzdWIiOiJteVRlc3RBcHAiLCJhdWQiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvb2F1dGgvdG9rZW4iLCJleHAiOjE1OTk2MDA0OTEsImp0aSI6MTU5OTYwMDE5MX0.OljK-13DGC6RvpHTgCFG0FgyFsEAlwcWIA8AEtzr_LrMJ8cTCWUYuLWNBR6TL6fiFIeW5vDJJdQ8zDUZC_rOMN-U-_oIulWNTWzEib3re0-ST8s3d1QFaZwgsa53C7m7WKUNvdEoKl5VA-YUjxayKQ3xbjUqR1aTy5IVkWeFi3iV0s1S53I6ZdpmiKP5MgCkXnLlWHehg10k4Ro571iOd54cphsrDueiCQBF7P88CoWsrV3uUhFnFSBR53JHWzYDX3-LYVDf1VJB_N8h_maD81MMbmGP7QucsXipQvsAA6G9ZfFzj9trvhRpI-Pk47G7aCca1raGMUja8AySybD0ng
```

We are going to use your JWT in the next step, Request an Access Token.

## Request an Access Token: Build Request

**7.** Using Postman, curl, or whatever HTTP library you like request an Access Token...

REQUEST

IF USING DEMO server:
```
curl --location --request POST 'https://demo.saraalert.org/oauth/token' \
     --header 'Content-Type: application/x-www-form-urlencoded' \
     --data-urlencode 'scope=system/Patient.* system/Observation.read system/QuestionnaireResponse.read' \
     --data-urlencode 'grant_type=client_credentials' \
     --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
     --data-urlencode 'client_assertion=<JWT FROM STEP 6>' \
     --data-urlencode 'client_id=myTestApp'
```

<details>
<summary> OR: Expand if using LOCAL server</summary>
<div markdown="1">

```
curl --location --request POST 'http://localhost:3000/oauth/token' \
     --header 'Content-Type: application/x-www-form-urlencoded' \
     --data-urlencode 'scope=system/Patient.* system/Observation.read system/QuestionnaireResponse.read' \
     --data-urlencode 'grant_type=client_credentials' \
     --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
     --data-urlencode 'client_assertion=<JWT FROM STEP 6>' \
     --data-urlencode 'client_id=myTestApp'
```
</div>
</details>

Make sure you use the proper `client_id` and `scope` that you registered in previous steps.

RESPONSE
```
{
    "access_token": "fXHoedJMq-mdf8cqQvw5a4AY7SOb92McbJvDzNSP5q4",
    "token_type": "Bearer",
    "expires_in": 7200,
    "scope": "system/Patient.* system/Observation.read system/QuestionnaireResponse.read",
    "created_at": 1599601092
}
```
We are going to use the `"access_token"` value in API requests.

## FHIR Requests

**8.** Using Postman, curl, or whatever HTTP library you like request some FHIR Resources...

REQUEST

If using DEMO server:
```
curl  --location --request GET 'http://demo.saraalert.org/fhir/r4/Patient/1' \
      --header 'Accept: application/fhir+json' \
      --header 'Authorization: Bearer fXHoedJMq-mdf8cqQvw5a4AY7SOb92McbJvDzNSP5q4'
```

<details>
<summary>OR: Expand if using LOCAL server</summary>
<div markdown="1">

```
curl  --location --request GET 'http://localhost:3000/fhir/r4/Patient/1' \
      --header 'Accept: application/fhir+json' \
      --header 'Authorization: Bearer fXHoedJMq-mdf8cqQvw5a4AY7SOb92McbJvDzNSP5q4'
```
</div>
</details>

Make sure you replace the token in the example with the token you obtained in Step #7.

The response should be an HTTP 200 with a JSON formatted FHIR Patient.
