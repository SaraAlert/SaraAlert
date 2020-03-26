import React from 'react';
import { Card, Table } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

const SYMPTOMLEVELS = ['Symptomatic', 'Non-Reporting', 'Asymptomatic'];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

class RiskStratification extends React.Component {
  constructor(props) {
    super(props);
    let data = {};
    let totalCount = { total: 0 };
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring);
    let x = activeMonitorees.filter(x => x.category_type === 'Monitoring Status');
    SYMPTOMLEVELS.forEach(symptomlevel => {
      data[symptomlevel] = {};
      x.filter(y => y.category === symptomlevel).forEach(z => {
        data[symptomlevel][z.risk_level] = z.total;
      });
    });
    RISKLEVELS.forEach(risklevel => {
      totalCount[risklevel] = 0;
      SYMPTOMLEVELS.forEach(symptomlevel => {
        totalCount.total += data[symptomlevel][risklevel];
        totalCount[risklevel] += data[symptomlevel][risklevel];
      });
    });
    let tableData = {};
    // We want to know the value (n) and it's percentage for each risklevel for each symptom
    // so we create two values the symptom_n value and the symptom_p value
    RISKLEVELS.forEach(risklevel => {
      tableData[risklevel] = {};
      SYMPTOMLEVELS.forEach(symptomlevel => {
        tableData[risklevel][`${symptomlevel}_n`] = data[symptomlevel][risklevel];
        tableData[risklevel][`${symptomlevel}_p`] =
          totalCount[risklevel] === 0 ? 0 : ((data[symptomlevel][risklevel] * 100) / totalCount[risklevel]).toFixed(0);
      });
    });

    tableData['total'] = {
      Symptomatic_n:
        data['Symptomatic']['High'] +
        data['Symptomatic']['Medium'] +
        data['Symptomatic']['Low'] +
        data['Symptomatic']['No Identified Risk'] +
        data['Symptomatic']['Missing'],
      Symptomatic_p:
        totalCount.total === 0
          ? null
          : (
              (parseFloat(
                data['Symptomatic']['High'] +
                  data['Symptomatic']['Medium'] +
                  data['Symptomatic']['Low'] +
                  data['Symptomatic']['No Identified Risk'] +
                  data['Symptomatic']['Missing']
              ) *
                100) /
              totalCount.total
            ).toFixed(0),
      'Non-Reporting_n':
        data['Non-Reporting']['High'] +
        data['Non-Reporting']['Medium'] +
        data['Non-Reporting']['Low'] +
        data['Non-Reporting']['No Identified Risk'] +
        data['Non-Reporting']['Missing'],
      'Non-Reporting_p':
        totalCount.total === 0
          ? null
          : (
              (parseFloat(
                data['Non-Reporting']['High'] +
                  data['Non-Reporting']['Medium'] +
                  data['Non-Reporting']['Low'] +
                  data['Non-Reporting']['No Identified Risk'] +
                  data['Non-Reporting']['Missing']
              ) *
                100) /
              totalCount.total
            ).toFixed(0),
      Asymptomatic_n:
        data['Asymptomatic']['High'] +
        data['Asymptomatic']['Medium'] +
        data['Asymptomatic']['Low'] +
        data['Asymptomatic']['No Identified Risk'] +
        data['Asymptomatic']['Missing'],
      Asymptomatic_p:
        totalCount.total === 0
          ? null
          : (
              (parseFloat(
                data['Asymptomatic']['High'] +
                  data['Asymptomatic']['Medium'] +
                  data['Asymptomatic']['Low'] +
                  data['Asymptomatic']['No Identified Risk'] +
                  data['Asymptomatic']['Missing']
              ) *
                100) /
              totalCount.total
            ).toFixed(0),
    };
    this.data = data;
    this.tableData = tableData;
    this.totalCount = totalCount;
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header as="h5" className="text-left">
            Monitoring Status by Risk Level Amongst Those Currently Under Active Monitoring
          </Card.Header>
          <Card.Body>
            <Table striped borderless hover>
              <thead>
                <tr>
                  <th></th>
                  {RISKLEVELS.map(risklevel => (
                    <th key={risklevel.toString()}>
                      <div> {risklevel} </div>
                      <div className="text-secondary"> n (col %) </div>
                    </th>
                  ))}
                  <th>
                    <div> Total </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr style={{ backgroundColor: '#FA897B' }}>
                  <td className="font-weight-bold">Symptomatic</td>
                  {RISKLEVELS.map(risklevel => (
                    <td key={risklevel.toString()}>
                      {this.tableData[risklevel]['Symptomatic_n']} ({this.tableData[risklevel]['Symptomatic_p']}%)
                    </td>
                  ))}
                  <td>
                    {this.tableData['total']['Symptomatic_n']} ({this.tableData['total']['Symptomatic_p']}%)
                  </td>
                </tr>
                <tr style={{ backgroundColor: '#FFDD94' }}>
                  <td className="font-weight-bold">Asymptomatic</td>
                  {RISKLEVELS.map(risklevel => (
                    <td key={risklevel.toString()}>
                      {this.tableData[risklevel]['Asymptomatic_n']} ({this.tableData[risklevel]['Asymptomatic_p']}%)
                    </td>
                  ))}
                  <td>
                    {this.tableData['total']['Asymptomatic_n']} ({this.tableData['total']['Asymptomatic_p']}%)
                  </td>
                </tr>
                <tr style={{ backgroundColor: '#D0E6A5' }}>
                  <td className="font-weight-bold">Non-Reporting</td>
                  {RISKLEVELS.map(risklevel => (
                    <td key={risklevel.toString()}>
                      {this.tableData[risklevel]['Non-Reporting_n']} ({this.tableData[risklevel]['Non-Reporting_p']}%)
                    </td>
                  ))}
                  <td>
                    {this.tableData['total']['Non-Reporting_n']} ({this.tableData['total']['Non-Reporting_p']}%)
                  </td>
                </tr>
                <tr>
                  <td className="font-weight-bold">Total</td>
                  <td>{this.totalCount['High']}</td>
                  <td>{this.totalCount['Medium']}</td>
                  <td>{this.totalCount['Low']}</td>
                  <td>{this.totalCount['No Identified Risk']}</td>
                  <td>{this.totalCount['Missing']}</td>
                  <td>{this.totalCount.total}</td>
                </tr>
              </tbody>
            </Table>
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
