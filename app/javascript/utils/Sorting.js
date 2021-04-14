/**
  * Compare function for sorting the Object.entries elements in the jurisdiction drop down list
  * @param {Object} a - One Object.entries element to compare
  * @param {Object} b - Another Object.entries element to compare
*/
function compareJurisdictionObjectEntries(objectEntryA, objectEntryB) {
  const jurisdictionA = objectEntryA.props.value.toUpperCase();
  const jurisdictionB = objectEntryB.props.value.toUpperCase();

  let comparison = 0;
  if (jurisdictionA > jurisdictionB) {
    comparison = 1;
  } else if (jurisdictionA < jurisdictionB) {
    comparison = -1;
  }
  return comparison;
};

/**
  * Compare function for sorting the Array elements in the jurisdiction drop down list
  * @param {Object} a - One Array element to compare
  * @param {Object} b - Another Array element to compare
*/
function compareJurisdictionArrayElements(arrayElementA, arrayElementB) {
  const jurisdictionA = arrayElementA.label.toUpperCase();
  const jurisdictionB = arrayElementB.label.toUpperCase();

  let comparison = 0;
  if (jurisdictionA > jurisdictionB) {
    comparison = 1;
  } else if (jurisdictionA < jurisdictionB) {
    comparison = -1;
  }
  return comparison;
};

export {
  compareJurisdictionObjectEntries,
  compareJurisdictionArrayElements
};
