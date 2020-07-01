import React from 'react';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import moment from 'moment-timezone';
import { Badge, Card, Col, Form, InputGroup, Nav, Pagination, Spinner, Table, TabContent } from 'react-bootstrap';
// import { useTable } from 'react-table';

import InfoTooltip from '../util/InfoTooltip';

class PatientsTable extends React.Component {
  constructor(props) {
    super(props);
    this.handleTabSelect = this.handleTabSelect.bind(this);
    this.state = {
      tab: props.tabs[0],
      patients: [],
      total: 0,
      filters: {
        jurisdiction: 'all',
        scope: 'all',
        user: 'all',
        entries: 15,
        page: 0,
        search: '',
        order: [],
        columns: [],
      },
      table: {
        fields: [],
        linelist: [],
        total: 0,
      },
      loading: false,
      cancelToken: axios.CancelToken.source(),
    };
    this.handleChange = this.handleChange.bind(this);
  }

  componentDidMount() {
    // load saved tab from local storage if present
    const savedTabName = localStorage.getItem(`${this.props.workflow}Tab`);
    if (savedTabName === null || !this.props.tabs.map(tab => tab.name).includes(savedTabName)) {
      localStorage.setItem(`${this.props.workflow}Tab`, this.props.tabs[0].name);
    } else {
      this.handleTabSelect(savedTabName);
    }

    // fetch workflow and tab counts
    this.props.tabs
      .map(tab => tab.name)
      .filter(tab => tab.name !== 'all')
      .forEach(tab => {
        axios.get(`/public_health/patients/counts/${this.props.workflow}/${tab}`).then(response => {
          const count = {};
          count[`${tab}Count`] = response.data.count;
          this.setState(count);
        });
      });
  }

  handleTabSelect(tabName) {
    this.setState({ tab: this.props.tabs.filter(tab => tab.name === tabName)[0] }, this.fetchData);
    localStorage.setItem(`${this.props.workflow}Tab`, tabName);
  }

  handleChange(event) {
    const filters = this.state.filters;
    if (event.target.name === 'jurisdiction') {
      filters.jurisdiction = event.target.value;
    } else if (event.target.name === 'scope') {
      filters.scope = event.target.value;
    } else if (event.target.name === 'user') {
      filters.user = event.target.value;
    } else if (event.target.name === 'entries') {
      filters.entries = event.target.value;
    } else if (event.target.name === 'search') {
      filters.search = event.target.value;
    }
    this.setState({ filters }, this.fetchData);
  }

  handleKeyPress(event) {
    if (event.which === 13) {
      event.preventDefault();
    }
  }

  fetchData() {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // reset page to 1, but keep all the other filters
    const filters = { ...this.state.filters, page: 1 };
    this.setState(
      {
        filters: filters,
        loading: true,
        cancelToken: axios.CancelToken.source(),
      },
      () => {
        axios
          .get('/public_health/patients', {
            params: { workflow: this.props.workflow, tab: this.state.tab.name, ...this.state.filters },
            cancelToken: this.state.cancelToken.token,
          })
          .catch(error => {
            if (!axios.isCancel(error)) {
              this.setState({ table: { fields: [], linelist: [], total: 0 }, loading: false });
            }
          })
          .then(response => {
            if ('data' in response) {
              this.setState({ table: response.data, loading: false });
            }
          });
      }
    );
  }

  formatTimestamp(timestamp) {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('YYYY-MM-DD HH:mm z') : '';
  }

  render() {
    return (
      <div className="mx-2 pb-4">
        <Nav variant="tabs" activeKey={this.state.tab.name}>
          {this.props.tabs.map(tab => {
            return (
              <Nav.Item key={tab.name} className={tab.name === 'all' ? 'ml-auto' : ''}>
                <Nav.Link eventKey={tab.name} onSelect={this.handleTabSelect}>
                  {tab.label}
                  <Badge variant={tab.variant} className="badge-larger-font ml-1">
                    <span>{tab.name === 'all' ? this.props.allCount : `${tab.name}Count` in this.state ? this.state[`${tab.name}Count`] : ''}</span>
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
                {this.state.tab.description} You are currently in the <u>{this.props.workflow}</u> workflow.
                {this.state.tab.tooltip && <InfoTooltip tooltipTextKey={this.state.tab.tooltip} location="right"></InfoTooltip>}
              </div>
              <Form className="my-1">
                <Form.Row className="align-items-center">
                  <Col lg={16} md={14} sm={18} className="mb-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Jurisdiction</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm" name="jurisdiction" value={this.state.filters.jurisdiction} onChange={this.handleChange}>
                        {Object.keys(this.props.assignedJurisdictions).map(jur_id => {
                          return (
                            <option key={jur_id} value={jur_id}>
                              {this.props.assignedJurisdictions[parseInt(jur_id)]}
                            </option>
                          );
                        })}
                      </Form.Control>
                    </InputGroup>
                  </Col>
                  <Col lg={3} md={4} sm={6} className="mb-1">
                    <InputGroup size="sm">
                      <Form.Control as="select" size="sm" name="scope" value={this.state.filters.scope} onChange={this.handleChange}>
                        <option value="all">All</option>
                        <option value="exact">Exact Match</option>
                      </Form.Control>
                    </InputGroup>
                  </Col>
                  <Col lg={5} md={6} className="mb-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Assigned User</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm" name="user" value={this.state.filters.user} onChange={this.handleChange}>
                        <option value="all">All</option>
                        <option value="none">None</option>
                        {this.props.assignedUsers.map(user => {
                          return (
                            <option key={user} value={user}>
                              {user}
                            </option>
                          );
                        })}
                      </Form.Control>
                    </InputGroup>
                  </Col>
                  <Col lg={5} md={6} className="mb-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Show</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm" name="entries" value={this.state.filters.entries} onChange={this.handleChange}>
                        {[10, 15, 25, 50, 100].map(num => {
                          return (
                            <option key={num} value={num}>
                              {num}
                            </option>
                          );
                        })}
                      </Form.Control>
                      <InputGroup.Append>
                        <InputGroup.Text>entries</InputGroup.Text>
                      </InputGroup.Append>
                    </InputGroup>
                  </Col>
                  <Col lg={19} md={18} className="mb-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Search</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control
                        autoComplete="off"
                        size="sm"
                        name="search"
                        value={this.state.filters.search}
                        onChange={this.handleChange}
                        onKeyPress={this.handleKeyPress}
                      />
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
                    {this.state.table.fields.includes('name') && <th>Monitoree</th>}
                    {this.state.table.fields.includes('jurisdiction') && <th>Jurisdiction</th>}
                    {this.state.table.fields.includes('transferred_from') && <th>From Jurisdiction</th>}
                    {this.state.table.fields.includes('transferred_to') && <th>To Jurisdiction</th>}
                    {this.state.table.fields.includes('assigned_user') && <th>Assigned User</th>}
                    {this.state.table.fields.includes('state_local_id') && <th>State/Local ID</th>}
                    {this.state.table.fields.includes('sex') && <th>Sex</th>}
                    {this.state.table.fields.includes('dob') && <th>Date of Birth</th>}
                    {this.state.table.fields.includes('end_of_monitoring') && <th>End of Monitoring</th>}
                    {this.state.table.fields.includes('risk_level') && <th>Risk Level</th>}
                    {this.state.table.fields.includes('monitoring_plan') && <th>Monitoring Plan</th>}
                    {this.state.table.fields.includes('public_health_action') && <th>Latest Public Health Action</th>}
                    {this.state.table.fields.includes('expected_purge_date') && (
                      <th>
                        Eligible For Purge After <InfoTooltip tooltipTextKey="purgeDate" location="right"></InfoTooltip>
                      </th>
                    )}
                    {this.state.table.fields.includes('reason_for_closure') && <th>Reason for Closure</th>}
                    {this.state.table.fields.includes('closed_at') && <th>Closed At</th>}
                    {this.state.table.fields.includes('transferred_at') && <th>Transferred At</th>}
                    {this.state.table.fields.includes('latest_report') && <th>Latest Report</th>}
                    {this.state.table.fields.includes('status') && <th>Status</th>}
                  </tr>
                </thead>
                <tbody>
                  {this.state.table.linelist.length === 0 && this.state.table.fields.length > 0 && (
                    <tr className="odd">
                      <td colSpan={this.state.table.fields.length} className="text-center">
                        No data available in table
                      </td>
                    </tr>
                  )}
                  {this.state.table.linelist.map(patient => {
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
                    {`Displaying ${this.state.table.linelist.length} out of ${this.state.table.total} `}
                    {this.props.workflow === 'exposure' ? 'monitorees' : 'cases'}
                  </span>
                </div>
                <Pagination className="mb-0">
                  <Pagination.Item>Previous</Pagination.Item>
                  <Pagination.Item>1</Pagination.Item>
                  <Pagination.Ellipsis />
                  <Pagination.Item>a</Pagination.Item>
                  <Pagination.Item>b</Pagination.Item>
                  <Pagination.Item>c</Pagination.Item>
                  <Pagination.Ellipsis />
                  <Pagination.Item>{Math.floor(this.state.table.total / this.state.filters.entries)}</Pagination.Item>
                  <Pagination.Next>Next</Pagination.Next>
                </Pagination>
              </div>
            </Card.Body>
          </Card>
        </TabContent>
      </div>
    );
  }
}

PatientsTable.propTypes = {
  assignedJurisdictions: PropTypes.object,
  assignedUsers: PropTypes.array,
  workflow: PropTypes.oneOf(['exposure', 'isolation']),
  allCount: PropTypes.number,
  tabs: PropTypes.array,
};

export default PatientsTable;
