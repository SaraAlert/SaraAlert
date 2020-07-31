import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Table, Row } from 'react-bootstrap';

class MonitoreeFlow extends React.Component {
  constructor(props) {
    super(props);
    // These should be indexes 0, 1, and 2. But making that assumption is risky, so search the array for them
    // To ensure we're dealing with the correct objects
    this.data_last_24_hours = props.stats.monitoree_snapshots.find(x => x.time_frame === 'Last 24 Hours');
    this.data_last_14_days = props.stats.monitoree_snapshots.find(x => x.time_frame === 'Last 14 Days');
    this.data_total = props.stats.monitoree_snapshots.find(x => x.time_frame === 'Total');
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header as="h5" className="text-left">
            Monitoree Flow Over Time
          </Card.Header>
          <Card.Body className="card-body">
            <Row className="mx-md-5 mx-lg-0">
              {/* Any height: 0px <tr>s are to ensure proper Bootstrap striping. */}
              <Table striped borderless>
                <thead>
                  <tr>
                    <th className="py-0"></th>
                    <th className="py-0"> Last 24 Hours </th>
                    <th className="py-0"> Last 14 Days </th>
                    <th className="py-0"> Total </th>
                  </tr>
                </thead>
                <tbody>
                  <tr style={{ height: '0px' }}></tr>
                  <tr>
                    <td className="py-1 font-weight-bold text-left">
                      <u>INCOMING</u>{' '}
                    </td>
                  </tr>
                  <tr>
                    <td className="text-right">NEW ENROLLMENTS</td>
                    <td>{this.data_last_24_hours.new_enrollments}</td>
                    <td>{this.data_last_14_days.new_enrollments}</td>
                    <td>{this.data_total.new_enrollments}</td>
                  </tr>
                  <tr>
                    <td className="text-right">TRANSFERRED IN</td>
                    <td>{this.data_last_24_hours.transferred_in}</td>
                    <td>{this.data_last_14_days.transferred_in}</td>
                    <td>{this.data_total.transferred_in}</td>
                  </tr>
                  <tr style={{ height: '0px' }}></tr>
                  <tr>
                    <td className="py-1 font-weight-bold text-left">
                      <u>OUTGOING</u>{' '}
                    </td>
                  </tr>
                  <tr className="pt-5">
                    <td className="text-right">CLOSED</td>
                    <td>{this.data_last_24_hours.closed}</td>
                    <td>{this.data_last_14_days.closed}</td>
                    <td>{this.data_total.closed}</td>
                  </tr>
                  <tr>
                    <td className="text-right">TRANSFERRED OUT</td>
                    <td>{this.data_last_24_hours.transferred_out}</td>
                    <td>{this.data_last_14_days.transferred_out}</td>
                    <td>{this.data_total.transferred_out}</td>
                  </tr>
                </tbody>
              </Table>
            </Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoreeFlow.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreeFlow;
