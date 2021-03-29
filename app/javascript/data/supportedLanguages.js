// Every language in languages.yml will be included in our Languages dropdowns.
// However, they will all be given values of `false` for `sms`, `email`, and `phone`
// Unless that field is specifically listed as `true` in `supportedLanguages` below

import minifiedLanguages from './minifiedLanguages.json'

const supportedLanguages = [
    {
      'name': 'English',
      'code': 'eng',
      'supported': {
        'sms': true,
        'email': true,
        'phone': true
      }
    },
    {
      'name': 'French',
      'code': 'fra',
      'supported': {
        'sms': true,
        'email': true,
        'phone': true
      }
    },
    {
      'name': 'Spanish',
      'code': 'spa',
      'supported': {
        'sms': true,
        'email': true,
        'phone': true
      }
    },
    {
      'name': 'Spanish (Puerto Rican)',
      'code': 'spa-PR',
      'supported': {
        'sms': true,
        'email': true,
        'phone': true
      }
    },
    {
      'name': 'Somali',
      'code': 'som',
      'supported': {
        'sms': true,
        'email': true,
        'phone': false
      }
    }
  ]

const getAllLanguages = () => {
  // minifiedLanguages is a duplicate of the information in languages.yml
  // The `c` field stands for `code` name, and the `d` for `display` name
  // FIX_ME: Send the `languages.yml` file from the backend to avoid data duplication
  let allLangs = minifiedLanguages.map(x => {
      let supportedLanguageReference = supportedLanguages.find(y => y.name === x.d)
      if (supportedLanguageReference) {
        supportedLanguageReference["code"] = x.c
      } else {
        supportedLanguageReference = {
          "name": x.d,
          "code": x.c,
          "supported": {
            "sms": false,
            "email": false,
            "phone": false
          }
        }
      }
      return supportedLanguageReference
    })
    return allLangs.sort((a, b) => a.name.localeCompare(b.name))
}

export {
  getAllLanguages,
  supportedLanguages
}
