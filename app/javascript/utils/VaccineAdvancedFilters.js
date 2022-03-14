import _ from 'lodash';

/**
 * Transforms the vaccine_standards configuration in /config/vaccines.yml to match structure in app/javascript/data/advancedFilterOptions.js
 * @param {vaccine_standards} vaccine_standards - vaccine_standards object
 */
const getVaccineAdvancedFilters = (vaccine_standards) => {
  return {
    name: 'vaccination',
    title: 'Vaccination (Combination)',
    description: 'Monitorees with specified Vaccination criteria',
    type: 'combination',
    tooltip:'Returns records that contain at least one Vaccination entry that meets all user-specified criteria (e.g., searching for a specific Vaccination Product Name and Administration Date will only return records containing at least one Vaccination entry with matching values in both fields).',
    fields: getVaccineAdvancedFilterFields(vaccine_standards),
  }
}

const getVaccineAdvancedFilterFields = (vaccine_standards) => {
  let vaccineGroupOptions = [];
  let productNameOptions = [];
  let doseNumberOptions = [];
  let fields = [];

  for (const [, value] of Object.entries(vaccine_standards)) {
    vaccineGroupOptions.push(value["name"]);
    productNameOptions = productNameOptions.concat(_.map(value["vaccines"], "product_name"));
    doseNumberOptions = doseNumberOptions.concat(_.map(value["vaccines"], "num_doses"));
  }

  const minDose = Math.min(...doseNumberOptions);
  /* If the minDose is greater than 1, fill the doseNumberOptions array with integers from 1...minDose */
  if(minDose > 1) {
    doseNumberOptions = Array.from({length: minDose - 1 }, (_, i) => i + 1).concat(doseNumberOptions);
  }

  fields.push(selectTypeFilter('vaccine-group', 'vaccine group', vaccineGroupOptions));
  fields.push(selectTypeFilter('product-name', 'product name', _.uniq([...productNameOptions, 'Unknown'])));
  fields.push(selectTypeFilter('dose-number', 'dose number', _.uniq(['', ...doseNumberOptions.sort(), 'Unknown'])));
  fields.push(dateTypeFilter('administration-date', 'administration date'));

  return fields;
}

const selectTypeFilter = (name, title, options) => {
  return {
    name: name,
    title: title,
    type: 'select',
    options: options
  }
}

const dateTypeFilter = (name, title) => {
  return {
    name: name,
    title: title,
    type: 'date',
  }
}

export { getVaccineAdvancedFilters };
