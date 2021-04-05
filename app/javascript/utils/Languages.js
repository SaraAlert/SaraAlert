import LANGUAGES from '../data/minifiedLanguages.json'
import supportedLanguages from '../data/supportedLanguages'
import _ from 'lodash'

/**
 * Tries to match the input to a language in the system.
 * It accepts isoCodes or Display Names
 * If unable to match it, it returns null
 * @param {Object} potentialCodeorLanguage
 * @return {Object}
 */
function tryToMatchLanguage (potentialCodeorLanguage) {
  if (!potentialCodeorLanguage) return null
  let matchedLang = LANGUAGES.find(o => o.c === potentialCodeorLanguage);
  if (!matchedLang) {
    matchedLang = LANGUAGES.find(o => o.d === potentialCodeorLanguage);
  }
  return matchedLang
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
 * Returns a grouped array of all Languages in the system, formatted to work
 * with react-select (AKA in the format { value: isoCode, label: displayName }).
 * The groups are by whether the language is Supported and Unsupported.
 * These options are all alphabetized as well.
 * @return {Array} groupedOptions
 */
function getLanguagesAsOptions () {
  let allLangs = LANGUAGES.map(x => getLanguageSupported(x))
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
  return groupedOptions;
};

function convertLanguageCodeToName (val) {
  const matchedLang = LANGUAGES.find(o => o.c === val)
  return matchedLang ? matchedLang.d : ''
}

function convertLanguageNameToISOCode (val) {
  const matchedLang = LANGUAGES.find(o => o.d === val)
  return matchedLang ? matchedLang.c : ''
}

export {
  LANGUAGES,
  tryToMatchLanguage,
  getLanguagesAsOptions,
  getLanguageSupported,
  convertLanguageCodeToName,
  convertLanguageNameToISOCode
};
