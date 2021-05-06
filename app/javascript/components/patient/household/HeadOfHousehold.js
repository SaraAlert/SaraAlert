import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Table } from 'react-bootstrap';
import ChangeHoH from './actions/ChangeHoH';
import EnrollHouseholdMember from './actions/EnrollHouseholdMember';
import { formatNameAlt } from '../../../utils/Patient';

class HeadOfHousehold extends React.Component {
  render() {
    return (
      <div id="head-of-household">
        <Row>This monitoree is responsible for handling the reporting of the following other monitorees:</Row>
        <Row className="pt-2">
          <Table striped bordered hover size="sm">
            <thead>
              <tr>
                <th>Name</th>
                <th>Workflow</th>
                <th>Monitoring Status</th>
                <th>Continuous Exposure?</th>
              </tr>
            </thead>
            <tbody>
              {this.props.dependents.map((member, index) => {
                return (
                  <tr key={`dl-${index}`}>
                    <td>
                      <a href={`${window.BASE_PATH}/patients/${member.id}`}>{formatNameAlt(member)}</a>
                    </td>
                    <td>{member.isolation ? 'Isolation' : 'Exposure'}</td>
                    <td>{member.monitoring ? 'Actively Monitoring' : 'Not Monitoring'}</td>
                    <td>{member.continuous_exposure ? 'Yes' : 'No'}</td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
        </Row>
        <Row>
          <ChangeHoH patient={this.props.patient} dependents={this.props.dependents} authenticity_token={this.props.authenticity_token} />
          {this.props.can_add_group && <EnrollHouseholdMember responderId={this.props.patient.id} isHoh={true} />}
        </Row>
      </div>
    );
  }
}

HeadOfHousehold.propTypes = {
  can_add_group: PropTypes.bool,
  patient: PropTypes.object,
  dependents: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default HeadOfHousehold;
