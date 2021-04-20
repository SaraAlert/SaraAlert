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
  // Some components will call this with an object containing a value field containing a date
  // Others will pass in a date value directly
  const date = (Object.prototype.hasOwnProperty.call(data, 'value')) ? data.value : data
  return date ? moment(date, 'YYYY-MM-DD').format('MM/DD/YYYY') : '';
}

/**
 * Formats a date value into text string that indicates how far in the past the date is.
 * EX: "4 days ago" or "1 year ago"
 * @param {Object} date - date string
 */
function formatRelativePast(date) {
  var intervalType;
  var now = moment();
  var then = moment(date).toDate();  
  var duration = moment.duration(now.diff(then));
  var interval = duration.years();

  if (interval >= 1) {
    intervalType = 'year';
  } else {
    interval = duration.months();
    if (interval >= 1) {
      intervalType = 'month';
    } else {
      interval = duration.days();
      if (interval >= 1) {
        intervalType = 'day';
      } else {
        interval = duration.hours();
        if (interval >= 1) {
          intervalType = 'hour';
        } else {
          interval = duration.minutes();
          if (interval >= 1) {
            intervalType = 'minute';
          } else {
            return 'less than a minute ago';
          }
        }
      }
    }
  }

  if (interval > 1) {
    intervalType += 's';
  }

  return `${interval} ${intervalType} ago`;
}


export {
  formatTimestamp,
  formatDate,
  formatRelativePast
};
