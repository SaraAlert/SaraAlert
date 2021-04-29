---
layout: default
title: NBS Interface Specification
parent: API
nav_order: 5
---
<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

# NBS API Specification

To support interoperabilty with NBS, the Sara Alert API provides an endpoint that can be used to export monitorees in the Public Health Document Container (PHDC) format.

<a name="supported-scopes"/>

## Supported Scopes
This endpoint is only supported for applications following the [SMART on FHIR Backend Services Workflow](api-getting-started#backend-services), and applications should follow the process detailed in that section to authenticate. To access this endpoint the following scopes are required:

* One of `system/Patient.read` or `system/Patient.*`
* `system/QuestionnaireResponse.read`

<a name="export"/>

## Bulk Export of Monitorees in PHDC Format

<a name="export-get"/>

The API supports exporting monitorees to a zip file in PHDC format. The monitorees can be filtered by certain parameters. At least one parameter must be present; if no parameters are given, no monitorees will be found, and an empty zip file will be returned. Applications should make requests to:

GET `[base]/api/nbs/patient?parameter(s)`

The allowed parameters are:
* `workflow` - One of `isolation` or `exposure`.
  * `isolation` - Only monitorees in the Isolation workflow are included.
  * `exposure` - Only monitorees in the Exposure workflow are included.
  * Omitted - Monitorees in both workflows are included.
* `monitoring` - One of `true` or `false`.
  * `true` - Only monitorees under active monitoring are included.
  * `false` - Only monitorees not under active monitoring are included.
  * Omitted - Monitorees under active monitoring and monitorees not under active monitoring are included.
* `caseStatus` - One or more of `confirmed`, `probable`, `suspect`, `unknown`, `not a case`. When this parameter is present, only monitorees for which one of the given values applies will be included in the response. To pass multiple values, separate the values with commas, for example: `caseStatus=confirmed,probable`. When this parameter is omitted, monitorees of all possible case status values will be included in the response.
* `updatedSince` - This parameter should be a date value of the form YYYY-MM-DD or YYYY-MM-DDThh:mm:ss+zz:zz. When this parameter is specified, only monitorees which have been updated since the time provided will be included in the response. If the value is of the form YYYY-MM-DD, that is interpreted as YYYY-MM-DD:00:00:00+00:00, i.e. monitorees updated since the beginning of that day will be included in the response.

Some example requests are shown below:
* GET `[base]/api/nbs/patient?workflow=isolation&caseStatus=confirmed` - Get all monitorees in the Isolation workflow with a `confirmed` case status.
* GET `[base]/api/nbs/patient?caseStatus=confirmed,probable&monitoring=false` - Get all monitorees with a `confirmed` or `probable` case status that are not under active monitoring.
* GET `[base]/api/nbs/patient?updatedSince=2021-04-01&monitoring=true` - Get all monitorees under active monitoring that have been updated since the beginning of the day on April 1, 2021.

The requesting application should set the `Accept` header to `application/zip`, as that is the format of the response. When unzipped, the response will contain XML files following the PHDC format, and each file is named by the ID of the monitoree it represents.