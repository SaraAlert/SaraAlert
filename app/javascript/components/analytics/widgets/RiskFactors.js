import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import _ from 'lodash';

const WORKFLOWS = ['Exposure', 'Isolation'];
const RISKFACTORS = [
  'Close Contact with Known Case',
  'Travel from Affected Country or Area',
  'Was in Healthcare Facility with Known Cases',
  'Healthcare Personnel',
  'Common Exposure Cohort',
  'Crew on Passenger or Cargo Flight',
  'Laboratory Personnel',
];
const NUM_COUNTRIES_TO_SHOW = 5;

class RiskFactors extends React.Component {
  constructor(props) {
    super(props);

    let topTenCountries = _.uniq(props.stats.monitoree_counts.filter(x => x.category_type === 'Exposure Country').map(x => x.category)).map(country => {
      return {
        country,
        total: _.sum(props.stats.monitoree_counts.filter(x => x.category_type === 'Exposure Country' && x.category === country).map(x => x.total)),
      };
    });
    this.COUNTRY_HEADERS = topTenCountries
      .sort((a, b) => b.total - a.total)
      .map(x => x.country)
      .slice(0, NUM_COUNTRIES_TO_SHOW);

    this.rfData = this.parseOutFields(RISKFACTORS, 'Risk Factor');
    this.countryData = this.parseOutFields(this.COUNTRY_HEADERS, 'Exposure Country');
  }

  parseOutFields = (masterList, categoryTypeName) =>
    masterList
      .map(ml =>
        WORKFLOWS.map(
          wf => this.props.stats.monitoree_counts.find(x => x.status === wf && x.category_type === categoryTypeName && x.category === ml)?.total || 0
        )
      )
      .map(x => x.concat(_.sum(x)));

  renderBarGraph() {
    return (
      <div className="mx-3 mt-2">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={{}}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 5,
            }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="High" stackId="a" fill="#FA897B" />
            <Bar dataKey="Medium" stackId="a" fill="#FFDD94" />
            <Bar dataKey="Low" stackId="a" fill="#D0E6A5" />
            <Bar dataKey="No Identified Risk" stackId="a" fill="#333" />
            <Bar dataKey="Missing" stackId="a" fill="#BABEC4" />
          </BarChart>
        </ResponsiveContainer>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.sexData}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 5,
            }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="High" stackId="a" fill="#FA897B" />
            <Bar dataKey="Medium" stackId="a" fill="#FFDD94" />
            <Bar dataKey="Low" stackId="a" fill="#D0E6A5" />
            <Bar dataKey="No Identified Risk" stackId="a" fill="#333" />
            <Bar dataKey="Missing" stackId="a" fill="#BABEC4" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5"> Demographics ​</div>
          <Card.Body className="mt-5">
            <h4 className="text-left"> Risk Factors </h4>
            <table className="analytics-table">
              <thead>
                <tr>
                  <th className="py-0"></th>
                  {WORKFLOWS.map((header, index) => (
                    <th key={index} className="font-weight-bold">
                      {' '}
                      <u>{_.upperCase(header)}</u>{' '}
                    </th>
                  ))}
                  <th>Total</th>
                </tr>
              </thead>
              {RISKFACTORS.map((val, index1) => (
                <tbody key={`workflow-table-${index1}`}>
                  <tr className={index1 % 2 ? '' : 'analytics-zebra-bg'}>
                    <td className="font-weight-bold"> {val} </td>
                    {this.rfData[Number(index1)].map((data, subIndex1) => (
                      <td key={subIndex1}> {data} </td>
                    ))}
                  </tr>
                </tbody>
              ))}
            </table>
            <h4 className="text-left mt-3"> Country of Exposure </h4>
            <table className="analytics-table">
              <thead>
                <tr>
                  <th className="py-0"></th>
                  {WORKFLOWS.map((header, index) => (
                    <th key={index} className="font-weight-bold">
                      {' '}
                      <u>{_.upperCase(header)}</u>{' '}
                    </th>
                  ))}
                  <th>Total</th>
                </tr>
              </thead>
              {this.COUNTRY_HEADERS.map((val, index2) => (
                <tbody key={`workflow-table-${index2}`}>
                  <tr className={index2 % 2 ? '' : 'analytics-zebra-bg'}>
                    <td className="font-weight-bold"> {val} </td>
                    {this.countryData[Number(index2)].map((data, subIndex2) => (
                      <td key={subIndex2}> {data} </td>
                    ))}
                  </tr>
                </tbody>
              ))}
            </table>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

RiskFactors.propTypes = {
  stats: PropTypes.object,
};

export default RiskFactors;
