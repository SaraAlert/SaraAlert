import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';
import { Card } from 'react-bootstrap';

const WORKFLOWS = ['Exposure', 'Isolation'];

// Provide a separate array, as object-iteration order is not guaranteed in JS
const CONTACT_METHOD_HEADERS = ['Email', 'SMS Weblink', 'SMS Text', 'Phone Call', 'Opt-Out', 'Unknown', 'Missing', 'Total'];

// Maps the difference between what we have server-side and what we want to display to the client
const CONTACT_METHOD_MAPPINGS = {
  'E-mailed Web Link': 'Email',
  'SMS Texted Weblink': 'SMS Weblink',
  'SMS Text-message': 'SMS Text',
  'Telephone call': 'Phone Call',
  'Opt-out': 'Opt-Out',
  Unknown: 'Unknown',
  Missing: 'Missing',
};

// The goal was to have as few hard-coded options as possisble.
// Feedback was provided to tweak certain things (colors, wording) so this becomes a necessity
const LINELIST_STYLE_OPTIONS = [
  {
    linelist: 'Symptomatic',
    class: 'analytics-table-danger',
  },
  {
    linelist: 'Non-Reporting',
    class: 'analytics-table-caution',
  },
  {
    linelist: 'Asymptomatic',
    class: 'analytics-table-success',
  },
  {
    linelist: 'PUI',
    class: 'analytics-table-secondary',
  },
  {
    linelist: 'Requiring Review',
    linelistRewording: 'Records Requiring Review',
    class: 'analytics-table-danger',
  },
  {
    linelist: 'Reporting',
    class: 'analytics-table-success',
  },
];

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
            linelistClass: linelistOptions.class,
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
        linelist.contactMethodData.push({ contactMethod: 'Total', value, percentageOfTotal: percentageOfTotal ? percentageOfTotal + '%' : 'None' });
      });
      return workflowData;
    });
    this.reportingData = {};
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5">Monitorees by Reporting Method (Active Records Only)</div>
          <Card.Body className="mt-4">
            <table className="analytics-table">
              <thead>
                <tr>
                  <th></th>
                  {CONTACT_METHOD_HEADERS.map((contactMethodHeaders, index) => (
                    <th key={index}>
                      <div> {contactMethodHeaders} </div>
                      <div className="text-secondary"> n (col %) </div>
                    </th>
                  ))}
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
                    <tr key={`data-${index2}`} className={data.linelistClass}>
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
