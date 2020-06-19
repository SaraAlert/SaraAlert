# Sara Alert API

Sara Alert provides a FHIR (see: https://www.hl7.org/fhir/overview.html) based RESTful API to interact with the system to perform various actions. Actions include reading, writing, and updating monitoree data as well as reading monitoree lab results and monitoree daily reports. The data accepted and returned by the API corresponds to FHIR version R4 (the FHIR Patient resource is used to represent monitorees, the Observation FHIR resource is used to represent monitoree lab results, and the FHIR QuestionaireResponse FHIR resource is used to represent monitoree daily reports).

For the purposes of this documentation, \[base\] includes `/fhir/r4`.

JSON is currently the only supported format. Please make use of the `application/fhir+json` mime type for the `Accept` header. The `Content-Type` header must also correspond to this mime type.

This API follows the FHIR RESTful API (https://www.hl7.org/fhir/http.html) and SMART-on-FHIR SMART App Launch Framework standards (http://hl7.org/fhir/smart-app-launch/index.html), so there is nothing unique or custom about this implementation in particular. Capabilities are described by the `/metadata` endpoint. This means that developers can utilize existing open source libraries for FHIR/SMART-on-FHIR, such as:

* Python SMART on FHIR client: https://github.com/smart-on-fhir/client-py
* JavaScript SMART on FHIR client: https://github.com/smart-on-fhir/client-js
* Official .NET FHIR API: https://github.com/FirelyTeam/fhir-net-api
* Java HAPI FHIR API: https://hapifhir.io/

## Contents

- [Authenticating](#auth)
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
  - [GET [base]/Observation?subject=Patient/[:id]](#search-subj)
  - [GET [base]/Patient?_count=2](#search-all)

<a name="auth"/>

## Authenticating

Sara Alert currently utilizes the SMART-on-FHIR SMART App Launch Framework "standalone launch" flow for authentication. For more details, see http://hl7.org/fhir/smart-app-launch/index.html.

For access to a live production or demonstration enviornment, please contact the system administrator to discuss adding your application to the approved list. Additionally, users must be granted API access via the admin panel.

The supported scopes are `user/*.read` and `user/*.write` (or `user/*.*` for both read and write). Currently, this iteration of the API only supports accessing resources available to the authenticated user (hence the `user/` based scopes).

The demonstration-data-generator script that comes with the Sara Alert source code on GitHub includes a read/write OAuth 2.0 application for testing. The client id is `demo-oauth-app-uid` and the client secret is `demo-oauth-app-secret`. User accounts `state1_epi@example.com` and `state1_epi_enroller@example.com` both have API access enabled.

First, the user must authorize your application. Use the following URL to do so: `/oauth/authorize?client_id=CLIENT_ID&redirect_uri=REDIRECT&response_type=code&scope=SCOPES&state=STATE&aud=AUD`. For specifics about each parameter, see http://hl7.org/fhir/smart-app-launch/index.html#step-1-app-asks-for-authorization.

For testing locally (developers), use: http://localhost:3000/oauth/authorize?client_id=demo-oauth-app-uid&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fredirect&response_type=code&scope=user%2F%2A.write+user%2F%2A.read&state=blah&aud=http%3A%2F%2Flocalhost%3A3000%2Ffhir%2Fr4

The authorization code returned can be used to get an access token:

### POST `/oauth/token`

#### Request Body

```json
{
  "client_id": "<CLIENT_ID>",
  "client_secret": "<CLIENT_SECRET>",
  "code": "<AUTHORIZATION_CODE>",
  "grant_type": "authorization_code",
  "redirect_uri": "http://localhost:3000/redirect"
}
```

#### Response

```json
{
  "access_token": "<TOKEN>",
  "token_type": "Bearer",
  "expires_in": 7200,
  "scope": "user/*.write user/*.read",
  "created_at": 1589830122
}
```

Use this token for all subsequent requests, via Authorization header, i.e. `'Authorization': "Bearer <TOKEN>"`.

<a name="cap"/>

## CapabilityStatement and Well-Known Uniform Resource Identifiers

<a name="cap-get"/>

A capability statement is available at `[base]/metadata`:

### GET `[base]/metadata`

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

### GET `[base]/.well-known/smart-configuration`

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

## Reading

The API supports reading monitorees, monitoree lab results, and monitoree daily reports.

<a name="read-get-pat"/>

### GET `[base]/Patient/[:id]`

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

### GET `[base]/Observation/[:id]`

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

### GET `[base]/QuestionnaireResponse/[:id]`

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

### GET `[base]/Patient/[:id]/$everything`

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

## Creating

The API supports creating new monitorees.

### Extensions

<a name="create-ext"/>

Along with supporting the US Core extensions for race, ethnicity, and birthsex, Sara Alert includes four additional extensions for things specific to the Sara Alert workflows.

Use `http://saraalert.org/StructureDefinition/preferred-contact-method` for specifying the monitorees Sara Alert preferred contact method (options are: `E-mailed Web Link`, `SMS Texted Weblink`, `Telephone call`, and `SMS Text-message`).

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

### POST `[base]/Patient`

<a name="create-post-pat"/>

To create a new monitoree, simply POST a FHIR Patient resource.

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

## Updating

The API supports updating existing monitorees.

<a name="update-put-pat"/>

### PUT `[base]/Patient/[:id]`

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

## Searching

The API supports searching for monitorees.

<a name="search-get"/>

### GET `[base]/Patient?parameter(s)`

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

### GET `[base]/Observation?subject=Patient/[:id]`

You can also use search to find Monitoree daily reports and laboratory results by using the `subject` parameter.

<a name="search-subj"/>

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

### GET `[base]/Patient`

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

