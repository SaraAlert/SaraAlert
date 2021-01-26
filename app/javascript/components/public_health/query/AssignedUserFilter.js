import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, InputGroup, OverlayTrigger, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

class AssignedUserFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assigned_user: props.assigned_user !== 'none' ? props.assigned_user : '' || '',
    };
  }

  handleAssignedUserChange = assigned_user => {
    if (!isNaN(assigned_user) && parseInt(assigned_user) > 0 && parseInt(assigned_user) <= 999999) {
      this.setState({ assigned_user }, () => {
        this.props.onAssignedUserChange(assigned_user);
      });
    } else if ([null, ''].includes(assigned_user)) {
      this.setState({ assigned_user: '' }, () => {
        this.props.onAssignedUserChange(null);
      });
    } else if (assigned_user === 'none') {
      this.setState({ assigned_user: '' }, () => {
        this.props.onAssignedUserChange(assigned_user);
      });
    }
  };

  render() {
    return (
      <InputGroup size="sm">
        <InputGroup.Prepend>
          <InputGroup.Text className="rounded-0">
            <FontAwesomeIcon icon="users" />
            <span className="ml-1">Assigned User</span>
          </InputGroup.Text>
        </InputGroup.Prepend>
        <Form.Control
          id="assigned_user"
          aria-label="Assigned User Filter"
          type="text"
          autoComplete="off"
          list="assigned_users"
          value={this.state.assigned_user || ''}
          onChange={event => this.handleAssignedUserChange(event?.target?.value)}
        />
        <datalist id="assigned_users">
          {this.props.assigned_users?.map(num => {
            return (
              <option value={num} key={num}>
                {num}
              </option>
            );
          })}
        </datalist>
        <OverlayTrigger
          overlay={
            <Tooltip>
              Search for {this.props.workflow === 'exposure' ? 'monitorees' : this.props.workflow === 'isolation' ? 'cases' : 'monitorees and cases'} with any
              or no assigned user
            </Tooltip>
          }>
          <Button
            id="allAssignedUsers"
            size="sm"
            variant={this.props.assigned_user === null ? 'primary' : 'outline-secondary'}
            style={{ outline: 'none', boxShadow: 'none' }}
            onClick={() => this.handleAssignedUserChange(null)}>
            All
          </Button>
        </OverlayTrigger>
        <OverlayTrigger
          overlay={
            <Tooltip>
              Search for {this.props.workflow === 'exposure' ? 'monitorees' : this.props.workflow === 'isolation' ? 'cases' : 'monitorees and cases'} with no
              assigned user
            </Tooltip>
          }>
          <Button
            id="noAssignedUser"
            size="sm"
            variant={this.props.assigned_user === 'none' ? 'primary' : 'outline-secondary'}
            style={{ outline: 'none', boxShadow: 'none' }}
            onClick={() => this.handleAssignedUserChange('none')}>
            None
          </Button>
        </OverlayTrigger>
      </InputGroup>
    );
  }
}

AssignedUserFilter.propTypes = {
  workflow: PropTypes.string,
  assigned_users: PropTypes.array,
  assigned_user: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  onAssignedUserChange: PropTypes.func,
};

export default AssignedUserFilter;
