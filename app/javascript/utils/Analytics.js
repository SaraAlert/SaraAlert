import _ from 'lodash';

const WORKFLOWS = ['Exposure', 'Isolation']

/**
  * This function is specific to the PublicHealthAnalytics
  * It makes many assumptions about the format of the incoming monitoree counts.
  * It parses out the correct fields from MonitoreeCounts and formats it in a consistent way that the Analytics
  * components use for displaying in a table
  * @param {Object} monitoreeCounts - The full list of MonitoreeCounts
  * @param {Array} masterList - An array of the values the Analytics Commponents will display in the table
  * @param {String} categoryTypeName - The value of `category` that should be parsed out of MonitoreeCounts
*/
function parseOutFields (monitoreeCounts, masterList, categoryTypeName) {
  return masterList
    .map(ml =>
      WORKFLOWS.map(
        wf => monitoreeCounts.find(x => x.status === wf && x.category_type === categoryTypeName && x.category === ml)?.total || 0
      )
    )
    .map(x => x.concat(_.sum(x)));
}

/**
  * This function is specific to the PublicHealthAnalytics
  * It formats the data (the output of `parseOutFields` in a manner that ReactCharts can use)
  * @param {Array} masterList - An array of the values the Analytics Commponents will display in the graph
  * @param {Object} values - An object containing the resultant output of the `parseOutFields` function to be mapped
*/
function mapToChartFormat (masterList, values) {
  return masterList.map((ml, index0) => {
    let retVal = {};
    retVal['name'] = ml;
    WORKFLOWS.map((workflow, index1) => {
      retVal[`${workflow}`] = values[Number(index0)][Number(index1)];
    });
    return retVal;
  });
}

export {
  parseOutFields,
  mapToChartFormat
};
