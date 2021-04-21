import axios from 'axios'
import _ from 'lodash'

import reportError from '../components/util/ReportError'
import supportedLanguages from '../data/supportedLanguages'

// Keep a small list of the most common languages on the front-end, and try to match them.
// If we can great, it saves us a call to the back-end
// Otherwise, make an async call to the back-end to do a lookup there
const COMMON_LANGUAGES = {
  'spa-pr': 'Spanish (Puerto Rican)',
  'eng': 'English',
  'spa': 'Spanish',
  'som': 'Somali',
  'fra': 'French',
  'por': 'Portuguese'
}

/**
 * This function attempts to convert an array of iso code strings to an array of iso display names
 * i.e. ['eng', null, 'spa'] to ['English', null, 'Spanish']
 * We keep a list of the most common translations above. They will cover at least 90% of all translations
 * If we can't match it there, we make a call to the back-end to look the up (for only the unmatchable ones)
 * @param {Array} languageCodes - An array of strings of language codes (must be valid). Nulls are allowed, but will be filtered out
 * @param {*} authToken - the authToken
 * @param {*} cb - a callback function to set the values on the front-end when this finishes
 * @return {Array} Returns array of translated language codes (leaves nulls as nulls)
 */
function convertLanguageCodesToNames (languageCodes, authToken, cb) {
  let names = new Array(languageCodes.length)
  let unmatchabledLangs = []
  languageCodes.forEach((code, i) => {
    if (_.isNil(code)) {
      names[i] = null
    } else if (Object.prototype.hasOwnProperty.call(COMMON_LANGUAGES, code)) {
      names[i] = COMMON_LANGUAGES[`${code}`]
    } else {
      unmatchabledLangs.push(i)
    }
  })
  if (unmatchabledLangs.length > 0) {
    axios.defaults.headers.common['X-CSRF-Token'] = authToken;
    axios
      .post(`${window.BASE_PATH}/languages/translate_languages`, {language_codes: unmatchabledLangs.map(i => languageCodes[i])})
      .then(val => {
        const res = val.data.display_names
        unmatchabledLangs.forEach((indexVal, responseIndex) => {
          names[indexVal] = res[responseIndex]
        })
        cb(names)
      })
      .catch(err => {
        reportError(err)
      });
  } else {
    cb(names)
  }
}

/**
 * Returns an object containing all the contact-method booleans
 * for a language. The values default to false, unless specified true in
 * 'supportedLanguages.js'
 * @param {Object} language - must be in the form of {c: isoCode, d: displayName}
 * @return {Object}
 */
function getLanguageSupported(language = {c:null, d:null}) {
  let supportedLanguageReference = supportedLanguages.find(y => y.name === language.d)
  if (supportedLanguageReference) {
    supportedLanguageReference["code"] = language.c
  } else {
    supportedLanguageReference = {
      "name": language.d,
      "code": language.c,
      "supported": {
        "sms": false,
        "email": false,
        "phone": false
      }
    }
  }
  return supportedLanguageReference
}

/**
 * This function returns to cb an array of arrays where each inner
 * array is in the format ["eng", "English"]
 * @param {String} authToken
 * @param {Function} cb - the callback to pass the results to
 * @return {Array} [["eng", "English"]...,["zho","Chinese"],["zul","Zulu"]]
 */
function getAllLanguages (authToken, cb) {
  axios.defaults.headers.common['X-CSRF-Token'] = authToken;
  axios.get(`${window.BASE_PATH}/languages/get_all_languages`)
    .then(val => {
      let allLangs = val.data.map(x => ({ c: x[0], d: x[1] }))
      allLangs = allLangs.sort((a, b) => a.c.localeCompare(b.c))
      cb(allLangs);
    })
    .catch(err => {
      reportError(err);
    })
  }

/**
 * Returns a grouped array of all Languages in the system, formatted to work
 * with react-select (AKA in the format { value: isoCode, label: displayName }).
 * The groups are by whether the language is Supported and Unsupported.
 * These options are all alphabetized as well.
 * @param {String} authToken
 * @param {Function} cb - the callback to pass the results to
 */
function getLanguagesAsOptions (authToken, cb) {
  axios.defaults.headers.common['X-CSRF-Token'] = authToken;
  axios.get(`${window.BASE_PATH}/languages/get_all_languages`)
    .then(val => {
      let allLangs = val.data.map(x => getLanguageSupported({c: x[0], d: x[1]}))
      allLangs = allLangs.sort((a, b) => a.name.localeCompare(b.name))
      const langOptions = allLangs.map(lang => {
        const fullySupported = lang.supported.sms && lang.supported.email && lang.supported.phone;
        const langLabel = fullySupported ? lang.name : lang.name + '*';
        return { value: lang.code, label: langLabel };
      });

      // lodash's 'remove()' actually removes the values from the object
      let supportedLangCodes = supportedLanguages.map(sL => sL.code);
      const supportedLangsFormatted = _.remove(langOptions, n => supportedLangCodes.includes(n.value));
      const unsupportedLangsFormatted = langOptions;

      const groupedOptions = [
        {
          label: 'Supported Languages',
          options: supportedLangsFormatted,
        },
        {
          label: 'Unsupported Languages',
          options: unsupportedLangsFormatted,
        },
      ];
      cb(groupedOptions);

    })
    .catch(err => {
      reportError(err);
    });
};


export {
  getAllLanguages,
  getLanguagesAsOptions,
  getLanguageSupported,
  convertLanguageCodesToNames
};
