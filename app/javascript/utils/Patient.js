import React from 'react';
import IconMinor from '../components/patient/household/utils/IconMinor';
import { formatDate } from '../utils/DateTime';
import moment from 'moment-timezone';

/**
 * Formats a patient's name (first middle last) as a string.
 * @param {Object} patient - patient object
 */
function formatName(patient) {
  return `${patient.first_name || ''}${patient.middle_name ? ' ' + patient.middle_name : ''}${patient.last_name ? ' ' + patient.last_name : ''}`;
}

/**
 * Formats a patient's name (last, first middle) as a string.
 * @param {Object} patient - patient object
 */
function formatNameAlt(patient) {
  return `${patient.last_name || ''}, ${patient.first_name || ''}${patient.middle_name ? ' ' + patient.middle_name : ''}`;
}

/**
 * Formats patient's phone number in E164 format.
 * @param {String} phone - patient's phone number
 */
function formatPhoneNumber(phone) {
  if (phone === null || phone === undefined) return '';

  const match = phone
    .replace('+1', '')
    .replace(/\D/g, '')
    .match(/^(\d{3})(\d{3})(\d{4})$/);
  return match ? +match[1] + '-' + match[2] + '-' + match[3] : '';
}

/**
 * Formats patient's races as a string.
 * @param {Object} patient - patient object
 */
function formatRace(patient) {
  let raceArray = [];
  if (patient.white) {
    raceArray.push('White');
  }
  if (patient.black_or_african_american) {
    raceArray.push('Black or African American');
  }
  if (patient.asian) {
    raceArray.push('Asian');
  }
  if (patient.american_indian_or_alaska_native) {
    raceArray.push('American Indian or Alaska Native');
  }
  if (patient.native_hawaiian_or_other_pacific_islander) {
    raceArray.push('Native Hawaiian or Other Pacific Islander');
  }
  if (patient.race_other) {
    raceArray.push('Other');
  }
  if (patient.race_unknown) {
    raceArray.push('Unknown');
  }
  if (patient.race_refused_to_answer) {
    raceArray.push('Refused to Answer');
  }
  return raceArray.length === 0 ? '--' : raceArray.join(', ');
}

/**
 * Formats values in the date of birth column to be human readable and include whether that DOB indicates a minor.
 * @param {Object} data - Data about the cell this filter is called on.
 */
function formatDateOfBirth(data) {
  const rowData = data.rowData;
  if (!!rowData?.dob && moment(rowData.dob, 'YYYY-MM-DD').isAfter(moment().subtract(18, 'years'))) {
    return (
      <div>
        <IconMinor patientId={rowData.id.toString()} customClass={'float-right ml-1'} />
        {formatDate(rowData.dob)}
      </div>
    );
  }
  if (!!rowData?.date_of_birth && moment(rowData.date_of_birth, 'YYYY-MM-DD').isAfter(moment().subtract(18, 'years'))) {
    return (
      <div>
        <IconMinor patientId={rowData.id.toString()} customClass={'float-right ml-1'} />
        {formatDate(rowData.date_of_birth)}
      </div>
    );
  }
  if (!!rowData?.date_of_birth) {
    return formatDate(rowData.date_of_birth);
  }
  return formatDate(rowData.dob);
}

export { formatName, formatNameAlt, formatPhoneNumber, formatRace, formatDateOfBirth };
