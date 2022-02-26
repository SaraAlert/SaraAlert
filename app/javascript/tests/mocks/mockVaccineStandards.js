const mockVaccineStandards = {
  'COVID-19': {
    name: 'COVID-19',
    codes: [
      {
        system: 'http://hl7.org/fhir/sid/cvx',
        code: '213',
      },
    ],
    vaccines: [
      {
        product_name: 'Moderna COVID-19 Vaccine (non-US Spikevax)',
        num_doses: 3,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/cvx',
            code: '207',
          },
        ],
      },
      {
        product_name: 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)',
        num_doses: 3,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/cvx',
            code: '208',
          },
        ],
      },
      {
        product_name: 'Janssen (J&J) COVID-19 Vaccine',
        num_doses: 2,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/cvx',
            code: '212',
          },
        ],
      },
      {
        product_name: 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)',
        num_doses: 3,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/cvx',
            code: '210',
          },
        ],
      },
      {
        product_name: 'Coronavac (Sinovac) COVID-19 Vaccine',
        num_doses: 3,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/cvx',
            code: '511',
          },
        ],
      },
      {
        product_name: 'Sinopharm (BIBP) COVID-19 Vaccine',
        num_doses: 3,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/cvx',
            code: '510',
          },
        ],
      },
    ],
  },
  'Another Condition': {
    name: 'Another Condition',
    codes: [
      {
        system: 'http://hl7.org/fhir/sid/abc',
        code: '000',
      },
    ],
    vaccines: [
      {
        product_name: 'The first vaccine',
        num_doses: 3,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/abc',
            code: '123',
          },
        ],
      },
      {
        product_name: 'The second vaccine',
        num_doses: 1,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/abc',
            code: '456',
          },
        ],
      },
      {
        product_name: 'The third vaccine',
        num_doses: 2,
        product_codes: [
          {
            system: 'http://hl7.org/fhir/sid/abc',
            code: '789',
          },
        ],
      },
    ],
  },
};

export { mockVaccineStandards };
