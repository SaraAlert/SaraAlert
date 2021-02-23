import moment from 'moment';

/** formats patient name as it is done when the field is displayed */
function nameFormatter(patient) {
  return `${patient.first_name ? patient.first_name : ''}${patient.middle_name ? ' ' + patient.middle_name : ''}${patient.last_name ? ' ' + patient.last_name : ''}`;
}

/** formats patient name with last name first (ex: Smith, John Harold) */
function nameFormatterAlt(patient) {
  return `${patient.last_name ? patient.last_name + ',' : ''}${patient.first_name ? ' ' + patient.first_name : ''}${patient.middle_name ? ' ' + patient.middle_name : ''}`;
}

/** formats address line 1 (number/street/etc) as it is done when the field is displayed */
function addressLine1Formatter(patient) {
  return `${patient.address_line_1 ? `${patient.address_line_1}` : ''}${patient.address_line_2 ? ` ${patient.address_line_2}` : ''}${patient.foreign_address_line_1 ? `${patient.foreign_address_line_1}` : ''}${patient.foreign_address_line_2 ? ` ${patient.foreign_address_line_2}` : ''}`;
}

/** formats address line 2 (city/state/zip/etc) as it is done when the field is displayed */
function addressLine2Formatter(patient) {
  return `${patient.address_city ? patient.address_city : ''}${patient.address_state ? ` ${patient.address_state}` : ''}${patient.address_county ? ` ${patient.address_county}` : ''}${patient.address_zip ? ` ${patient.address_zip}` : ''}${patient.foreign_address_city ? patient.foreign_address_city : ''}${patient.foreign_address_country ? ` ${patient.foreign_address_country}` : ''}${patient.foreign_address_zip ? ` ${patient.foreign_address_zip}` : ''}`;
}

/** formats full address as it is done when the field is displayed */
function addressFullFormatter(patient) {
  return `${addressLine1Formatter(patient)} ${addressLine2Formatter(patient)}`;
}

/** formats date as it is done when the field is displayed (MM/DD/YYYY)  */
function dateFormatter(date) {
  return `${moment(date, 'YYYY-MM-DD').format('MM/DD/YYYY')}`;
}

/** formats date as it is done on the analytics page (YYYY-MM-DD HH:mm z)  */
function analyticsDateFormatter(date) {
  return `${moment.tz(date, 'UTC').tz(moment.tz.guess()).format('YYYY-MM-DD HH:mm z')}`;
}

/** sorts array of patients alphabetically by last name, then by first name  */
function sortByNameAscending(patients) {
  return patients.sort((a, b) => {
    return a.first_name.localeCompare(b.first_name);
  })
  .sort((a, b) => {
    return a.last_name.localeCompare(b.last_name);
  });
}

/** sorts array of patients reverse alphabetically by last name, then by first name  */
function sortByNameDescending(patients) {
  return patients.sort((a, b) => {
    return b.first_name.localeCompare(a.first_name);
  })
  .sort((a, b) => {
    return b.last_name.localeCompare(a.last_name);
  });
}

/** sorts array of patients by specified date field oldest to youngest */
function sortByDateAscending(patients, field) {
  return patients.sort((a, b) => {
    return moment(a[field]).format('YYYYMMDD') - moment(b[field]).format('YYYYMMDD');
  });
}

/** sorts array of patients by specified date field youngest to oldest */
function sortByDateDescending(patients, field) {
  return patients.sort((a, b) => {
    return moment(b[field]).format('YYYYMMDD') - moment(a[field]).format('YYYYMMDD');
  });
}

/** sorts array of patients alphabetically by specified field */
function sortByAscending(patients, field) {
  return patients.sort((a, b) => {
    return a[field] - b[field];
  });
}

/** sorts array of patients reverse alphabetically by specified field  */
function sortByDescending(patients, field) {
  return patients.sort((a, b) => {
    return b[field] - a[field];
  });
}

export {
  nameFormatter,
  nameFormatterAlt,
  addressLine1Formatter,
  addressLine2Formatter,
  addressFullFormatter,
  dateFormatter,
  analyticsDateFormatter,
  sortByNameAscending,
  sortByNameDescending,
  sortByDateAscending,
  sortByDateDescending,
  sortByAscending,
  sortByDescending
};
