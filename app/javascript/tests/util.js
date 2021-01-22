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

export {
    nameFormatter,
    nameFormatterAlt,
    addressLine1Formatter,
    addressLine2Formatter,
    addressFullFormatter,
    dateFormatter,
    analyticsDateFormatter
};
