import React from 'react';

import { PropTypes } from 'prop-types';
import axios from 'axios';
import moment from 'moment-timezone';
import { Badge, Button, ButtonGroup, Card, Col, Dropdown, DropdownButton, Form, InputGroup, Nav, Spinner, Table, TabContent } from 'react-bootstrap';
import Pagination from 'react-js-pagination';

import InfoTooltip from '../util/InfoTooltip';

class PatientsTable extends React.Component {
  constructor(props) {
    super(props);
    this.handleTabSelect = this.handleTabSelect.bind(this);
    this.state = {
      jurisdictionPaths: {},
      assignedUsers: [],
      config: {
        options: {
          entries: [10, 15, 25, 50, 100],
        },
      },
      form: {
        jurisdictionPath: props.jurisdiction.path,
        assignedUser: '',
      },
      query: {
        tab: Object.keys(props.tabs)[0],
        jurisdiction: props.jurisdiction.id,
        scope: 'all',
        user: 'all',
        entries: 15,
        page: 0,
        search: '',
        order: [],
        columns: [],
      },
      patients: {
        fields: [],
        linelist: [],
        total: 0,
      },
      loading: false,
      cancelToken: axios.CancelToken.source(),
    };
    this.state.jurisdictionPaths[props.jurisdiction.id] = props.jurisdiction.path;
    this.handleChange = this.handleChange.bind(this);
    this.handlePageChange = this.handlePageChange.bind(this);
  }

  componentDidMount() {
    // load saved tab from local storage if present
    let tab = localStorage.getItem(`${this.props.workflow}Tab`);
    if (tab === null || !(tab in this.props.tabs)) {
      tab = this.state.query.tab;
      localStorage.setItem(`${this.props.workflow}Tab`, tab);
    }

    // select tab and fetch patients
    this.handleTabSelect(tab);

    // fetch workflow and tab counts
    Object.keys(this.props.tabs).forEach(tab => {
      axios.get(`/public_health/patients/counts/${this.props.workflow}/${tab}`).then(response => {
        const count = {};
        count[`${tab}Count`] = response.data.count;
        this.setState(count);
      });
    });

    // fetch list of jurisdiction paths
    this.updateJurisdictionPaths();

    // fetch list of assigned users
    this.updateAssignedUsers(this.props.jurisdiction.id, this.state.query.scope);
  }

  handleTabSelect(tab) {
    const query = this.state.query;
    query.tab = tab;
    query.page = 1;
    this.updateTable(query);
    localStorage.setItem(`${this.props.workflow}Tab`, tab);
  }

  handleChange(event) {
    const form = this.state.form;
    const query = this.state.query;
    if (event.target.name === 'jurisdictionPath') {
      this.setState({ form: { ...form, jurisdictionPath: event.target.value } });
      const jurisdictionId = Object.keys(this.state.jurisdictionPaths).find(id => this.state.jurisdictionPaths[parseInt(id)] === event.target.value);
      if (jurisdictionId) {
        this.updateTable({ ...query, jurisdiction: jurisdictionId, page: 1 });
        this.updateAssignedUsers(jurisdictionId, this.state.query.scope);
      }
    } else if (event.target.name === 'assignedUser') {
      if (event.target.value === '') {
        this.setState({ form: { ...form, assignedUser: event.target.value } });
        this.updateTable({ ...query, user: 'all', page: 1 });
      } else if (!isNaN(event.target.value) && parseInt(event.target.value) <= 9999) {
        this.setState({ form: { ...form, assignedUser: event.target.value } });
        this.updateTable({ ...query, user: event.target.value, page: 1 });
      }
    } else if (event.target.name === 'entries') {
      this.updateTable({ ...query, entries: parseInt(event.target.value), page: 1 });
    } else if (event.target.name === 'search') {
      this.updateTable({ ...query, search: event.target.value, page: 1 });
    }
  }

  handleScopeChange(scope) {
    if (scope !== this.state.query.scope) {
      const query = this.state.query;
      this.updateTable({ ...query, scope, page: 1 });
    }
  }

  handleUserChange(user) {
    if (user !== this.state.query.user) {
      const form = this.state.form;
      const query = this.state.query;
      this.setState({ form: { ...form, assignedUser: '' } });
      this.updateTable({ ...query, user, page: 1 });
    }
  }

  handlePageChange(page) {
    const query = this.state.query;
    this.updateTable({ ...query, page: page });
  }

  handleKeyPress(event) {
    if (event.which === 13) {
      event.preventDefault();
    }
  }

  updateTable(query) {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState({ query, cancelToken, loading: true }, () => {
      axios
        .get('/public_health/patients', {
          params: { workflow: this.props.workflow, ...query },
          cancelToken: this.state.cancelToken.token,
        })
        .catch(error => {
          if (!axios.isCancel(error)) {
            this.setState({ patients: { fields: [], linelist: [], total: 0 }, loading: false });
          }
        })
        .then(response => {
          if (response && response.data && response.data.fields && response.data.linelist && response.data.total) {
            this.setState({ patients: response.data, loading: false });
          } else {
            this.setState({ loading: false });
          }
        });
    });
  }

  updateJurisdictionPaths() {
    axios.get('/jurisdictions/paths').then(response => {
      this.setState({ jurisdictionPaths: response.data.jurisdictionPaths });
    });
  }

  updateAssignedUsers(jurisdiction_id, scope) {
    axios.get(`/jurisdictions/${jurisdiction_id}/assigned_users/${scope}`).then(response => {
      this.setState({ assignedUsers: response.data.assignedUsers });
    });
  }

  formatTimestamp(timestamp) {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('YYYY-MM-DD HH:mm z') : '';
  }

  render() {
    return (
      <div className="mx-2 pb-4">
        <Nav variant="tabs" activeKey={this.state.query.tab}>
          {Object.entries(this.props.tabs).map(([tab, tabProps]) => {
            return (
              <Nav.Item key={tab} className={tab === 'all' ? 'ml-auto' : ''}>
                <Nav.Link eventKey={tab} onSelect={this.handleTabSelect}>
                  {tabProps.label}
                  <Badge variant={tabProps.variant} className="badge-larger-font ml-1">
                    <span>{`${tab}Count` in this.state ? this.state[`${tab}Count`] : ''}</span>
                  </Badge>
                </Nav.Link>
              </Nav.Item>
            );
          })}
        </Nav>
        <TabContent>
          <Card>
            <Card.Body className="pl-4 pr-4">
              <div className="lead mt-1 mb-3">
                {this.props.tabs[this.state.query.tab].description} You are currently in the <u>{this.props.workflow}</u> workflow.
                {this.props.tabs[this.state.query.tab].tooltip && (
                  <InfoTooltip tooltipTextKey={this.props.tabs[this.state.query.tab].tooltip} location="right"></InfoTooltip>
                )}
              </div>
              <Form className="my-1">
                <Form.Row className="align-items-center">
                  <Col lg={17} md={15} className="my-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text className="rounded-0">Jurisdiction</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control
                        type="text"
                        autoComplete="off"
                        name="jurisdictionPath"
                        list="jurisdictionPaths"
                        value={this.state.form.jurisdictionPath}
                        onChange={this.handleChange}
                      />
                      <datalist id="jurisdictionPaths">
                        {Object.entries(this.state.jurisdictionPaths).map(([id, path]) => {
                          return (
                            <option value={path} key={id}>
                              {path}
                            </option>
                          );
                        })}
                      </datalist>
                      <Button
                        size="sm"
                        variant={this.state.query.scope === 'all' ? 'secondary' : 'outline-secondary'}
                        style={{ outline: 'none', boxShadow: 'none' }}
                        onClick={() => this.handleScopeChange('all')}>
                        All
                      </Button>
                      <Button
                        size="sm"
                        variant={this.state.query.scope === 'exact' ? 'secondary' : 'outline-secondary'}
                        style={{ outline: 'none', boxShadow: 'none' }}
                        onClick={() => this.handleScopeChange('exact')}>
                        Exact
                      </Button>
                    </InputGroup>
                  </Col>
                  <Col lg={7} md={9} className="my-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text className="rounded-0">Assigned User</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control
                        type="text"
                        autoComplete="off"
                        name="assignedUser"
                        list="assignedUsers"
                        value={this.state.form.assignedUser}
                        onChange={this.handleChange}
                      />
                      <datalist id="assignedUsers">
                        {this.state.assignedUsers.map(num => {
                          return (
                            <option value={num} key={num}>
                              {num}
                            </option>
                          );
                        })}
                      </datalist>
                      <Button
                        size="sm"
                        variant={this.state.query.user === 'all' ? 'secondary' : 'outline-secondary'}
                        style={{ outline: 'none', boxShadow: 'none' }}
                        onClick={() => this.handleUserChange('all')}>
                        All
                      </Button>
                      <Button
                        size="sm"
                        variant={this.state.query.user === 'none' ? 'secondary' : 'outline-secondary'}
                        style={{ outline: 'none', boxShadow: 'none' }}
                        onClick={() => this.handleUserChange('none')}>
                        None
                      </Button>
                    </InputGroup>
                  </Col>
                  <Col lg={4} md={5} sm={6} className="my-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text className="rounded-0">Show</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm" name="entries" value={this.state.query.entries} onChange={this.handleChange}>
                        {this.state.config.options.entries.map(num => {
                          return (
                            <option key={num} value={num}>
                              {num}
                            </option>
                          );
                        })}
                      </Form.Control>
                    </InputGroup>
                  </Col>
                  <Col lg={20} md={19} sm={18} className="my-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text className="rounded-0">Search</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control
                        autoComplete="off"
                        size="sm"
                        name="search"
                        value={this.state.query.search}
                        onChange={this.handleChange}
                        onKeyPress={this.handleKeyPress}
                      />
                      <DropdownButton
                        as={ButtonGroup}
                        size="sm"
                        variant="secondary"
                        title="Actions"
                        className="ml-2"
                        style={{ outline: 'none', boxShadow: 'none' }}>
                        <Dropdown.Item>Case Status</Dropdown.Item>
                      </DropdownButton>
                    </InputGroup>
                  </Col>
                </Form.Row>
              </Form>
              {this.state.loading && (
                <div className="text-center" style={{ height: '0' }}>
                  <Spinner variant="secondary" animation="border" size="lg" />
                </div>
              )}
              <Table striped bordered hover size="sm" className="mb-2">
                <thead>
                  <tr>
                    {this.state.patients.fields.includes('name') && <th>Monitoree</th>}
                    {this.state.patients.fields.includes('jurisdiction') && <th>Jurisdiction</th>}
                    {this.state.patients.fields.includes('transferred_from') && <th>From Jurisdiction</th>}
                    {this.state.patients.fields.includes('transferred_to') && <th>To Jurisdiction</th>}
                    {this.state.patients.fields.includes('assigned_user') && <th>Assigned User</th>}
                    {this.state.patients.fields.includes('state_local_id') && <th>State/Local ID</th>}
                    {this.state.patients.fields.includes('sex') && <th>Sex</th>}
                    {this.state.patients.fields.includes('dob') && <th>Date of Birth</th>}
                    {this.state.patients.fields.includes('end_of_monitoring') && <th>End of Monitoring</th>}
                    {this.state.patients.fields.includes('risk_level') && <th>Risk Level</th>}
                    {this.state.patients.fields.includes('monitoring_plan') && <th>Monitoring Plan</th>}
                    {this.state.patients.fields.includes('public_health_action') && <th>Latest Public Health Action</th>}
                    {this.state.patients.fields.includes('expected_purge_date') && (
                      <th>
                        Eligible For Purge After <InfoTooltip tooltipTextKey="purgeDate" location="right"></InfoTooltip>
                      </th>
                    )}
                    {this.state.patients.fields.includes('reason_for_closure') && <th>Reason for Closure</th>}
                    {this.state.patients.fields.includes('closed_at') && <th>Closed At</th>}
                    {this.state.patients.fields.includes('transferred_at') && <th>Transferred At</th>}
                    {this.state.patients.fields.includes('latest_report') && <th>Latest Report</th>}
                    {this.state.patients.fields.includes('status') && <th>Status</th>}
                  </tr>
                </thead>
                <tbody>
                  {this.state.patients.linelist.length === 0 && this.state.patients.fields.length > 0 && (
                    <tr className="odd">
                      <td colSpan={this.state.patients.fields.length} className="text-center">
                        No data available in table
                      </td>
                    </tr>
                  )}
                  {this.state.patients.linelist.map(patient => {
                    return (
                      <tr key={patient.id}>
                        {'name' in patient && (
                          <td>
                            <a href={`/patients/${patient.id}`}>{patient.name}</a>
                          </td>
                        )}
                        {'jurisdiction' in patient && <td>{patient.jurisdiction}</td>}
                        {'transferred_from' in patient && <td>{patient.transferred_from}</td>}
                        {'transferred_to' in patient && <td>{patient.transferred_to}</td>}
                        {'assigned_user' in patient && <td>{patient.assigned_user}</td>}
                        {'state_local_id' in patient && <td>{patient.state_local_id}</td>}
                        {'sex' in patient && <td>{patient.sex}</td>}
                        {'dob' in patient && <td>{patient.dob}</td>}
                        {'end_of_monitoring' in patient && <td>{patient.end_of_monitoring}</td>}
                        {'risk_level' in patient && <td>{patient.risk_level}</td>}
                        {'monitoring_plan' in patient && <td>{patient.monitoring_plan}</td>}
                        {'public_health_action' in patient && <td>{patient.public_health_action}</td>}
                        {'expected_purge_date' in patient && <td>{this.formatTimestamp(patient.expected_purge_date)}</td>}
                        {'reason_for_closure' in patient && <td>{patient.reason_for_closure}</td>}
                        {'closed_at' in patient && <td>{this.formatTimestamp(patient.closed_at)}</td>}
                        {'transferred_at' in patient && <td>{this.formatTimestamp(patient.transferred_at)}</td>}
                        {'latest_report' in patient && <td>{this.formatTimestamp(patient.latest_report)}</td>}
                        {'status' in patient && <td>{patient.status}</td>}
                      </tr>
                    );
                  })}
                </tbody>
              </Table>
              <div className="d-flex">
                <div className="d-block mr-auto py-1" style={{ height: '38px' }}>
                  <span className="align-middle">
                    {`Displaying ${this.state.patients.linelist.length} out of ${this.state.patients.total} `}
                    {this.props.workflow === 'exposure' ? 'monitorees' : 'cases'}
                  </span>
                </div>
                <Pagination
                  totalItemsCount={this.state.patients.total}
                  onChange={this.handlePageChange}
                  activePage={this.state.query.page}
                  itemsCountPerPage={this.state.query.entries}
                  pageRangeDisplayed={5}
                  prevPageText="Previous"
                  nextPageText="Next"
                  className="mb-0"
                />
              </div>
            </Card.Body>
          </Card>
        </TabContent>
      </div>
    );
  }
}

PatientsTable.propTypes = {
  jurisdiction: PropTypes.exact({
    id: PropTypes.number,
    path: PropTypes.string,
  }),
  workflow: PropTypes.oneOf(['exposure', 'isolation']),
  tabs: PropTypes.object,
};

export default PatientsTable;
