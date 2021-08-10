import axios from 'axios';
import _ from 'lodash';

import reportError from '../components/util/ReportError';

// Keep a small list of the most common languages on the front-end, and try to match them.
// If we can great, it saves us a call to the back-end
// Otherwise, make an async call to the back-end to do a lookup there
const COMMON_LANGUAGES = {
  eng: 'English',
  fra: 'French',
  spa: 'Spanish',
  'spa-pr': 'Spanish (Puerto Rican)',
  por: 'Portuguese',
  som: 'Somali',
  vie: 'Vietnamese',
  kor: 'Korean',
  rus: 'Russian',
  ara: 'Arabic',
};

/**
 * This function attempts to convert an array of iso code strings to an array of iso display names
 * i.e. ['eng', null, 'spa'] to ['English', null, 'Spanish']
 * We keep a list of the most common translations above. They will cover at least 90% of all translations
 * If we can't match it there, we make a call to the back-end to look the up (for only the unmatchable ones)
 * @param {Array} languageCodes - An array of strings of language codes (must be valid). Nulls are allowed, but will be filtered out
 * @param {String} authToken - the authToken
 * @param {Function} callback - a callback function to set the values on the front-end when this finishes
 * @return {Array} Returns array of translated language codes (leaves nulls as nulls)
 */
function convertLanguageCodesToNames(languageCodes, authToken, callback) {
  let names = new Array(languageCodes.length);
  let unmatchabledLangs = [];
  languageCodes.forEach((code, i) => {
    if (_.isNil(code)) {
      names[i] = null;
    } else if (Object.prototype.hasOwnProperty.call(COMMON_LANGUAGES, code)) {
      names[i] = COMMON_LANGUAGES[`${code}`];
    } else {
      unmatchabledLangs.push(i);
    }
  });
  if (unmatchabledLangs.length > 0) {
    axios.defaults.headers.common['X-CSRF-Token'] = authToken;
    axios
      .post(`${window.BASE_PATH}/languages/translate_languages`, { language_codes: unmatchabledLangs.map(i => languageCodes[i]) })
      .then(val => {
        const res = val.data.display_names;
        unmatchabledLangs.forEach((indexVal, responseIndex) => {
          names[indexVal] = res[responseIndex];
        });
        callback(names);
      })
      .catch(err => {
        reportError(err);
      });
  } else {
    callback(names);
  }
}

/**
 * This function returns to the callback an array of all language display names (alphabetized)
 * @param {String} authToken
 * @param {Function} callback - the callback to pass the results to
 * @return {Array of Strings} ["English","Chinese",..."Zulu"]
 */
function getAllLanguageDisplayNames(authToken, callback) {
  axios.defaults.headers.common['X-CSRF-Token'] = authToken;
  axios
    .get(`${window.BASE_PATH}/languages/get_all_languages`)
    .then(val => {
      let languageDisplayNames = _.values(val.data)
        .map(x => x.display)
        .sort((a, b) => a.localeCompare(b));
      callback(languageDisplayNames);
    })
    .catch(err => {
      reportError(err);
    });
}

/**
 * Returns to the callback all languages from the backend (alphabetized), in the format of:
 * [{code: 'eng', display: 'English', supported: {sms: true, phone: true, email: false}}, {...}]
 * @param {String} authToken
 * @param {Function} callback - the callback to pass the results to
 * @return {Array of Objects}
 */
function getLanguageData(authToken, callback) {
  axios.defaults.headers.common['X-CSRF-Token'] = authToken;
  axios
    .get(`${window.BASE_PATH}/languages/get_all_languages`)
    .then(val => {
      let languageData = [];
      _.forIn(val.data, (value, key) => {
        languageData.push({
          code: key,
          display: value.display,
          supported: value.supported || {},
        });
      });
      languageData.sort((a, b) => a.display.localeCompare(b.display));
      callback(languageData);
    })
    .catch(err => {
      reportError(err);
    });
}

export { getAllLanguageDisplayNames, getLanguageData, convertLanguageCodesToNames };
