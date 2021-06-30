import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';
import { Card } from 'react-bootstrap';
import { formatPercentage } from '../../../../utils/Analytics';

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
    class: 'row-danger',
  },
  {
    linelist: 'Non-Reporting',
    class: 'row-caution',
  },
  {
    linelist: 'Asymptomatic',
    class: 'row-success',
  },
  {
    linelist: 'PUI',
    class: 'row-secondary',
  },
  {
    linelist: 'Requiring Review',
    linelistRewording: 'Records Requiring Review',
    class: 'row-danger',
  },
  {
    linelist: 'Reporting',
    class: 'row-success',
  },
];

class PreferredReportingMethod extends React.Component {
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
                percentageOfTotal: formatPercentage(value, cumulativeSum),
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
        const percentageOfTotal = value ? ((value / cumuluativeSum) * 100).toFixed(1) : value;
        linelist.contactMethodData.push({ contactMethod: 'Total', value, percentageOfTotal: percentageOfTotal ? percentageOfTotal + '%' : 'None' });
      });
      return workflowData;
    });
    this.reportingData = {};
  }

  render() {
    return (
      <Card>
        <Card.Header as="h4" className="text-center">
          Monitorees by Reporting Method (Active Records Only)
        </Card.Header>
        <Card.Body>
          <table className="analytics-table reporting-method">
            <thead>
              <tr className="g-border-bottom text-center header">
                <th></th>
                <th></th>
                {CONTACT_METHOD_HEADERS.map((header, h_index) => (
                  <th key={h_index}>{header}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {this.tableData.map((table, t_index) => (
                <React.Fragment key={t_index}>
                  <tr>
                    <td className="header py-2" colSpan="9">
                      {_.capitalize(table.workflow)} Workflow
                    </td>
                    <td></td>
                  </tr>
                  {table.data.map((row, r_index) => (
                    <tr key={r_index} className={`${row.linelistClass || 'row-total g-border-bottom'}`}>
                      <td className="placeholder-cell" style={{ width: '40px' }}></td>
                      <td className="sub-header">{row.linelist}</td>
                      {row.contactMethodData.map((data, d_index) => (
                        <td key={d_index}>
                          <div className="count-percent-container">
                            <span className="number">{data.value}</span>
                            <span className="percentage align-bottom">{row.linelist === 'Total' ? '' : `(${data.percentageOfTotal})`}</span>
                          </div>
                        </td>
                      ))}
                    </tr>
                  ))}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </Card.Body>
      </Card>
    );
  }
}

PreferredReportingMethod.propTypes = {
  stats: PropTypes.object,
};

export default PreferredReportingMethod;
