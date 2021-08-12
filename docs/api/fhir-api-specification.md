---
layout: default
title: FHIR Interface Specification
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

# FHIR API Specification

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
| Monitoree History         | [Provenance](https://hl7.org/fhir/provenance.html)|

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
* `user/Immunization.*`,
* `user/Provenance.read`

For applications following the [SMART on FHIR Backend Services Workflow](#backend-services), these are the available scopes:

* `system/Patient.read`
* `system/Patient.write`
* `system/Patient.*` (for both read and write access to this resource)
* `system/Observation.read`
* `system/Observation.write`
* `system/Observation.*`
* `system/QuestionnaireResponse.read`
* `system/RelatedPerson.read`
* `system/RelatedPerson.write`
* `system/RelatedPerson.*`
* `system/Immunization.read`
* `system/Immunization.write`
* `system/Immunization.*`
* `system/Provenance.read`

Please note a given application and request for access token can have have multiple scopes, which must be space-separated. For example:
```
user/Patient.read system/Patient.read system/Observation.read
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
  "date": "2021-05-04T00:00:00+00:00",
  "kind": "instance",
  "software": {
    "name": "Sara Alert",
    "version": "v1.30"
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
          "type": "Provenance",
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
  "token_endpoint_auth_methods_supported": [
    "client_secret_basic",
    "private_key_jwt"
  ],
  "token_endpoint_auth_signing_alg_values_supported": ["RS384"],
  "introspection_endpoint": "http://localhost:3000/oauth/introspect",
  "revocation_endpoint": "http://localhost:3000/oauth/revoke",
  "scopes_supported": [
    "user/Patient.read",
    "user/Patient.write",
    "user/Patient.*",
    "user/Observation.read",
    "user/Observation.*",
    "user/QuestionnaireResponse.read",
    "user/RelatedPerson.read",
    "user/RelatedPerson.write",
    "user/RelatedPerson.*",
    "user/Immunization.read",
    "user/Immunization.write",
    "user/Immunization.*",
    "user/Provenance.read",
    "system/Patient.read",
    "system/Patient.write",
    "system/Patient.*",
    "system/Observation.read",
    "system/Observation.*",
    "system/QuestionnaireResponse.read",
    "system/RelatedPerson.read",
    "system/RelatedPerson.write",
    "system/RelatedPerson.*",
    "system/Immunization.read",
    "system/Immunization.write",
    "system/Immunization.*",
    "system/Provenance.read"
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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
      "valueString": "case1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-reason",
      "valueString": "Duplicate"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-note",
      "valueString": "This is a duplicate."
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
  "id": 11,
  "meta": {
    "lastUpdated": "2021-05-06T12:44:19+00:00"
  },
  "status": "final",
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "laboratory"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "94564-2"
      }
    ],
    "text": "IgM Antibody"
  },
  "subject": {
    "reference": "Patient/1"
  },
  "effectiveDateTime": "2021-05-06",
  "issued": "2021-05-07T00:00:00+00:00",
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "10828004"
      }
    ],
    "text": "positive"
  },
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

<a name="read-get-provenance"/>

### GET `[base]/Provenance/[:id]`

Get a monitoree history via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 2006, 
  "meta": {
    "lastUpdated": "2021-05-20T02:09:38+00:00"
  },
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/comment", 
      "valueString": "User changed latest public health action to \"Recommended medical evaluation of symptoms\". Reason: Lost to follow-up during monitoring period, details"
    }, 
    {
      "url": "http://saraalert.org/StructureDefinition/history_type", 
      "valueString": "Monitoring Change"
    }
  ], 
  "target": [
    {
      "reference": "Patient/6"
    }
  ], 
  "recorded": "2021-05-20T02:09:38+00:00", 
  "agent": [
    {
      "who": {
        "identifier": {
          "value": "state1_epi_enroller@example.com"
        }
      }, 
      "onBehalfOf": {
        "reference": "Patient/6"
      }
    }
  ], 
  "resourceType": "Provenance"
}
```
  </div>
</details>




<a name="read-get-all"/>

### GET `[base]/Patient/[:id]/$everything`

Use this route to retrieve a FHIR Bundle containing the monitoree and all their lab results, daily reports, vaccinations, close contacts, and histories

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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "2020-05-29"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "Low"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "Document results of medical evaluation"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
            "valueString": "case1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Collierview"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "Angola"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
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
      "fullUrl": "http://localhost:3000/fhir/r4/Provenance/1262",
      "resource": {
        "id": 1262,
        "meta": {
          "lastUpdated": "2021-05-19T02:13:54+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/comment",
            "valueString": "User enrolled monitoree."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/history-type",
            "valueString": "Enrollment"
          }
        ],
       "target": [
         {
            "reference": "Patient/3"
          }
        ],
        "recorded": "2021-05-19T02:13:54+00:00",
        "agent": [
         {
           "who": {
             "identifier": {
               "value": "state1_enroller@example.com"
             }
           },
           "onBehalfOf": {
              "reference": "Patient/3"
           }
          }
        ],
        "resourceType": "Provenance"
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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
      "valueString": "case1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-reason",
      "valueString": "Duplicate"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-note",
      "valueString": "This is a duplicate."
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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
      "valueString": "case1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
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

Use `http://saraalert.org/StructureDefinition/exposure-risk-assessment` to specify the risk assessment of the monitoree's exposure to disease.
```json
{
  "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
  "valueString": "Low"
}
```

Use `http://saraalert.org/StructureDefinition/public-health-action` to specify the public health recommendation provided to a monitoree.
```json
{
  "url": "http://saraalert.org/StructureDefinition/public-health-action",
  "valueString": "Document results of medical evaluation"
}
```

Use `http://saraalert.org/StructureDefinition/contact-of-known-case` to specify if a monitoree has a known exposure to a confirmed or probable case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
  "valueBoolean": true
}
```

Use `http://saraalert.org/StructureDefinition/contact-of-known-case-id` to specify the case ID of the probable or confirmed case that a monitoree had exposure to. Any sort of identifier can be used here.
```json
{
  "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
  "valueString": "1"
}
```

Use `http://saraalert.org/StructureDefinition/common-exposure-cohort-name` to specify the name of a cohort that a monitoree shares common exposure with.
```json
{
  "url": "http://saraalert.org/StructureDefinition/common-exposure-cohort-name",
  "valueString": "Example Cohort"
}
```

Use `http://saraalert.org/StructureDefinition/potential-exposure-location` to specify a description of the location where the monitoree was potentially last exposed to a case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
  "valueString": "Boise"
}
```

Use `http://saraalert.org/StructureDefinition/potential-exposure-country` to specify the country where the monitoree was potentially last exposed to a case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
  "valueString": "Angola"
}
```

Use `http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired` to specify if the monitoree needs a language interpreter when speaking with public health representatives.
```json
{
  "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
  "valueBoolean": true
}
```

Use `http://saraalert.org/StructureDefinition/extended-isolation` to specify a user-defined date that determines eligibility for a monitoree appearing on the Records Requiring Review linelist.
```json
{
  "url": "http://saraalert.org/StructureDefinition/extended-isolation",
  "valueDate": "2021-06-15"
}
```

Use `http://saraalert.org/StructureDefinition/follow-up-reason` to specify a reason to follow up on the monitoree (options are: `Deceased`, `Duplicate`, `High-Risk`, `Hospitalized`, `In Need of Follow-up`, `Lost to Follow-up`, `Needs Interpretation`, `Quality Assurance`, `Refused Active Monitoring`, and `Other`).
```json
{
  "url": "http://saraalert.org/StructureDefinition/follow-up-reason",
  "valueString": "Duplicate"
}
```

Use `http://saraalert.org/StructureDefinition/follow-up-note` to specify additional details for follow up reason on the monitoree. This requires the follow up reason to be set.
```json
{
  "url": "http://saraalert.org/StructureDefinition/follow-up-note",
  "valueString": "This is a duplicate."
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

The `http://saraalert.org/StructureDefinition/end-of-monitoring` extension represents the system calculated end of monitoring period. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
  "valueDate": "2021-06-15"
}
```

The `http://saraalert.org/StructureDefinition/expected-purge-date` extension represents the date and time that the monitoree's identifiers will be eligible to be purged from the system. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/expected-purge-date",
  "valueDateTime": "2021-06-29T21:04:08+00:00"
}
```

The `http://saraalert.org/StructureDefinition/reason-for-closure` extension represents the reason a monitoree was closed by the user or system. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/reason-for-closure",
  "valueString": "Completed Monitoring"
}
```

The complex `http://saraalert.org/StructureDefinition/latest-transfer` extension represents the latest transfer that occurred for the monitoree. This field is read-only.
```json

{
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/transferred-at",
      "valueDateTime": "2021-05-20T22:54:57+00:00"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/transferred-from",
      "valueString": "USA, State 1, County 1"
    }
  ],
  "url": "http://saraalert.org/StructureDefinition/latest-transfer"
}
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

### POST `[base]/Observation`

<a name="create-post-immunization"/>

To create a new monitoree lab result, simply POST a FHIR Observation resource that references the monitoree.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "final",
  "subject": {
    "reference": "Patient/10"
  },
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "94564-2"
      }
    ]
  },
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "10828004"
      }
    ]
  },
  "effectiveDateTime": "2021-05-06",
  "issued": "2021-05-07T00:00:00+00:00",
  "resourceType": "Observation"
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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
      "valueString": "case1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-reason",
      "valueString": "Duplicate"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-note",
      "valueString": "This is a duplicate."
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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
      "valueString": "case1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
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

<a name="update-put-observation"/>
### PUT `[base]/Observation/[:id]`

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "final",
  "subject": {
    "reference": "Patient/10"
  },
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "94564-2"
      }
    ]
  },
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "10828004"
      }
    ]
  },
  "effectiveDateTime": "2021-05-06",
  "issued": "2021-05-07T00:00:00+00:00",
  "resourceType": "Observation",
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
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
      "valueString": "case1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
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

<a name="update-patch-observation"/>
### PATCH `[base]/Observation/[:id]`

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
  { "op": "replace", "path": "/valueCodeableConcept/coding/0", "value":  { "system": "http://snomed.info/sct", "code": "260385009" }}
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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "2020-05-29"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "Low"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "Document results of medical evaluation"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
            "valueString": "case1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Collierview"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "Angola"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
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
      "fullUrl": "http://localhost:3000/fhir/r4/Observation/11",
      "resource": {
        "id": 11,
        "meta": {
          "lastUpdated": "2021-05-06T12:44:19+00:00"
        },
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "94564-2"
            }
          ],
          "text": "IgM Antibody"
        },
        "subject": {
          "reference": "Patient/1"
        },
        "effectiveDateTime": "2021-05-06",
        "issued": "2021-05-07T00:00:00+00:00",
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ],
          "text": "positive"
        },
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

### GET `[base]/Provenance?patient=Patient/[:id]`

You can also use search to find Monitoree histories by using the `patient` parameter.

<a name="search-history-patient"/>

GET `[base]/Provenance?patient=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
    "id": "83890c54-0871-4801-bbdf-b4b29f6c400a",
    "meta": {
        "lastUpdated": "2021-05-28T16:37:43-04:00"
    },
    "type": "searchset",
    "total": 1,
    "entry": [
        {
            "fullUrl": "http://localhost:3000/fhir/r4/Provenance/10183",
            "resource": {
                "id": 10183,
                "meta": {
                    "lastUpdated": "2021-05-26T15:51:19+00:00"
                },
                "extension": [
                    {
                        "url": "http://saraalert.org/StructureDefinition/comment",
                        "valueString": "User enrolled monitoree."
                    },
                    {
                        "url": "http://saraalert.org/StructureDefinition/history-type",
                        "valueString": "Enrollment"
                    }
                ],
                "target": [
                    {
                        "reference": "Patient/954"
                    }
                ],
                "recorded": "2021-05-26T15:51:19+00:00",
                "agent": [
                    {
                        "who": {
                            "identifier": {
                                "value": "locals2c4_enroller@example.com"
                            }
                        },
                        "onBehalfOf": {
                            "reference": "Patient/954"
                        }
                    }
                ],
                "resourceType": "Provenance"
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
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "2020-05-29"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "Low"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "Document results of medical evaluation"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/contact-of-known-case",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/contact-of-known-case-id",
            "valueString": "case1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Collierview"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "Angola"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
            "valueBoolean": true
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

## Transactions
The API supports performing several actions as a single atomic "transaction" for which all of the individual changes succeed or fail together. 

<a name="transaction-post"/>

### POST `[base]`
To perform a transaction, POST a FHIR [Bundle](https://www.hl7.org/fhir/bundle.html) resource to `[base]`. The Bundle must have `Bundle.type` set to `transaction`. There is a limit of 50 resources per transaction. Currently a transaction may only be used to create monitorees and lab results via the FHIR Patient and Observations resources, respectively. The transaction does not need to include Observation resources, and can be used to enroll monitorees in bulk. If a transaction is used to create an Observation, that Observation must reference a Patient being created by the same transaction. The transaction Bundle can contain at most 50 elements in the `Bundle.entry` array. Each entry in the `Bundle.entry` array should contain the following fields:

* `fullUrl` - Must be an identifier for the resource. Since the resources are being created, they do not have a server assigned ID yet. To uniquely identify a resource, generate a UUID, for example: `urn:uuid:9c94a2bc-1929-4666-8099-9e8566b7d9ad`. An Observation should use the `fullUrl` of its corresponding Patient in `Observation.subject.reference`.
* `resource` - Must contain the content of the Observation or Patient that is being created.
* `request.method` - Must be `POST` as this is the only supported operation.
* `request.url` - Must be `Patient` or `Observation`, depending on which resource is being created.

See the FHIR [transaction](https://www.hl7.org/fhir/http.html#transaction) documentation for more details. An example request and response is shown below.

**Request Body:**

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "resourceType": "Bundle",
  "type": "transaction",
  "entry": [
    {
      "fullUrl": "urn:uuid:17b6896d-9fd1-437f-a7bd-6ef7a66116ab",
      "request": {
        "method": "POST",
        "url": "Observation"
      },
      "resource": {
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "94564-2"
            }
          ],
          "text": "IgM Antibody"
        },
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ]
        },
        "subject": {
          "reference": "urn:uuid:9c94a2bc-1929-4666-8099-9e8566b7d9ad"
        },
        "effectiveDateTime": "2021-05-06",
        "issued": "2021-05-07T00:00:00+00:00",
        "resourceType": "Observation"
      }
    },
    {
      "fullUrl": "urn:uuid:9c94a2bc-1929-4666-8099-9e8566b7d9ad",
      "request": {
        "method": "POST",
        "url": "Patient"
      },
      "resource": {
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
            "valueString": "Telephone call"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-date-of-exposure",
            "valueDate": "2020-05-18"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": false
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Smith82",
            "given": ["Malcolm94", "Bogan39"]
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
            "value": "22222222323222@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1981-03-30",
        "address": [
          {
            "line": ["22424 Daphne Key"],
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
                  "display": "eng"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      }
    }
  ]
}
```
  </div>
</details>

**Response:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "ea19333b-2b23-4150-be6d-5c666e8f4414",
  "meta": {
    "lastUpdated": "2021-05-07T14:03:24-04:00"
  },
  "type": "transaction-response",
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/30",
      "resource": {
        "id": 30,
        "meta": {
          "lastUpdated": "2021-05-07T18:03:24+00:00"
        },
        "contained": [
          {
            "target": [
              {
                "reference": "/fhir/r4/Patient/30"
              }
            ],
            "recorded": "2021-05-07T18:03:24+00:00",
            "activity": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
                  "code": "CREATE",
                  "display": "create"
                }
              ]
            },
            "agent": [
              {
                "who": {
                  "identifier": {
                    "value": "ogsaC3PrRzsMZYa1LOXRdu6eJaCc7yWJViGudzNNHBc"
                  },
                  "display": "test-m2m-app"
                }
              }
            ],
            "resourceType": "Provenance"
          }
        ],
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
            "valueString": "Telephone call"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-date-of-exposure",
            "valueDate": "2020-05-18"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": false
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Smith82",
            "given": ["Malcolm94", "Bogan39"]
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
            "value": "22222222323222@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1981-03-30",
        "address": [
          {
            "line": ["22424 Daphne Key"],
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
      },
      "response": {
        "status": "201 Created"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Observation/36",
      "resource": {
        "id": 36,
        "meta": {
          "lastUpdated": "2021-05-07T18:03:24+00:00"
        },
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "94564-2"
            }
          ],
          "text": "IgM Antibody"
        },
        "subject": {
          "reference": "Patient/30"
        },
        "effectiveDateTime": "2021-05-06",
        "issued": "2021-05-07T00:00:00+00:00",
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ],
          "text": "positive"
        },
        "resourceType": "Observation"
      },
      "response": {
        "status": "201 Created"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>


## Bulk Data Export
The API supports exporting monitoree data in bulk according the the [FHIR Bulk Data Access](https://hl7.org/fhir/uv/bulkdata/export/index.html) specification. Instead of making individual requests to gather information, bulk data export supports exporting all available monitoree data at once. The bulk data request flow includes a kick-off request, status requests, and file requests, all of which are described in subsequent sections. This documentation focuses on how bulk data export works in Sara Alert, and for details not included here, please see the 
[specification](https://hl7.org/fhir/uv/bulkdata/export/index.html).
<a name="bulk-data-kick-off"/>

### Kick-off Request - GET `[base]/Patient/$export`
This request begins the asynchronous generation of bulk data. The generated bulk data will include all monitorees for which the client has access, along with the lab results, daily reports, close contacts, immunizations, and history items of those monitorees. Since the client is requesting access to all this data, they must have the correct read scopes for Patient, Observation, QuestionnaireResponse, RelatedPerson, Immunization, and Provenance. A client can begin one bulk data export every 15 minutes. Additionally, kicking off a new request will delete the content of old requests, so a new request should not be started until the content of an old request is no longer needed.

#### Request Headers
* The `Accept` header must be set to `application/fhir+json`.
* The `Prefer` header must be set to `respond-async`.

#### Parameters
* The API supports only the `_since` parameter. If this parameter is specified, only resources for which `meta.lastUpdated` is later than the `_since` time will be included in the response. This parameter should have a [FHIR instant](https://www.hl7.org/fhir/datatypes.html#instant) as its value.
  * **Example:** Get only resources changed since 2021 began: `[base]/Patient/$export?_since=2021-01-01T00:00:00Z`

#### Response on Success
* `202 Accepted` status
* The `Content-Location` header will contain a URL of the form `[base]/ExportStatus/[:id]` which can be used to request the status of the bulk data export.

#### Response on Error
* Error status
  * `403 Forbidden` - The client does not have access to all of the required read scopes, or there is some other issue with their token.
  * `406 Not Acceptable` - Incorrect value for `Accept` header.
  * `422 Unprocessable Entity` - Incorrect format for `_since` parameter, or incorrect value for `Prefer` header.
  * `401 Unauthorized` - The client's API application is not registered for us in the backend services workflow.
  * `429 Too Many Requests` - The client already initiated an export within the last 15 minutes.
* The body of the response will include a FHIR OperationOutcome with an error message indicating the issue.


<a name="bulk-data-status">

### Status Request - GET `[base]/ExportStatus/[:id]`
After a bulk data request has successfully started, the client can use the polling URL returned in the `Content-Location` header of the response to the kick-off request. The `[:id]` in this URL uniquely identifies the client's request. The response will indicate the current status of the export.

#### In Progress
If the generation of data is still in progress, the export will return a `202 Accepted` status.

#### Error
If an error prevents the bulk data export for completing, a `500 Internal Server Error` will indicate this.

#### Complete
Once the export is complete, the status request will return a `200 OK` response. The body of the response will follow the JSON format described in [section 5.3.4](https://hl7.org/fhir/uv/bulkdata/export/index.html#response---complete-status) of the bulk data access specification. An example response is shown below:

```json
{
    "transactionTime": "2021-07-07T21:08:19+00:00",
    "request": "https://demo.saraalert.org/fhir/r4/Patient/$export?_since=2021-07-05T12:02:02Z",
    "requiresAccessToken": true,
    "output": [
        {
            "type": "Patient",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Patient.ndjson"
        },
        {
            "type": "QuestionnaireResponse",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/QuestionnaireResponse.ndjson"
        },
        {
            "type": "Provenance",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Provenance.ndjson"
        },
        {
            "type": "Observation",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Observation.ndjson"
        },
        {
            "type": "Immunization",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Immunization.ndjson"
        },
        {
            "type": "RelatedPerson",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/RelatedPerson.ndjson"
        }
    ]
}
```
The `url` values listed on each element of the `output` array can be used to access the generated exports.


<a name="bulk-data-files">

### File Request - GET `[base]/ExportFiles/[:id]/[:filename]`
Once a client's export is complete, the completed files will be available at this endpoint, where the `[:id]` is the same unique identifier used in the status requests, and the `[:filename]` is of the form `<resourceType>.ndjson`. A valid authorization token with read access to the type of resource being requested is required.

#### Response on Success
The response will have a `200 OK` status, and the body will include the requested resources as a [newline delimited JSON](http://ndjson.org/) file. The example below shows the format of an ndjson file:
```
{"id":1,"name":[{"family":"McCullough24","given":["Eulah20"]}],"resourceType":"Patient"}
{"id":4,"name":[{"family":"Konopelski65","given":["Kirby47"]}],"resourceType":"Patient"}
{"id":6,"name":[{"family":"Herman26","given":["Barton43"]}],"resourceType":"Patient"}
```
Note that the Patients shown in this example are not valid Sara Alert Patients, most elements have been removed for brevity.

#### Response on Error
The response will have a `404 Not Found` status, indicating that either the `[:filename]` parameter does not correspond to a supported FHIR Resource, or that no file of the type indicated by `[:filename]` exists for that `[:id]`.