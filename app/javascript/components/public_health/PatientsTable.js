import React from 'react';

import { PropTypes } from 'prop-types';
import axios from 'axios';
import { Badge, Card, Col, Form, InputGroup, Nav, Table, TabContent } from 'react-bootstrap';
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
        search: '',
        order: [],
        columns: [],
        length: 15,
        start: 0,
      },
      table: {
        fields: [],
        data: [],
      },
      options: {
        numEntries: [10, 15, 25, 50, 100],
      },
    };
  }

  componentDidMount() {
    const savedTabName = localStorage.getItem(`${this.props.workflow}Tab`);
    if (savedTabName === null || !this.props.tabs.map(tab => tab.name).includes(savedTabName)) {
      localStorage.setItem(`${this.props.workflow}Tab`, this.props.tabs[0].name);
    } else {
      this.handleTabSelect(savedTabName);
    }
  }

  handleTabSelect(tabName) {
    this.setState({ tab: this.props.tabs.filter(tab => tab.name === tabName)[0] }, () => {
      localStorage.setItem(`${this.props.workflow}Tab`, tabName);
    });
    axios
      .get('/public_health/patients', {
        params: { workflow: this.props.workflow, tab: tabName, ...this.state.filters },
      })
      .then(response => {
        this.setState({
          table: {
            fields: response.data.fields,
            data: response.data.linelist,
          },
        });
      });
  }

  render() {
    return (
      <div className="mx-2 pb-4">
        <Nav variant="tabs" activeKey={this.state.tab.name}>
          {this.props.tabs.map(tab => {
            return (
              <Nav.Item key={tab.name} className={tab.name === 'all' ? 'ml-auto' : ''}>
                <Nav.Link eventKey={tab.name} onSelect={this.handleTabSelect}>
                  {tab.label}{' '}
                  <Badge variant={tab.variant} className="badge-larger-font">
                    {tab.total}
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
              <Form className="mb-2">
                <Form.Row className="align-items-center">
                  <Col lg={16} md={14} sm={18} className="mt-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Jurisdiction</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm">
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
                  <Col lg={3} md={4} sm={6} className="mt-1">
                    <InputGroup size="sm">
                      <Form.Control as="select" size="sm">
                        <option value="all">All</option>
                        <option value="exact">Exact Match</option>
                      </Form.Control>
                    </InputGroup>
                  </Col>
                  <Col lg={5} md={6} className="mt-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Assigned User</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm">
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

                  <Col lg={5} md={6} className="mt-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Show</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control as="select" size="sm">
                        {this.state.options.numEntries.map(num => {
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
                  <Col lg={19} md={18} className="mt-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text>Search</InputGroup.Text>
                      </InputGroup.Prepend>
                      <Form.Control size="sm"></Form.Control>
                    </InputGroup>
                  </Col>
                </Form.Row>
              </Form>
              <Table striped bordered hover size="sm">
                <thead>
                  <tr>
                    <th>Monitoree</th>
                    {this.state.table.fields.includes('jurisdiction') && <th>Jurisdiction</th>}
                    {this.state.table.fields.includes('transferred_from') && <th>From Jurisdiction</th>}
                    {this.state.table.fields.includes('transferred_to') && <th>To Jurisdiction</th>}
                    {this.state.table.fields.includes('assigned_user') && <th>Assigned User</th>}
                    <th>State/Local ID</th>
                    <th>Sex</th>
                    <th>Date of Birth</th>
                    {this.state.table.fields.includes('end_of_monitoring') && <th>End of Monitoring</th>}
                    {this.state.table.fields.includes('risk_level') && <th>Risk Level</th>}
                    {this.state.table.fields.includes('monitoring_plan') && <th>Monitoring Plan</th>}
                    {this.state.table.fields.includes('public_health_action') && <th>Latest Public Health Action</th>}
                    {this.state.table.fields.includes('expected_purge_date') && <th>Eligible For Purge After</th>}
                    {this.state.table.fields.includes('reason_for_closure') && <th>Reason for Closure</th>}
                    {this.state.table.fields.includes('closed_at') && <th>Closed At</th>}
                    {this.state.table.fields.includes('transferred_at') && <th>Transferred At</th>}
                    {this.state.table.fields.includes('latest_report') && <th>Latest Report</th>}
                    {this.state.table.fields.includes('status') && <th>Status</th>}
                  </tr>
                </thead>
                <tbody>
                  {this.state.table.data.map(patient => {
                    return (
                      <tr key={patient.id}>
                        {'name' in patient && <td>{patient.name}</td>}
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
                        {'expected_purge_date' in patient && <td>{patient.expected_purge_date}</td>}
                        {'reason_for_closure' in patient && <td>{patient.reason_for_closure}</td>}
                        {'closed_at' in patient && <td>{patient.closed_at}</td>}
                        {'transferred_at' in patient && <td>{patient.transferred_at}</td>}
                        {'latest_report' in patient && <td>{patient.latest_report}</td>}
                        {'status' in patient && <td>{patient.status}</td>}
                      </tr>
                    );
                  })}
                </tbody>
              </Table>
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
  tabs: PropTypes.array,
};

export default PatientsTable;
