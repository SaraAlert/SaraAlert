---
layout: default
title: Interface Specification
parent: API
nav_order: 4
---
<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

# API Specification

For the purposes of this documentation, when describing an API route, [base] includes `/fhir/r4`.
JSON is currently the only supported format. Please make use of the `application/fhir+json` mime type for the Accept header. When using a POST or PUT endpoint, please also use `application/fhir+json` for the Content-Type header, and when using a PATCH endpoint, please use `application/json-patch+json`.

<a name="data-representation"/>

### Data Representation
Because the Sara Alert API follows the FHIR specification, there is a mapping between known kinds of Sara Alert data and their associated FHIR resources.

| Sara Alert                | FHIR Resource |
| :---------------          | :------------ |
| Monitoree                 | [Patient](https://hl7.org/fhir/R4/patient.html)|
| Monitoree Lab Result      | [Observation](https://hl7.org/fhir/R4/observation.html)|
| Monitoree Daily Report    | [QuestionnaireResponse](https://www.hl7.org/fhir/questionnaireresponse.html)|
| Monitoree Close Contact   | [RelatedPerson](https://www.hl7.org/fhir/relatedperson.html)|
| Monitoree Immunization    | [Immunization](https://www.hl7.org/fhir/immunization.html)|

<a name="supported-scopes"/>

## Supported Scopes
For applications following the [SMART-on-FHIR App Launch Framework "Standalone Launch" Workflow](#standalone-launch), these are the available scopes:

* `user/Patient.read`
* `user/Patient.write`
* `user/Patient.*` (for both read and write access to this resource)
* `user/Observation.read`
* `user/QuestionnaireResponse.read`
* `user/RelatedPerson.read`
* `user/RelatedPerson.write`
* `user/RelatedPerson.*`
* `user/Immunization.read`
* `user/Immunization.write`
* `user/Immunization.*`

For applications following the [SMART on FHIR Backend Services Workflow](#backend-services), these are the available scopes:

* `system/Patient.read`,
* `system/Patient.write`,
* `system/Patient.*`, (for both read and write access to this resource)
* `system/Observation.read`,
* `system/QuestionnaireResponse.read`,
* `system/RelatedPerson.read`,
* `system/RelatedPerson.write`,
* `system/RelatedPerson.*`,
* `system/Immunization.read`,
* `system/Immunization.write`,
* `system/Immunization.*`

Please note a given application and request for access token can have have multiple scopes, which must be space-separated. For example:
```
`user/Patient.read system/Patient.read system/Observation.read`
```

<a name="cap"/>

## CapabilityStatement and Well-Known Uniform Resource Identifiers

<a name="cap-get"/>

A capability statement is available at `[base]/metadata`:

### GET `[base]/metadata`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "active",
  "date": "2021-04-01T00:00:00+00:00",
  "kind": "instance",
  "software": {
    "name": "Sara Alert",
    "version": "v1.27.0"
  },
  "implementation": {
    "description": "Sara Alert API"
  },
  "fhirVersion": "4.0.1",
  "format": ["json"],
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
            "text": "OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)"
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
              "code": "patch"
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
          "type": "RelatedPerson",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "patch"
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
              "name": "patient",
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
          "type": "Immunization",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "patch"
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
              "name": "patient",
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
  </div>
</details>

<a name="wk-get"/>

A Well Known statement is also available at `/.well-known/smart-configuration` or `[base]/.well-known/smart-configuration`:

### GET `[base]/.well-known/smart-configuration`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "authorization_endpoint": "http://localhost:3000/oauth/authorize",
  "token_endpoint": "http://localhost:3000/oauth/token",
  "token_endpoint_auth_methods_supported": ["client_secret_basic", "private_key_jwt"],
  "token_endpoint_auth_signing_alg_values_supported": ["RS384"],
  "introspection_endpoint": "http://localhost:3000/oauth/introspect",
  "revocation_endpoint": "http://localhost:3000/oauth/revoke",
  "scopes_supported": [
    "user/Patient.read",
    "user/Patient.write",
    "user/Patient.*",
    "user/Observation.read",
    "user/QuestionnaireResponse.read",
    "user/RelatedPerson.read",
    "user/RelatedPerson.write",
    "user/RelatedPerson.*",
    "user/Immunization.read",
    "user/Immunization.write",
    "user/Immunization.*",
    "system/Patient.read",
    "system/Patient.write",
    "system/Patient.*",
    "system/Observation.read",
    "system/QuestionnaireResponse.read",
    "system/RelatedPerson.read",
    "system/RelatedPerson.write",
    "system/RelatedPerson.*",
    "system/Immunization.read",
    "system/Immunization.write",
    "system/Immunization.*"
  ],
  "capabilities": ["launch-standalone"]
}

```
  </div>
</details>

<a name="read"/>

## Reading

The API supports reading monitorees, monitoree lab results, monitoree daily reports, monitoree close contacts, and monitoree vaccinations.

<a name="read-get-pat"/>

### GET `[base]/Patient/[:id]`

Get a monitoree via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
    },
    {
        "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
        "valueString": "USA, State 1"
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
  </div>
</details>


<a name="read-get-obs"/>

### GET `[base]/Observation/[:id]`

Get a monitoree lab result via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
  </div>
</details>


<a name="read-get-que"/>

### GET `[base]/QuestionnaireResponse/[:id]`

Get a monitoree daily report via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
  </div>
</details>

<a name="read-get-related"/>

### GET `[base]/RelatedPerson/[:id]`

Get a monitoree close contact via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 950,
  "meta": {
    "lastUpdated": "2021-01-31T18:23:16+00:00"
  },
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/contact-attempts",
      "valueUnsignedInt": 5
    },
    {
      "url": "http://saraalert.org/StructureDefinition/notes",
      "valueString": "Parsing the panel won't do anything, we need to program the optical ib array!"
    }
  ],
  "patient": {
    "reference": "Patient/222"
  },
  "name": [
    {
      "family": "Pollich97",
      "given": ["Nam32"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+15555550104",
      "rank": 1
    },
    {
      "system": "email",
      "value": "1845823000fake@example.com",
      "rank": 1
    }
  ],
  "resourceType": "RelatedPerson"
}
```
  </div>
</details>


<a name="read-get-immunization"/>

### GET `[base]/Immunization/[:id]`

Get a monitoree vaccination via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 32,
  "meta": {
    "lastUpdated": "2021-04-01T22:09:11+00:00"
  },
  "status": "completed",
  "vaccineCode": [
    {
      "coding": [
        {
          "system": "http://hl7.org/fhir/sid/cvx",
          "code": "207"
        }
      ],
      "text": "Moderna COVID-19 Vaccine"
    }
  ],
  "patient": {
    "reference": "Patient/1"
  },
  "occurrenceDateTime": "2021-03-30",
  "note": [
    {
      "text": "Notes here"
    }
  ],
  "protocolApplied": [
    {
      "targetDisease": [
        {
          "coding": [
            {
              "system": "http://hl7.org/fhir/sid/cvx",
              "code": "213"
            }
          ],
          "text": "COVID-19"
        }
      ],
      "doseNumberString": "1"
    }
  ],
  "resourceType": "Immunization"
}
```
  </div>
</details>




<a name="read-get-all"/>

### GET `[base]/Patient/[:id]/$everything`

Use this route to retrieve a FHIR Bundle containing the monitoree, all their lab results, and all their daily reports.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
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
  </div>
</details>


<a name="create"/>

## Creating

The API supports creating new monitorees.

### POST `[base]/Patient`

<a name="create-post-pat"/>

To create a new monitoree, simply POST a FHIR Patient resource.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
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
  </div>
</details>


**Response:**

On success, the server will return the newly created resource with an id. This is can be used to retrieve or update the record moving forward.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
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
  </div>
</details>

#### Patient Extensions

<a name="create-pat-ext"/>

Along with supporting the US Core extensions for [race](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-race.html), [ethnicity](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-ethnicity.html), and [birthsex](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-birthsex.html), Sara Alert includes additional extensions for attributes specific to the Sara Alert workflows.

Use `http://saraalert.org/StructureDefinition/preferred-contact-method` to specify the monitoree's Sara Alert preferred contact method (options are: `E-mailed Web Link`, `SMS Texted Weblink`, `Telephone call`, `SMS Text-message`, `Opt-out`, and `Unknown`).

```json
{
  "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
  "valueString": "E-mailed Web Link"
}
```

Use `http://saraalert.org/StructureDefinition/preferred-contact-time` to specify the monitoree's Sara Alert preferred contact time (options are: `Morning`, `Afternoon`, and `Evening`).

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

Use `http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path` to specify the monitoree's assigned jurisdiction.
```json
{
  "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
  "valueString": "USA, State 1"
}
```

Use `http://saraalert.org/StructureDefinition/monitoring-plan` to specify the monitoree's Sara Alert monitoring plan (options are: `None`, `Daily active monitoring`, `Self-monitoring with public health supervision`, `Self-monitoring with delegated supervision`, and `Self-observation`).
```json
{
  "url": "http://saraalert.org/StructureDefinition/monitoring-plan",
  "valueString": "Daily active monitoring"
}
```

Use `http://saraalert.org/StructureDefinition/assigned-user` to specify the monitoree's assigned user.
```json
{
  "url": "http://saraalert.org/StructureDefinition/assigned-user",
  "valuePositiveInt": 123
}
```

Use `http://saraalert.org/StructureDefinition/additional-planned-travel-start-date` to specify when the monitoree is planning to begin their travel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-start-date",
  "valueDate": "2020-06-15"
}
```

Use `http://saraalert.org/StructureDefinition/port-of-origin` to specify the port that the monitoree traveled from.
```json
{
  "url": "http://saraalert.org/StructureDefinition/port-of-origin",
  "valueString": "MSP Airport"
}
```

Use `http://saraalert.org/StructureDefinition/date-of-departure` to specify when the monitoree departed from the port of origin.
```json
{
  "url": "http://saraalert.org/StructureDefinition/date-of-departure",
  "valueDate": "2020-05-25"
}
```

Use `http://saraalert.org/StructureDefinition/flight-or-vessel-number` to specify the plane, train, ship, or other vessel that the monitoree used to travel to their destination.
```json
{
  "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
  "valueString": "QQ1234"
}
```

Use `http://saraalert.org/StructureDefinition/flight-or-vessel-carrier` to specify the carrier, operating company, or provider of the flight or vessel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
  "valueString": "QQ Airways"
}
```

Use `http://saraalert.org/StructureDefinition/date-of-arrival` to specify when the monitoree
entered the United States after travel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
  "valueDate": "2020-05-28"
}
```

Use `http://saraalert.org/StructureDefinition/exposure-notes` to specify additional notes about the monitoree's exposure history or case information history.
```json
{
  "url": "http://saraalert.org/StructureDefinition/exposure-notes",
  "valueString": "Sample exposure notes."
}
```

Use `http://saraalert.org/StructureDefinition/travel-related-notes` to specify additional notes
about the monitoree’s travel history.
```json
{
  "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
  "valueString": "Sample travel notes."
}
```

Use `http://saraalert.org/StructureDefinition/additional-planned-travel-notes` to specify additional notes about the monitoree's planned travel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-notes",
  "valueString": "Sample planned travel notes."
}
```

Use `http://saraalert.org/StructureDefinition/phone-type` to specify the type of phone attached to the primary or secondary phone number (options are: `Smartphone`, `Plain Cell`, and `Landline`). Note that this extension should be placed on the first element in the `Patient.telecom` array to specify the monitoree's primary phone type, and the second element in the `Patient.telecom` array to specify the monitoree's secondary phone type.
```json
"telecom": [
  {
    "system": "phone",
    "value": "(333) 333-3333",
    "rank": 1,
    "extension": {
      "url": "http://saraalert.org/StructureDefinition/phone-type",
      "valueString": "Smartphone"
    }
  }
]
```

Use `http://saraalert.org/StructureDefinition/address-type` to specify the type of an address (options are: `USA` and `Foreign`). Note that this extension should be placed on an element in the `Patient.address` array. If this extension is not present on an address in the `Patient.address` array, the address is assumed to be a `USA` address.
```json
"address": [
  {
    "extension": [
      {
        "url": "http://saraalert.org/StructureDefinition/address-type",
        "valueString": "Foreign"
      }
    ],
    "line": ["24961 Linnie Inlet", "Apt. 497"],
    "city": "Ottawa",
    "state": "Ontario",
    "country": "Canada",
    "postalCode": "192387"
  },
  {
    "line": ["35047 Van Light"],
    "city": "New Tambra",
    "state": "Mississippi",
    "district": "Summer Square",
    "postalCode": "05657",
  }
]
```

### POST `[base]/RelatedPerson`

<a name="create-post-related"/>

To create a new monitoree close contact, simply POST a FHIR RelatedPerson resource that references the monitoree.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/contact-attempts",
      "valueUnsignedInt": 5
    },
    {
      "url": "http://saraalert.org/StructureDefinition/notes",
      "valueString": "Parsing the panel won't do anything, we need to program the optical ib array!"
    }
  ],
  "patient": {
    "reference": "Patient/222"
  },
  "name": [
    {
      "family": "Pollich97",
      "given": ["Nam32"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+15555550104",
      "rank": 1
    },
    {
      "system": "email",
      "value": "1845823000fake@example.com",
      "rank": 1
    }
  ],
  "resourceType": "RelatedPerson"
}
```
  </div>
</details>

#### RelatedPerson Extensions

<a name="create-related-ext"/>

Sara Alert includes additional extensions for attributes specific to a monitoree close contact.


Use `http://saraalert.org/StructureDefinition/last-date-of-exposure` to specify when the close contact's last exposure occurred.
```json
{
  "url": "http://saraalert.org/StructureDefinition/last-date-of-exposure",
  "valueDate": "2020-05-18"
}
```

Use `http://saraalert.org/StructureDefinition/assigned-user` to specify the close contacts's assigned user.
```json
{
  "url": "http://saraalert.org/StructureDefinition/assigned-user",
  "valuePositiveInt": 123
}
```

Use `http://saraalert.org/StructureDefinition/notes` to specify additional notes about the close contacts's case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/notes",
  "valueString": "Sample notes."
}
```

Use `http://saraalert.org/StructureDefinition/contact-attempts` to specify the number of attempts made to contact the close contact.
```json
{
  "url": "http://saraalert.org/StructureDefinition/contact-attempts",
  "valueUnsignedInt": 2
}
```

The `http://saraalert.org/StructureDefinition/enrolled-patient` extension is used to reference the full Patient resource that corresponds to the close contact, if such a Patient exists. Note that this extension is read-only. This field may only be updated by manually enrolling a new Patient for this close contact via the user interface.
```json
{
  "url": "http://saraalert.org/StructureDefinition/enrolled-patient",
  "valueReference": {
    "reference": "Patient/567"
  }
}
```

### POST `[base]/Immunization`

<a name="create-post-immunization"/>

To create a new monitoree vaccination, simply POST a FHIR Immunization resource that references the monitoree.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 32,
  "meta": {
    "lastUpdated": "2021-04-01T22:09:11+00:00"
  },
  "status": "completed",
  "vaccineCode": [
    {
      "coding": [
        {
          "system": "http://hl7.org/fhir/sid/cvx",
          "code": "207"
        }
      ],
      "text": "Moderna COVID-19 Vaccine"
    }
  ],
  "patient": {
    "reference": "Patient/1"
  },
  "occurrenceDateTime": "2021-03-30",
  "note": [
    {
      "text": "Notes here"
    }
  ],
  "protocolApplied": [
    {
      "targetDisease": [
        {
          "coding": [
            {
              "system": "http://hl7.org/fhir/sid/cvx",
              "code": "213"
            }
          ],
          "text": "COVID-19"
        }
      ],
      "doseNumberString": "1"
    }
  ],
  "resourceType": "Immunization"
}
```
  </div>
</details>


<a name="update"/>

## Updating
An update request creates a new current version for an existing resource.

**PLEASE NOTE:** The API supports `PUT` and `PATCH` requests, which update an existing resource in different ways. A `PUT` request will replace the entire existing resource. This means that if certain attributes of the resource are omitted in the `PUT` requests, they will be replaced with null values. A `PATCH` request will only modify the attributes indicated in the request, which must follow the [JSON Patch specification](https://tools.ietf.org/html/rfc6902). Omitted attributes are unchanged. For further details on the contents of a `PATCH` request, see the [JSON Patch documentation](http://jsonpatch.com/).

<a name="update-put-pat"/>

### PUT `[base]/Patient/[:id]`

**NOTE:** This is a `PUT` operation, it will replace the entire resource. If you intend to modify specific attributes instead, see [PATCH](#update-patch-pat).

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
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
  </div>
</details>


**Response:**

On success, the server will update the existing resource given the id.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
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
  </div>
</details>

<a name="update-put-related"/>

### PUT `[base]/RelatedPerson/[:id]`

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/contact-attempts",
      "valueUnsignedInt": 5
    },
    {
      "url": "http://saraalert.org/StructureDefinition/notes",
      "valueString": "Parsing the panel won't do anything, we need to program the optical ib array!"
    }
  ],
  "patient": {
    "reference": "Patient/222"
  },
  "name": [
    {
      "family": "Pollich97",
      "given": ["Nam32"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+15555550104",
      "rank": 1
    },
    {
      "system": "email",
      "value": "1845823000fake@example.com",
      "rank": 1
    }
  ],
  "resourceType": "RelatedPerson"
}
```
  </div>
</details>

<a name="update-put-immunization"/>

### PUT `[base]/Immunization/[:id]`

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 32,
  "meta": {
    "lastUpdated": "2021-04-01T22:09:11+00:00"
  },
  "status": "completed",
  "vaccineCode": [
    {
      "coding": [
        {
          "system": "http://hl7.org/fhir/sid/cvx",
          "code": "207"
        }
      ],
      "text": "Moderna COVID-19 Vaccine"
    }
  ],
  "patient": {
    "reference": "Patient/1"
  },
  "occurrenceDateTime": "2021-03-30",
  "note": [
    {
      "text": "Notes here"
    }
  ],
  "protocolApplied": [
    {
      "targetDisease": [
        {
          "coding": [
            {
              "system": "http://hl7.org/fhir/sid/cvx",
              "code": "213"
            }
          ],
          "text": "COVID-19"
        }
      ],
      "doseNumberString": "1"
    }
  ],
  "resourceType": "Immunization"
}
```
  </div>
</details>

<a name="update-patch-pat"/>

### PATCH `[base]/Patient/[:id]`

**NOTE:** This is a `PATCH` operation, it will only modify specified attributes. If you intend to replace the entire resource instead, see [PUT](#update-put-pat).

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**

Assume the Patient resource was originally as shown in the example Patient [GET](#read-get-pat), and the patch is specified as below.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "remove", "path": "/communication" },
  { "op": "replace", "path": "/birthDate", "value": "1985-03-30" }
]
```
  </div>
</details>


**Response:**

On success, the server will update the attributes indicated by the request.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
    },
    {
        "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
        "valueString": "USA, State 1"
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
  "birthDate": "1985-03-30",
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
  "resourceType": "Patient"
}
```
  </div>
</details>

<a name="update-patch-related"/>

### PATCH `[base]/RelatedPerson/[:id]`

**NOTE:** See the [Patient PATCH documentation](#update-patch-pat) for a more complete explanation of PATCH.

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "remove", "path": "/name/0/family" },
]
```
  </div>
</details>

<a name="update-patch-immunization"/>

### PATCH `[base]/Immunization/[:id]`

**NOTE:** See the [Patient PATCH documentation](#update-patch-pat) for a more complete explanation of PATCH.

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "replace", "path": "/note/0/text", "value": "Important notes" },
]
```
  </div>
</details>


<a name="search"/>

## Searching

The API supports searching for monitorees.

<a name="search-get"/>

### GET `[base]/Patient?parameter(s)`

The current parameters allowed are: `given`, `family`, `telecom`, `email`, `active`, `subject`, and `_id`. Search results will be paginated by default (see: <https://www.hl7.org/fhir/http.html#paging>), although you can request a different page size using the `_count` param (defaults to 10, but will allow up to 500). Utilize the `page` param to navigate through the results, as demonstrated in the `[base]/Patient?_count=2` example below under the `link` entry.

GET `[base]/Patient?given=john&family=doe`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
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
  </div>
</details>

### GET `[base]/QuestionnaireResponse?subject=Patient/[:id]`
You can use search to find Monitoree daily reports by using the `subject` parameter.

<a name="search-questionnaire-subj"/>

GET `[base]/QuestionnaireResponse?subject=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
  </div>
</details>

### GET `[base]/Observation?subject=Patient/[:id]`

You can also use search to find Monitoree laboratory results by using the `subject` parameter.

<a name="search-observation-subj"/>

GET `[base]/Observation?subject=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
  </div>
</details>

### GET `[base]/RelatedPerson?patient=Patient/[:id]`

You can also use search to find Monitoree close contacts by using the `patient` parameter.

<a name="search-related-patient"/>

GET `[base]/RelatedPerson?patient=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "f37cc7ac-3543-4ded-8902-841d0076a9bd",
  "meta": {
    "lastUpdated": "2021-03-04T17:04:29-05:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/RelatedPerson/950",
      "resource": {
        "id": 950,
        "meta": {
          "lastUpdated": "2021-01-31T18:23:16+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/contact-attempts",
            "valueUnsignedInt": 5
          },
          {
            "url": "http://saraalert.org/StructureDefinition/notes",
            "valueString": "Parsing the panel won't do anything, we need to program the optical ib array!"
          }
        ],
        "patient": {
          "reference": "Patient/222"
        },
        "name": [
          {
            "family": "Pollich97",
            "given": ["Nam32"]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "+15555550104",
            "rank": 1
          },
          {
            "system": "email",
            "value": "1845823000fake@example.com",
            "rank": 1
          }
        ],
        "resourceType": "RelatedPerson"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/Immunization?patient=Patient/[:id]`

You can also use search to find Monitoree vaccinations by using the `patient` parameter.

<a name="search-immunization-patient"/>

GET `[base]/Immunization?patient=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "18dca7c0-692e-4819-b70b-2b342741567c",
  "meta": {
    "lastUpdated": "2021-04-01T18:17:29-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Immunization/35",
      "resource": {
        "id": 35,
        "meta": {
          "lastUpdated": "2021-04-01T22:17:14+00:00"
        },
        "status": "completed",
        "vaccineCode": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/sid/cvx",
                "code": "207"
              }
            ],
            "text": "Moderna COVID-19 Vaccine"
          }
        ],
        "patient": {
          "reference": "Patient/111"
        },
        "occurrenceDateTime": "2021-03-30",
        "note": [
          {
            "text": "Notes here"
          }
        ],
        "protocolApplied": [
          {
            "targetDisease": [
              {
                "coding": [
                  {
                    "system": "http://hl7.org/fhir/sid/cvx",
                    "code": "213"
                  }
                ],
                "text": "COVID-19"
              }
            ],
            "doseNumberString": "1"
          }
        ],
        "resourceType": "Immunization"
      }
    }
  ],
  "resourceType": "Bundle"
}

```
  </div>
</details>

### GET `[base]/Patient`

By not specifying any search parameters, you can request all resources of the specified type.

<a name="search-all"/>

GET `[base]/Patient?_count=2`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
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
  </div>
</details>

