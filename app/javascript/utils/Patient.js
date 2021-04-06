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

export { formatName, formatNameAlt, formatPhoneNumber, formatRace };
