import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import axios from 'axios';

import AdvancedFilter from '../AdvancedFilter';
import AssignedUserFilter from '../query/AssignedUserFilter';
import JurisdictionFilter from '../query/JurisdictionFilter';

class PatientsFilters extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assigned_users: [],
    };
  }

  componentDidMount() {
    this.updateAssignedUsers();
  }

  // Update Assigned Users datalist
  updateAssignedUsers = () => {
    axios
      .post('/jurisdictions/assigned_users', {
        query: {
          jurisdiction: this.props.query?.jurisdiction || this.props.jurisdiction?.id,
          scope: this.props.query?.scope || 'all',
          workflow: this.props.query?.workflow,
          tab: this.props.query?.tab || 'all',
        },
      })
      .then(response => {
        this.setState({ assigned_users: response?.data?.assigned_users });
      });
  };

  render() {
    return (
      <Form.Group className="mb-0">
        <Row className="px-3">
          <Col md={12} className="my-1 px-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="project-diagram" />
                  <span className="ml-1">Workflow</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                as="select"
                size="sm"
                className="form-square"
                onChange={event => {
                  this.props.onQueryChange('workflow', event?.target?.value);
                  this.props.onQueryChange('tab', 'all');
                }}
                value={this.props.query?.workflow}
                disabled={this.props.disabled}>
                <option value="all">All</option>
                <option value="exposure">Exposure</option>
                <option value="isolation">Isolation</option>
              </Form.Control>
            </InputGroup>
          </Col>
          <Col md={12} className="my-1 px-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="stream" />
                  <span className="ml-1">Line List</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                as="select"
                size="sm"
                className="form-square"
                onChange={event => this.props.onQueryChange('tab', event?.target?.value)}
                value={this.props.query?.tab}
                disabled={this.props.disabled}>
                <option value="all">All</option>
                {this.props.query?.workflow === 'exposure' && (
                  <React.Fragment>
                    <option value="symptomatic">Symptomatic</option>
                    <option value="non_reporting">Non-Reporting</option>
                    <option value="asymptomatic">Asymptomatic</option>
                    <option value="pui">PUI</option>
                  </React.Fragment>
                )}
                {this.props.query?.workflow === 'isolation' && (
                  <React.Fragment>
                    <option value="requiring_review">Records Requiring Review</option>
                    <option value="non_reporting">Non-Reporting</option>
                    <option value="reportingc">Reporting</option>
                  </React.Fragment>
                )}
                <option value="closed">Closed</option>
                <option value="transferred_in">Transferred In</option>
                <option value="transferred_out">Transferred Out</option>
              </Form.Control>
            </InputGroup>
          </Col>
          <Col md={24} className="my-1 px-1">
            <JurisdictionFilter
              jurisdiction_paths={this.props.jurisdiction_paths}
              jurisdiction={this.props.query?.jurisdiction}
              scope={this.props.query?.scope}
              onJurisdictionChange={jurisdiction => {
                if (jurisdiction !== this.props.query?.jurisdiction) {
                  this.props.onQueryChange('jurisdiction', jurisdiction, () => {
                    this.updateAssignedUsers();
                  });
                }
              }}
              onScopeChange={scope => this.props.onQueryChange('scope', scope)}
              disabled={this.props.disabled}
            />
          </Col>
          <Col md={24} className="my-1 px-1">
            <AssignedUserFilter
              workflow={this.props.query?.workflow}
              assigned_users={this.state.assigned_users}
              assigned_user={this.props.query?.user}
              onAssignedUserChange={user => this.props.onQueryChange('user', user)}
              disabled={this.props.disabled}
            />
          </Col>
          <Col md={24} className="my-1 px-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <OverlayTrigger overlay={<Tooltip>Search by monitoree name, date of birth, state/local id, cdc id, or nndss/case id</Tooltip>}>
                  <InputGroup.Text className="rounded-0">
                    <FontAwesomeIcon icon="search" />
                    <span className="ml-1">Dashboard Search Terms</span>
                  </InputGroup.Text>
                </OverlayTrigger>
              </InputGroup.Prepend>
              <Form.Control
                autoComplete="off"
                size="sm"
                id="search"
                value={this.props.query?.search || ''}
                onChange={event => this.props.onQueryChange('search', event?.target?.value)}
                onKeyPress={event => {
                  if (event.which === 13) {
                    event.preventDefault();
                  }
                }}
                disabled={this.props.disabled}
              />
              <AdvancedFilter
                key="custom-export-advanced-filter"
                advancedFilterUpdate={filter =>
                  this.props.onQueryChange(
                    'filter',
                    filter?.filter(field => field?.filterOption != null)
                  )
                }
                authenticity_token={this.props.authenticity_token}
                workflow={this.props.query?.workflow}
                disabled={this.props.disabled}
              />
            </InputGroup>
          </Col>
        </Row>
      </Form.Group>
    );
  }
}

PatientsFilters.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.object,
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default PatientsFilters;
