# frozen_string_literal: true

# Helper methods for the pat model
module PatientHelper
  def normalize_state_names(pat)
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
      'districtofcolombia' => 'District of Columbia',
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
    pat.monitored_address_state = state_names[normalize_name(pat.monitored_address_state)] || pat.monitored_address_state
    pat.address_state = state_names[normalize_name(pat.address_state)] || pat.address_state
    adpt = pat.additional_planned_travel_destination_state
    pat.additional_planned_travel_destination_state = state_names[normalize_name(adpt)] || adpt
  end

  def normalize_name(name)
    return nil if name.nil?

    name.delete(" \t\r\n").downcase
  end
end
