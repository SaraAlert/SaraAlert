/**
 * Objects used for configuring and populating analytics maps.
 */

// Amcharts gets finicky with its internal map projections using certain iso codes, hence not all are `US-XX`
export const insularAreas = [
  { abbrv: 'AS', isoCode: 'US-AS', name: 'American Samoa', mapFile: 'usaTerritories' },
  { abbrv: 'FM', isoCode: 'US-FM', name: 'Federated States of Micronesia', mapFile: 'usaTerritories' },
  { abbrv: 'GU', isoCode: 'US-GU', name: 'Guam', mapFile: 'usaTerritories' },
  { abbrv: 'MH', isoCode: 'MH', name: 'Marshall Islands', mapFile: 'usaTerritories' },
  { abbrv: 'MP', isoCode: 'US-MP', name: 'Northern Mariana Islands', mapFile: 'usaTerritories' },
  { abbrv: 'PW', isoCode: 'PW', name: 'Palau', mapFile: 'usaTerritories' },
  { abbrv: 'PR', isoCode: 'US-PR', name: 'Puerto Rico', mapFile: 'usaTerritories' },
  { abbrv: 'VI', isoCode: 'US-VI', name: 'Virgin Islands', mapFile: 'usaTerritories' },
];
