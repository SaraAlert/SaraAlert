# frozen_string_literal: true

# Helper methods for the patient model
module PatientHelper # rubocop:todo Metrics/ModuleLength
  def normalize_state_names(pat)
    pat.monitored_address_state = normalize_and_get_state_name(pat.monitored_address_state) || pat.monitored_address_state
    pat.address_state = normalize_and_get_state_name(pat.address_state) || pat.address_state
    adpt = pat.additional_planned_travel_destination_state
    pat.additional_planned_travel_destination_state = normalize_and_get_state_name(adpt) || adpt
  end

  def normalize_name(name)
    return nil if name.nil?

    name.delete(" \t\r\n").downcase
  end

  def normalize_and_get_state_name(name)
    # This list contains all of the same states listed in app/javascript/components/data.js
    state_names = {
      'alabama' => 'Alabama',
      'alaska' => 'Alaska',
      'americansamoa' => 'American Samoa',
      'arizona' => 'Arizona',
      'arkansas' => 'Arkansas',
      'california' => 'California',
      'colorado' => 'Colorado',
      'connecticut' => 'Connecticut',
      'delaware' => 'Delaware',
      'districtofcolumbia' => 'District of Columbia',
      'federatedstatesofmicronesia' => 'Federated States of Micronesia',
      'florida' => 'Florida',
      'georgia' => 'Georgia',
      'guam' => 'Guam',
      'hawaii' => 'Hawaii',
      'idaho' => 'Idaho',
      'illinois' => 'Illinois',
      'indiana' => 'Indiana',
      'iowa' => 'Iowa',
      'kansas' => 'Kansas',
      'kentucky' => 'Kentucky',
      'louisiana' => 'Louisiana',
      'maine' => 'Maine',
      'marshallislands' => 'Marshall Islands',
      'maryland' => 'Maryland',
      'massachusetts' => 'Massachusetts',
      'michigan' => 'Michigan',
      'minnesota' => 'Minnesota',
      'mississippi' => 'Mississippi',
      'missouri' => 'Missouri',
      'montana' => 'Montana',
      'nebraska' => 'Nebraska',
      'nevada' => 'Nevada',
      'newhampshire' => 'New Hampshire',
      'newjersey' => 'New Jersey',
      'newmexico' => 'New Mexico',
      'newyork' => 'New York',
      'northcarolina' => 'North Carolina',
      'northdakota' => 'North Dakota',
      'northernmarianaislands' => 'Northern Mariana Islands',
      'ohio' => 'Ohio',
      'oklahoma' => 'Oklahoma',
      'oregon' => 'Oregon',
      'palau' => 'Palau',
      'pennsylvania' => 'Pennsylvania',
      'puertorico' => 'Puerto Rico',
      'rhodeisland' => 'Rhode Island',
      'southcarolina' => 'South Carolina',
      'southdakota' => 'South Dakota',
      'tennessee' => 'Tennessee',
      'texas' => 'Texas',
      'utah' => 'Utah',
      'vermont' => 'Vermont',
      'virginislands' => 'Virgin Islands',
      'virginia' => 'Virginia',
      'washington' => 'Washington',
      'westvirginia' => 'West Virginia',
      'wisconsin' => 'Wisconsin',
      'wyoming' => 'Wyoming'
    }
    state_names[normalize_name(name)] || nil
  end

  def timezone_for_state(name)
    # Offsets are DST
    timezones = {
      'alabama' => { offset: -5, observes_dst: true },
      'alaska' => { offset: -8, observes_dst: true },
      'americansamoa' => { offset: -11, observes_dst: false },
      'arizona' => { offset: -7, observes_dst: false },
      'arkansas' => { offset: -5, observes_dst: true },
      'california' => { offset: -7, observes_dst: true },
      'colorado' => { offset: -6, observes_dst: true },
      'connecticut' => { offset: -4, observes_dst: true },
      'delaware' => { offset: -4, observes_dst: true },
      'districtofcolumbia' => { offset: -4, observes_dst: true },
      'federatedstatesofmicronesia' => { offset: 11, observes_dst: false },
      'florida' => { offset: -4, observes_dst: true },
      'georgia' => { offset: -4, observes_dst: true },
      'guam' => { offset: 10, observes_dst: false },
      'hawaii' => { offset: -10, observes_dst: false },
      'idaho' => { offset: -6, observes_dst: true },
      'illinois' => { offset: -5, observes_dst: true },
      'indiana' => { offset: -4, observes_dst: true },
      'iowa' => { offset: -5, observes_dst: true },
      'kansas' => { offset: -5, observes_dst: true },
      'kentucky' => { offset: -4, observes_dst: true },
      'louisiana' => { offset: -5, observes_dst: true },
      'maine' => { offset: -4, observes_dst: true },
      'marshallislands' => { offset: 12, observes_dst: false },
      'maryland' => { offset: -4, observes_dst: true },
      'massachusetts' => { offset: -4, observes_dst: true },
      'michigan' => { offset: -4, observes_dst: true },
      'minnesota' => { offset: -5, observes_dst: true },
      'mississippi' => { offset: -5, observes_dst: true },
      'missouri' => { offset: -5, observes_dst: true },
      'montana' => { offset: -6, observes_dst: true },
      'nebraska' => { offset: -5, observes_dst: true },
      'nevada' => { offset: -7, observes_dst: true },
      'newhampshire' => { offset: -4, observes_dst: true },
      'newjersey' => { offset: -4, observes_dst: true },
      'newmexico' => { offset: -6, observes_dst: true },
      'newyork' => { offset: -4, observes_dst: true },
      'northcarolina' => { offset: -4, observes_dst: true },
      'northdakota' => { offset: -5, observes_dst: true },
      'northernmarianaislands' => { offset: 10, observes_dst: false },
      'ohio' => { offset: -4, observes_dst: true },
      'oklahoma' => { offset: -5, observes_dst: true },
      'oregon' => { offset: -7, observes_dst: true },
      'palau' => { offset: 9, observes_dst: false },
      'pennsylvania' => { offset: -4, observes_dst: true },
      'puertorico' => { offset: -4, observes_dst: false },
      'rhodeisland' => { offset: -4, observes_dst: true },
      'southcarolina' => { offset: -4, observes_dst: true },
      'southdakota' => { offset: -5, observes_dst: true },
      'tennessee' => { offset: -5, dobserves_dstst: true },
      'texas' => { offset: -5, observes_dst: true },
      'utah' => { offset: -6, observes_dst: true },
      'vermont' => { offset: -4, observes_dst: true },
      'virginislands' => { offset: -4, observes_dst: false },
      'virginia' => { offset: -4, observes_dst: true },
      'washington' => { offset: -7, observes_dst: true },
      'westvirginia' => { offset: -4, observes_dst: true },
      'wisconsin' => { offset: -5, observes_dst: true },
      'wyoming' => { offset: -6, observes_dst: true },
      nil => { offset: -4, observes_dst: true },
      '' => { offset: -4, observes_dst: true }
    }
    # Grab timezone using lookup
    timezone = timezones[normalize_name(name)]

    # Grab offset
    offset = timezone.nil? ? -4 : timezone[:offset]

    # Adjust for DST (if observed)
    offset -= 1 if timezone && timezone[:observes_dst] && !Time.use_zone('Eastern Time (US & Canada)') { Time.now.dst? }

    # Format and return
    (offset.negative? ? '' : '+') + format('%<offset>.2d', offset: offset) + ':00'
  end

  def self.languages(language)
    languages = {
      'arabic': { code: 'ar', display: 'Arabic', system: 'urn:ietf:bcp:47' },
      'bengali': { code: 'bn', display: 'Bengali', system: 'urn:ietf:bcp:47' },
      'czech': { code: 'cs', display: 'Czech', system: 'urn:ietf:bcp:47' },
      'danish': { code: 'da', display: 'Danish', system: 'urn:ietf:bcp:47' },
      'german': { code: 'de', display: 'German', system: 'urn:ietf:bcp:47' },
      'greek': { code: 'el', display: 'Greek', system: 'urn:ietf:bcp:47' },
      'english': { code: 'en', display: 'English', system: 'urn:ietf:bcp:47' },
      'spanish': { code: 'es', display: 'Spanish', system: 'urn:ietf:bcp:47' },
      'finnish': { code: 'fi', display: 'Finnish', system: 'urn:ietf:bcp:47' },
      'french': { code: 'fr', display: 'French', system: 'urn:ietf:bcp:47' },
      'frysian': { code: 'fy', display: 'Frysian', system: 'urn:ietf:bcp:47' },
      'hindi': { code: 'hi', display: 'Hindi', system: 'urn:ietf:bcp:47' },
      'croatian': { code: 'hr', display: 'Croatian', system: 'urn:ietf:bcp:47' },
      'italian': { code: 'it', display: 'Italian', system: 'urn:ietf:bcp:47' },
      'japanese': { code: 'ja', display: 'Japanese', system: 'urn:ietf:bcp:47' },
      'korean': { code: 'ko', display: 'Korean', system: 'urn:ietf:bcp:47' },
      'dutch': { code: 'nl', display: 'Dutch', system: 'urn:ietf:bcp:47' },
      'norwegian': { code: 'no', display: 'Norwegian', system: 'urn:ietf:bcp:47' },
      'punjabi': { code: 'pa', display: 'Punjabi', system: 'urn:ietf:bcp:47' },
      'polish': { code: 'pl', display: 'Polish', system: 'urn:ietf:bcp:47' },
      'portuguese': { code: 'pt', display: 'Portuguese', system: 'urn:ietf:bcp:47' },
      'russian': { code: 'ru', display: 'Russian', system: 'urn:ietf:bcp:47' },
      'serbian': { code: 'sr', display: 'Serbian', system: 'urn:ietf:bcp:47' },
      'swedish': { code: 'sv', display: 'Swedish', system: 'urn:ietf:bcp:47' },
      'telegu': { code: 'te', display: 'Telegu', system: 'urn:ietf:bcp:47' },
      'chinese': { code: 'zh', display: 'Chinese', system: 'urn:ietf:bcp:47' },
      'vietnamese': { code: 'vi', display: 'Vietnamese', system: 'urn:ietf:bcp:47' },
      'tagalog': { code: 'tl', display: 'Tagalog', system: 'urn:ietf:bcp:47' },
      'somali': { code: 'so', display: 'Somali', system: 'urn:ietf:bcp:47' },
      'nepali': { code: 'ne', display: 'Nepali', system: 'urn:ietf:bcp:47' },
      'swahili': { code: 'sw', display: 'Swahili', system: 'urn:ietf:bcp:47' },
      'burmese': { code: 'my', display: 'Burmese', system: 'urn:ietf:bcp:47' },
      'spanish (puerto rican)': { code: 'es-PR', display: 'Spanish (Puerto Rican)', system: 'urn:ietf:bcp:47' }
    }
    languages[language&.downcase&.to_sym].present? ? languages[language&.downcase&.to_sym] : nil
  end
end
