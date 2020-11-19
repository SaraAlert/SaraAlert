import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import _ from 'lodash';

const WORKFLOWS = ['Exposure', 'Isolation'];
const AGEGROUPS = ['0-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '>=80', 'FAKE_BIRTHDATE'];
const SEXES = ['Male', 'Female', 'Unknown'];
const ETHNICITIES = ['Hispanic or Latino', 'Not Hispanic or Latino'];
const RACES = [
  'White',
  'Black or African American',
  'Asian',
  'American Indian or Alaska Native',
  'Native Hawaiian or Other Pacific Islander',
  'More Than One Race',
  'Unknown',
];
const SEXUAL_ORIENTATIONS = ['Straight or Heterosexual', 'Lesbian, Gay, or Homosexual', 'Bisexual', 'Another', 'Choose not to disclose', 'Don’t know'];

class Demographics extends React.Component {
  constructor(props) {
    super(props);
    this.ageData = this.parseOutFields(AGEGROUPS, 'Age Group');
    this.sexData = this.parseOutFields(SEXES, 'Sex');
    this.ethnicityData = this.parseOutFields(ETHNICITIES, 'Ethnicity');
    this.raceData = this.parseOutFields(RACES, 'Race');
    this.soData = this.parseOutFields(SEXUAL_ORIENTATIONS, 'Sexual Orientation');
    this.hasFakeBirthdateData = false;
    this.numberOfFakeBirthdates = 0;

    if (_.last(_.last(this.ageData)) !== 0) {
      // Meaning we have monitorees with fake birthdates
      this.hasFakeBirthdateData = true;
      this.numberOfFakeBirthdates = _.last(_.last(this.ageData));
      let indexOfGreaterThan80 = AGEGROUPS.findIndex(x => x === '>=80');
      // This overly complex statement just adds every value from the `110+` fields to the `>=80` fields
      this.ageData[Number(indexOfGreaterThan80)] = this.ageData[Number(indexOfGreaterThan80)].map(
        (x, i) => this.ageData[Number(indexOfGreaterThan80)][Number(i)] + _.last(this.ageData)[Number(i)]
      );
    }
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
            data={this.ageData}
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
            <h4 className="text-left">Age (Years)</h4>
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
              {_.initial(AGEGROUPS).map((val, index1) => (
                <tbody key={`workflow-table-${index1}`}>
                  <tr className={index1 % 2 ? '' : 'analytics-zebra-bg'}>
                    <td className="font-weight-bold"> {val} </td>
                    {this.ageData[Number(index1)].map((data, subIndex1) => (
                      <td key={subIndex1}> {data} </td>
                    ))}
                  </tr>
                </tbody>
              ))}
            </table>
            {this.hasFakeBirthdateData && (
              <div className="text-secondary fake-demographic-text mb-3">
                <i className="fas fa-info-circle mr-3"></i>
                &gt;=80 years category includes {this.numberOfFakeBirthdates} monitorees where age is greater than 110.
              </div>
            )}
            <h4 className="text-left mt-3 mb-n1">Sex</h4>
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
              {SEXES.map((val, index2) => (
                <tbody key={`workflow-table-${index2}`}>
                  <tr className={index2 % 2 ? '' : 'analytics-zebra-bg'}>
                    <td className="font-weight-bold"> {val} </td>
                    {this.sexData[Number(index2)].map((data, subIndex2) => (
                      <td key={subIndex2}> {data} </td>
                    ))}
                  </tr>
                </tbody>
              ))}
            </table>
            <h4 className="text-left mt-3 mb-n1">Race</h4>
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
              {RACES.map((val, index4) => (
                <tbody key={`workflow-table-${index4}`}>
                  <tr className={index4 % 2 ? '' : 'analytics-zebra-bg'}>
                    <td className="font-weight-bold"> {val} </td>
                    {this.raceData[Number(index4)].map((data, subIndex4) => (
                      <td key={subIndex4}> {data} </td>
                    ))}
                  </tr>
                </tbody>
              ))}
            </table>
            <h4 className="text-left mt-3 mb-n1">Ethnicity</h4>
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
              {ETHNICITIES.map((val, index3) => (
                <tbody key={`workflow-table-${index3}`}>
                  <tr className={index3 % 2 ? '' : 'analytics-zebra-bg'}>
                    <td className="font-weight-bold"> {val} </td>
                    {this.ethnicityData[Number(index3)].map((data, subIndex3) => (
                      <td key={subIndex3}> {data} </td>
                    ))}
                  </tr>
                </tbody>
              ))}
            </table>
            {/* <h4 className="text-left mt-3 mb-n1">Sexual Orientation</h4>
            <table className="analytics-table">
              <thead>
                <tr>
                  <th className="py-0"></th>
                  {WORKFLOWS.map((header, index) => (
                    <th key={index} className="font-weight-bold"> <u>{_.upperCase(header)}</u> </th>
                  ))}
                  <th>Total</th>
                </tr>
              </thead>
              {SEXUAL_ORIENTATIONS.map((val, index5) => (
                <tbody key={`workflow-table-${index5}`}>
                  <tr className={ index5 % 2 ? '' : 'analytics-zebra-bg' }>
                    <td className="font-weight-bold"> {val} </td>
                    {this.soData[index5].map((data, subIndex5) => (
                      <td key={subIndex5}> {data} </td>
                    ))}
                  </tr>
                </tbody>
               ))}
            </table> */}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

Demographics.propTypes = {
  stats: PropTypes.object,
};

export default Demographics;
