import _ from 'lodash';

const WORKFLOWS = ['Exposure', 'Isolation'];

/**
  * This function is specific to the PublicHealthAnalytics
  * It makes many assumptions about the format of the incoming monitoree counts.
  * It parses out the correct fields from MonitoreeCounts and formats it in a consistent way that the Analytics
  * components use for displaying in a table
  * @param {Object} monitoreeCounts - The full list of MonitoreeCounts
  * @param {Array} masterList - An array of the values the Analytics Commponents will display in the table
  * @param {String} categoryTypeName - The value of `category` that should be parsed out of MonitoreeCounts
  * @param {Array of Strings} workflows - An Array of Strings of Workflow Values (defaults to the constant above)
*/
function parseOutFields (monitoreeCounts, masterList, categoryTypeName, workflows = WORKFLOWS) {
  return masterList
    .map(ml =>
      workflows.map(
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
  * @param {Array of Strings} workflows - An Array of Strings of Workflow Values (defaults to the constant above)
*/
function mapToChartFormat (masterList, values, workflows = WORKFLOWS) {
  return masterList.map((ml, index0) => {
    let retVal = {};
    retVal['name'] = ml;
    workflows.map((workflow, index1) => {
      retVal[`${workflow}`] = values[Number(index0)][Number(index1)];
    });
    return retVal;
  });
}

/**
 * Create a percentage string given a numerator and a denomenator
 * @param {Number} count The numerator
 * @param {Number} total The denomenator
 * @returns A string representing the percentage to one decimal point, or 'None' if the numerator is 0
 */
function formatPercentage(count, total) {
  return count ? ((count / total) * 100).toFixed(1).toString() + '%' : 'None';
}

export { parseOutFields, mapToChartFormat, formatPercentage };
