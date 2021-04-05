// Every language in languages.yml will be included in our Languages dropdowns.
// However, they will all be given values of `false` for `sms`, `email`, and `phone`
// Unless that field is specifically listed as `true` in `supportedLanguages` below

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

export default supportedLanguages;
