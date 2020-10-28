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
    console.log(props);
    console.log(props.stats.monitoree_counts.find(x => x.category_type === 'Preferred Contact Method'));
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
              <tbody>
                <tr style={{ height: '0px' }}></tr>
                <tr>
                  <td className="font-weight-bold text-left">
                    <u>EXPOSURE WORKFLOW</u>{' '}
                  </td>
                </tr>
                <tr className="analytics-zebra-bg">
                  <td className="text-right font-weight-bold">Symptomatic</td>
                  <td>Mark</td>
                  <td>Otto</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                </tr>
                <tr>
                  <td className="text-right font-weight-bold">Asymptomatic</td>
                  <td>Jacob</td>
                  <td>Thornton</td>
                  <td>tesst</td>
                  <td>tesst</td>
                  <td>tesst</td>
                  <td>tesst</td>
                  <td>tesst</td>
                </tr>
                <tr className="analytics-zebra-bg">
                  <td className="text-right font-weight-bold">Non-Reporting</td>
                  <td>Larry</td>
                  <td>Bob</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                </tr>
                <tr>
                  <td className="text-right font-weight-bold border-none">Total</td>
                  <td>Larry</td>
                  <td>Bob</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                </tr>
                <tr style={{ height: '0px' }}></tr>
                <tr>
                  <td className="font-weight-bold text-left">
                    <u>ISOLATION WORKFLOW</u>{' '}
                  </td>
                </tr>
                <tr className="analytics-zebra-bg">
                  <td className="text-right font-weight-bold">Symptomatic</td>
                  <td>Mark</td>
                  <td>Otto</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                </tr>
                <tr>
                  <td className="text-right font-weight-bold">Asymptomatic</td>
                  <td>Jacob</td>
                  <td>Thornton</td>
                  <td>tesst</td>
                  <td>tesst</td>
                  <td>tesst</td>
                  <td>tesst</td>
                  <td>tesst</td>
                </tr>
                <tr className="analytics-zebra-bg">
                  <td className="text-right font-weight-bold">Non-Reporting</td>
                  <td>Larry</td>
                  <td>Bob</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                </tr>
                <tr>
                  <td className="text-right font-weight-bold">Total</td>
                  <td>Larry</td>
                  <td>Bob</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                  <td>test</td>
                </tr>
              </tbody>
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
