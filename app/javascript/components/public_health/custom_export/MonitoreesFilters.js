import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import axios from 'axios';

import AdvancedFilter from '../AdvancedFilter';
import AssignedUserFilter from '../query/AssignedUserFilter';
import JurisdictionFilter from '../query/JurisdictionFilter';

class MonitoreesFilters extends React.Component {
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
      .get('/jurisdictions/assigned_users', {
        params: {
          jurisdiction_id: this.state.preset?.config?.query?.patients?.filters?.jurisdiction || this.props.jurisdiction?.id,
          scope: this.state.preset?.config?.query?.patients?.filters?.scope || 'all',
          workflow: this.state.preset?.config?.query?.patients?.filters?.workflow,
          tab: this.state.preset?.config?.query?.patients?.filters?.tab || 'all',
        },
      })
      .then(response => {
        this.setState({ assigned_users: response?.data?.assigned_users });
      });
  };

  render() {
    return (
      <Form.Group>
        <Form.Label className="nav-input-label mb-0">Select Monitorees:</Form.Label>
        <Row>
          <Col md={24} className="my-1">
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
                onChange={event => this.props.onFiltersChange('workflow', event?.target?.value)}
                value={this.props.filters?.workflow}>
                <option value="all">All</option>
                <option value="exposure">Exposure</option>
                <option value="isolation">Isolation</option>
              </Form.Control>
              <InputGroup.Prepend className="pl-2">
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="folder-open" />
                  <span className="ml-1">Tab</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                as="select"
                size="sm"
                className="form-square"
                onChange={event => this.props.onFiltersChange('tab', event?.target?.value)}
                value={this.props.filters?.tab}>
                <option value="all">All</option>
                {this.props.filters?.workflow === 'exposure' && (
                  <React.Fragment>
                    <option value="symptomatic">Symptomatic</option>
                    <option value="non_reporting">Non-Reporting</option>
                    <option value="asymptomatic">Asymptomatic</option>
                    <option value="pui">PUI</option>
                  </React.Fragment>
                )}
                {this.props.filters?.workflow === 'isolation' && (
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
          <Col md={24} className="my-1">
            <JurisdictionFilter
              jurisdiction_paths={this.props.jurisdiction_paths}
              jurisdiction={this.props.filters?.jurisdiction}
              scope={this.props.filters?.scope}
              onJurisdictionChange={jurisdiction => {
                if (jurisdiction !== this.props.filters?.jurisdiction) {
                  this.props.onFiltersChange('jurisdiction', jurisdiction, () => {
                    this.updateAssignedUsers();
                  });
                }
              }}
              onScopeChange={scope => this.props.onFiltersChange('scope', scope)}
            />
          </Col>
          <Col md={24} className="my-1">
            <AssignedUserFilter
              workflow={this.props.filters?.workflow}
              assigned_users={this.state.assigned_users}
              assigned_user={this.props.filters?.user}
              onAssignedUserChange={user => this.props.onFiltersChange('user', user)}
            />
          </Col>
          <Col md={24} className="my-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <OverlayTrigger overlay={<Tooltip>Search by monitoree name, date of birth, state/local id, cdc id, or nndss/case id</Tooltip>}>
                  <InputGroup.Text className="rounded-0">
                    <i className="fas fa-search"></i>
                    <span className="ml-1">Search</span>
                  </InputGroup.Text>
                </OverlayTrigger>
              </InputGroup.Prepend>
              <Form.Control
                autoComplete="off"
                size="sm"
                id="search"
                value={this.props.filters?.search || ''}
                onChange={event => this.props.onFiltersChange('search', event?.target?.value)}
                onKeyPress={event => {
                  if (event.which === 13) {
                    event.preventDefault();
                  }
                }}
              />
              <AdvancedFilter
                advancedFilterUpdate={filter =>
                  this.props.onFiltersChange(
                    'filters',
                    filter?.filter(field => field?.filterOption != null)
                  )
                }
                authenticity_token={this.props.authenticity_token}
                workflow={this.props.filters?.workflow}
              />
            </InputGroup>
          </Col>
        </Row>
      </Form.Group>
    );
  }
}

MonitoreesFilters.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.object,
  filters: PropTypes.object,
  onFiltersChange: PropTypes.func,
};

export default MonitoreesFilters;
