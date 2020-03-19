import React from 'react';
import { Card, Table } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class RiskStratification extends React.Component {
  constructor(props) {
    super(props);
    console.log(JSON.parse(JSON.stringify(props)));
    let pr; // = props.stats.current_reporting_summary.monitoring_status_by_risk_level; // pr stands for propsReference
    // This pr is the correct format as the endpoint will return. Just using fake data for now, because the endpoint isn't working
    pr = {
      symptomatic: { high: 15, med: 2, low: 3, none: 4, missing: 1, total: 76 },
      non_reporting: { high: 1, med: 1, low: 6, none: 8, missing: 0, total: 24 },
      asymptomatic: { high: 3, med: 5, low: 3, none: 75, missing: 0, total: 189 },
    };
    let totalCount = {
      high: pr.symptomatic.high + pr.non_reporting.high + pr.asymptomatic.high,
      med: pr.symptomatic.med + pr.non_reporting.med + pr.asymptomatic.med,
      low: pr.symptomatic.low + pr.non_reporting.low + pr.asymptomatic.low,
      none: pr.symptomatic.none + pr.non_reporting.none + pr.asymptomatic.none,
      missing: pr.symptomatic.missing + pr.non_reporting.missing + pr.asymptomatic.missing,
    };

    totalCount['total'] = totalCount['high'] + totalCount['med'] + totalCount['low'] + totalCount['none'] + totalCount['missing'];

    let data = {
      high: {
        symptomatic_n: pr.symptomatic.high,
        symptomatic_p: totalCount.high === 0 ? null : ((pr.symptomatic.high * 100) / totalCount.high).toFixed(0),
        non_reporting_n: pr.non_reporting.high,
        non_reporting_p: totalCount.high === 0 ? null : ((pr.non_reporting.high * 100) / totalCount.high).toFixed(0),
        asymptomatic_n: pr.asymptomatic.high,
        asymptomatic_p: totalCount.high === 0 ? null : ((pr.asymptomatic.high * 100) / totalCount.high).toFixed(0),
      },
      med: {
        symptomatic_n: pr.symptomatic.med,
        symptomatic_p: totalCount.med === 0 ? null : ((pr.symptomatic.med * 100) / totalCount.med).toFixed(0),
        non_reporting_n: pr.non_reporting.med,
        non_reporting_p: totalCount.med === 0 ? null : ((pr.non_reporting.med * 100) / totalCount.med).toFixed(0),
        asymptomatic_n: pr.asymptomatic.med,
        asymptomatic_p: totalCount.med === 0 ? null : ((pr.asymptomatic.med * 100) / totalCount.med).toFixed(0),
      },
      low: {
        symptomatic_n: pr.symptomatic.low,
        symptomatic_p: totalCount.low === 0 ? null : ((pr.symptomatic.low * 100) / totalCount.low).toFixed(0),
        non_reporting_n: pr.non_reporting.low,
        non_reporting_p: totalCount.low === 0 ? null : ((pr.non_reporting.low * 100) / totalCount.low).toFixed(0),
        asymptomatic_n: pr.asymptomatic.low,
        asymptomatic_p: totalCount.low === 0 ? null : ((pr.asymptomatic.low * 100) / totalCount.low).toFixed(0),
      },
      none: {
        symptomatic_n: pr.symptomatic.none,
        symptomatic_p: totalCount.none === 0 ? null : ((pr.symptomatic.none * 100) / totalCount.none).toFixed(0),
        non_reporting_n: pr.non_reporting.none,
        non_reporting_p: totalCount.none === 0 ? null : ((pr.non_reporting.none * 100) / totalCount.none).toFixed(0),
        asymptomatic_n: pr.asymptomatic.none,
        asymptomatic_p: totalCount.none === 0 ? null : ((pr.asymptomatic.none * 100) / totalCount.none).toFixed(0),
      },
      missing: {
        symptomatic_n: pr.symptomatic.missing,
        symptomatic_p: totalCount.missing === 0 ? null : ((pr.symptomatic.missing * 100) / totalCount.missing).toFixed(0),
        non_reporting_n: pr.non_reporting.missing,
        non_reporting_p: totalCount.missing === 0 ? null : ((pr.non_reporting.missing * 100) / totalCount.missing).toFixed(0),
        asymptomatic_n: pr.asymptomatic.missing,
        asymptomatic_p: totalCount.missing === 0 ? null : ((pr.asymptomatic.missing * 100) / totalCount.missing).toFixed(0),
      },
      total: {
        symptomatic_n: pr.symptomatic.high + pr.symptomatic.med + pr.symptomatic.low + pr.symptomatic.none + pr.symptomatic.missing,
        symptomatic_p:
          totalCount.total === 0
            ? null
            : (pr.symptomatic.high + pr.symptomatic.med + pr.symptomatic.low + pr.symptomatic.none + (pr.symptomatic.missing * 100) / totalCount.total).toFixed(
                0
              ),
        non_reporting_n: pr.non_reporting.high + pr.non_reporting.med + pr.non_reporting.low + pr.non_reporting.none + pr.non_reporting.missing,
        non_reporting_p:
          totalCount.total === 0
            ? null
            : (
                pr.non_reporting.high +
                pr.non_reporting.med +
                pr.non_reporting.low +
                pr.non_reporting.none +
                (pr.non_reporting.missing * 100) / totalCount.total
              ).toFixed(0),
        asymptomatic_n: pr.asymptomatic.high + pr.asymptomatic.med + pr.asymptomatic.low + pr.asymptomatic.none + pr.asymptomatic.missing,
        asymptomatic_p:
          totalCount.total === 0
            ? null
            : (
                pr.asymptomatic.high +
                pr.asymptomatic.med +
                pr.asymptomatic.low +
                pr.asymptomatic.none +
                (pr.asymptomatic.missing * 100) / totalCount.total
              ).toFixed(0),
      },
    };
    this.data = data;
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
                  <th>
                    <div> High Risk </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                  <th>
                    <div> Medium Risk </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                  <th>
                    <div> Low Risk </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                  <th>
                    <div> No Identifiable Risk </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                  <th>
                    <div> Missing </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                  <th>
                    <div> Total </div>
                    <div className="text-secondary"> n (col %) </div>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr style={{ backgroundColor: '#FA897B' }}>
                  <td className="font-weight-bold">Symptomatic</td>
                  <td>
                    {this.data.high.symptomatic_n} ({this.data.high.symptomatic_p}%)
                  </td>
                  <td>
                    {this.data.med.symptomatic_n} ({this.data.med.symptomatic_p}%)
                  </td>
                  <td>
                    {this.data.low.symptomatic_n} ({this.data.low.symptomatic_p}%)
                  </td>
                  <td>
                    {this.data.none.symptomatic_n} ({this.data.none.symptomatic_p}%)
                  </td>
                  <td>
                    {this.data.missing.symptomatic_n} ({this.data.missing.symptomatic_p}%)
                  </td>
                  <td>
                    {this.data.total.symptomatic_n} ({this.data.total.symptomatic_p}%)
                  </td>
                </tr>
                <tr style={{ backgroundColor: '#FFDD94' }}>
                  <td className="font-weight-bold">Non-Reporting</td>
                  <td>
                    {this.data.high.non_reporting_n} ({this.data.high.non_reporting_p}%)
                  </td>
                  <td>
                    {this.data.med.non_reporting_n} ({this.data.med.non_reporting_p}%)
                  </td>
                  <td>
                    {this.data.low.non_reporting_n} ({this.data.low.non_reporting_p}%)
                  </td>
                  <td>
                    {this.data.none.non_reporting_n} ({this.data.none.non_reporting_p}%)
                  </td>
                  <td>
                    {this.data.missing.non_reporting_n} ({this.data.missing.non_reporting_p}%)
                  </td>
                  <td>
                    {this.data.total.non_reporting_n} ({this.data.total.non_reporting_p}%)
                  </td>
                </tr>
                <tr style={{ backgroundColor: '#D0E6A5' }}>
                  <td className="font-weight-bold">Asymptomatic</td>
                  <td>
                    {this.data.high.asymptomatic_n} ({this.data.high.asymptomatic_p}%)
                  </td>
                  <td>
                    {this.data.med.asymptomatic_n} ({this.data.med.asymptomatic_p}%)
                  </td>
                  <td>
                    {this.data.low.asymptomatic_n} ({this.data.low.asymptomatic_p}%)
                  </td>
                  <td>
                    {this.data.none.asymptomatic_n} ({this.data.none.asymptomatic_p}%)
                  </td>
                  <td>
                    {this.data.missing.asymptomatic_n} ({this.data.missing.asymptomatic_p}%)
                  </td>
                  <td>
                    {this.data.total.asymptomatic_n} ({this.data.total.asymptomatic_p}%)
                  </td>
                </tr>
                <tr>
                  <td className="font-weight-bold">Total</td>
                  <td>{this.totalCount.high}</td>
                  <td>{this.totalCount.med}</td>
                  <td>{this.totalCount.low}</td>
                  <td>{this.totalCount.none}</td>
                  <td>{this.totalCount.missing}</td>
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
