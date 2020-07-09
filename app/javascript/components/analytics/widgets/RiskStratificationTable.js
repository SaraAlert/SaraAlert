import React from 'react';
import _ from 'lodash';
import { Card, Table } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

const SYMPTOMLEVELS = ['Symptomatic', 'Non-Reporting', 'Asymptomatic'];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

class RiskStratification extends React.Component {
  constructor(props) {
    super(props);
    this.getTotals = this.getTotals.bind(this);
    let totalCount = this.getTotals();

    let data = {};
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring);
    let x = activeMonitorees.filter(x => x.category_type === 'Monitoring Status');
    SYMPTOMLEVELS.forEach(symptomlevel => {
      data[String(symptomlevel)] = {};
      x.filter(y => y.category === symptomlevel).forEach(z => {
        data[String(symptomlevel)][z.risk_level] = z.total;
      });
    });

    let tableData = {};
    // We want to know the value (n) and it's percentage (p) for each risklevel for each symptom
    // so we create two values: the symptom_n value and the symptom_p value
    SYMPTOMLEVELS.forEach(symptomlevel => {
      tableData[String(symptomlevel)] = { total_n: 0 };
      RISKLEVELS.forEach(risklevel => {
        tableData[String(symptomlevel)][`${risklevel}_n`] = data[String(symptomlevel)][String(risklevel)]
          ? data[String(symptomlevel)][String(risklevel)]
          : 'None';
        tableData[String(symptomlevel)][`total_n`] += _.isFinite(data[String(symptomlevel)][String(risklevel)])
          ? data[String(symptomlevel)][String(risklevel)]
          : 0;
      });
    });
    SYMPTOMLEVELS.forEach(symptomlevel => {
      tableData[String(symptomlevel)][`total_p`] = ((tableData[String(symptomlevel)][`total_n`] * 100) / totalCount.total).toFixed(0);
      RISKLEVELS.forEach(risklevel => {
        tableData[String(symptomlevel)][`${risklevel}_p`] =
          tableData[String(symptomlevel)][`${risklevel}_n`] !== 'None'
            ? ((data[String(symptomlevel)][String(risklevel)] * 100) / totalCount[String(risklevel)]).toFixed(0)
            : 0;
      });
    });

    this.tableData = tableData;
    this.totalCount = totalCount;
  }

  getTotals = () => {
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring);
    let categoryGroups = activeMonitorees.filter(x => x.category_type === 'Overall Total');
    let retVal = {};
    RISKLEVELS.forEach(val => {
      let thisGroup = categoryGroups.filter(group => group.risk_level === val);
      retVal[String(val)] = _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
    });
    retVal['total'] = _.sum(_.valuesIn(retVal));
    return retVal;
  };

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
                      {this.tableData['Symptomatic'][`${String(risklevel)}_n`]} ({this.tableData['Symptomatic'][`${String(risklevel)}_p`]}%)
                    </td>
                  ))}
                  <td>
                    {this.tableData['Symptomatic']['total_n']} ({this.tableData['Symptomatic']['total_p']}%)
                  </td>
                </tr>
                <tr style={{ backgroundColor: '#D0E6A5' }}>
                  <td className="font-weight-bold">Asymptomatic</td>
                  {RISKLEVELS.map(risklevel => (
                    <td key={risklevel.toString()}>
                      {this.tableData['Asymptomatic'][`${String(risklevel)}_n`]} ({this.tableData['Asymptomatic'][`${String(risklevel)}_p`]}%)
                    </td>
                  ))}
                  <td>
                    {this.tableData['Asymptomatic']['total_n']} ({this.tableData['Asymptomatic']['total_p']}%)
                  </td>
                </tr>
                <tr style={{ backgroundColor: '#FFDD94' }}>
                  <td className="font-weight-bold">Non-Reporting</td>
                  {RISKLEVELS.map(risklevel => (
                    <td key={risklevel.toString()}>
                      {this.tableData['Non-Reporting'][`${String(risklevel)}_n`]} ({this.tableData['Non-Reporting'][`${String(risklevel)}_p`]}%)
                    </td>
                  ))}
                  <td>
                    {this.tableData['Non-Reporting']['total_n']} ({this.tableData['Non-Reporting']['total_p']}%)
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
