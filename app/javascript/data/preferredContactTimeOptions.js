export const customPreferredContactTimeOptions = {
  0: 'Midnight',
  1: '1:00',
  2: '2:00',
  3: '3:00',
  4: '4:00',
  5: '5:00',
  6: '6:00',
  7: '7:00',
  8: '8:00',
  9: '9:00',
  10: '10:00',
  11: '11:00',
  12: '12:00',
  13: '13:00',
  14: '14:00',
  15: '15:00',
  16: '16:00',
  17: '17:00',
  18: '18:00',
  19: '19:00',
  20: '20:00',
  21: '21:00',
  22: '22:00',
  23: '23:00',
};

export const customPreferredContactTimeGroupedOptions = [
  {
    label: 'Early',
    options: [
      { label: 'Midnight', value: '0' },
      { label: '1:00', value: '1' },
      { label: '2:00', value: '2' },
      { label: '3:00', value: '3' },
      { label: '4:00', value: '4' },
      { label: '5:00', value: '5' },
      { label: '6:00', value: '6' },
      { label: '7:00', value: '7' },
    ],
  },
  {
    label: 'Morning',
    options: [
      { label: '8:00', value: '8' },
      { label: '9:00', value: '9' },
      { label: '10:00', value: '10' },
      { label: '11:00', value: '11' },
    ],
  },
  {
    label: 'Afternoon',
    options: [
      { label: '12:00', value: '12' },
      { label: '13:00', value: '13' },
      { label: '14:00', value: '14' },
      { label: '15:00', value: '15' },
    ],
  },
  {
    label: 'Evening',
    options: [
      { label: '16:00', value: '16' },
      { label: '17:00', value: '17' },
      { label: '18:00', value: '18' },
      { label: '19:00', value: '19' },
    ],
  },
  {
    label: 'Late',
    options: [
      { label: '20:00', value: '20' },
      { label: '21:00', value: '21' },
      { label: '22:00', value: '22' },
      { label: '23:00', value: '23' },
    ],
  },
];

export const basicPreferredContactTimeOptions = ['', 'Morning', 'Afternoon', 'Evening', 'Custom...'].map(option => {
  return { label: option, value: option };
});
