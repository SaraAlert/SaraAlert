import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';
import { Card, Table } from 'react-bootstrap';

const SYMPTOMLEVELS = ['Symptomatic', 'Non-Reporting', 'Asymptomatic'];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

const workflows = ['Exposure', 'Isolation'];
const reportingMethods = ['email', ''];

class RiskStratification extends React.Component {
  constructor(props) {
    super(props);
    let contactMethodMonitoreeCounts = props.stats.monitoree_counts.filter(x => x.category_type === 'Contact Method');
    const linelistOptions = _.uniq(props.stats.monitoree_counts.filter(x => x.category_type === 'Contact Method').map(x => x.status));
    this.tableData = WORKFLOWS.map(workflow => {
      const thisWorkflowMC = contactMethodMonitoreeCounts.filter(x => x.status.includes(workflow));
      let workflowData = {};
      workflowData['workflow'] = _.upperCase(workflow);
      workflowData['data'] = linelistOptions
        .filter(option => option.includes(workflow))
        .map(linelistOption => {
          const linelistOptions = LINELIST_STYLE_OPTIONS.find(x => x.linelist === _.join(_.tail(linelistOption.split(' ')), ' '));
          return {
            linelist: linelistOptions['linelistRewording'] || linelistOptions['linelist'], // Some Linelists need to slightly re-worded
            linelistColor: linelistOptions.color,
            contactMethodData: _.initial(CONTACT_METHOD_HEADERS).map(contactMethod => {
              const thisContactMethodData = thisWorkflowMC.filter(x => x.category === _.findKey(CONTACT_METHOD_MAPPINGS, x => x === contactMethod));
              const value = thisContactMethodData.find(x => x.status.includes(linelistOption))?.total || 0;
              const cumulativeSum = _.sum(thisContactMethodData.map(x => x.total));
              return {
                contactMethod,
                value,
                percentageOfTotal: value ? ((value / cumulativeSum) * 100).toFixed(1).toString() + '%' : 'None',
              };
            }),
          };
        });
      workflowData['data'].push({
        linelist: 'Total',
        contactMethodData: _.initial(CONTACT_METHOD_HEADERS).map(contactMethod => {
          const thisContactMethodData = thisWorkflowMC.filter(x => x.category === _.findKey(CONTACT_METHOD_MAPPINGS, x => x === contactMethod));
          const value = _.sum(thisContactMethodData.map(x => x.total));
          return {
            contactMethod,
            value,
          };
        }),
      });
      workflowData['data'].forEach(linelist => {
        const value = _.sum(linelist.contactMethodData.map(x => x.value));
        const cumuluativeSum = _.sum(workflowData['data'].find(x => x.linelist === 'Total').contactMethodData.map(x => x.value));
        const percentageOfTotal = ((value / cumuluativeSum) * 100).toFixed(1);
        linelist.contactMethodData.push({ contactMethod: 'Total', value, percentageOfTotal });
      });
      return workflowData;
    });
    this.reportingData = {};
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5">Actively Monitored Individuals by Reporting Method (as of X) ​</div>
          <Card.Body className="mt-4">
            <table className="analytics-table">
              <thead>
                <tr>
                  <th></th>
                  <th>Email</th>
                  <th>SMS Weblink</th>
                  <th>SMS Text</th>
                  <th>Phone Call</th>
                  <th>Opt-Out</th>
                  <th>Unknown</th>
                  <th>Total</th>
                </tr>
              </thead>
              {this.tableData.map((workflow, index1) => (
                <tbody key={`workflow-table-${index1}`}>
                  <tr style={{ height: '0px' }}></tr>
                  <tr>
                    <td className="font-weight-bold text-left">
                      <u>{workflow['workflow']} WORKFLOW</u>{' '}
                    </td>
                  </tr>
                  {workflow.data.map((data, index2) => (
                    <tr key={`data-${index2}`} style={{ backgroundColor: data.linelistColor }}>
                      <td className="text-right font-weight-bold">{data.linelist}</td>
                      {data.contactMethodData.map((value, index3) => (
                        <td key={`value-${index3}`}>
                          {value.value}
                          {index2 < workflow.data.length - 1 && (
                            // Don't show the percentages for the Total
                            <span className="analytics-percentage"> {`(${value.percentageOfTotal})`} </span>
                          )}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              ))}
            </table>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

RiskStratification.propTypes = {
  stats: PropTypes.object,
};

export default RiskStratification;
