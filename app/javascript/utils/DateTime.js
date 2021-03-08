import moment from 'moment-timezone';

/**
  * Formats values in the timestamp column to be human readable
  * @param {Object} data - Data about the cell this filter is called on.
*/
function formatTimestamp(data) {
  // Some components will call this with an object containing a value field containing a timestamp
  // Others will pass in a timestamp value directly
  const timestamp = (Object.prototype.hasOwnProperty.call(data, 'value')) ? data.value : data
  const ts = moment.tz(timestamp, 'UTC');
  return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
}

/**
 * Formats a date value into consistent format.
 * @param {Object} data - provided by CustomTable about each cell in the column this filter is called in.
*/
function formatDate(data) {
  const date = data.value;
  return date ? moment(date, 'YYYY-MM-DD').format('MM/DD/YYYY') : '';
}

export {
  formatTimestamp,
  formatDate
};
