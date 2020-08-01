import React from 'react';
import { PropTypes } from 'prop-types';
import {
  Badge,
  Button,
  ButtonGroup,
  Card,
  Col,
  Dropdown,
  DropdownButton,
  Form,
  InputGroup,
  Modal,
  Nav,
  OverlayTrigger,
  Spinner,
  Table,
  TabContent,
  Tooltip,
} from 'react-bootstrap';
import ReactPaginate from 'react-paginate';
import axios from 'axios';
import moment from 'moment-timezone';

import CloseRecords from './actions/CloseRecords';
import UpdateCaseStatus from './actions/UpdateCaseStatus';
import InfoTooltip from '../util/InfoTooltip';
import EligibilityTooltip from '../util/EligibilityTooltip';

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
        entries: 25,
        page: 0,
        search: '',
        order: '',
        direction: '',
      },
      loading: false,
      cancelToken: axios.CancelToken.source(),
      selectedPatients: [],
    };
    this.state.jurisdictionPaths[props.jurisdiction.id] = props.jurisdiction.path;
    this.handleChange = this.handleChange.bind(this);
    this.handlePagination = this.handlePagination.bind(this);
    this.handleSelectAllPatients = this.handleSelectAllPatients.bind(this);
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
        count[`${tab}Count`] = response.data.total;
        this.setState(count);
      });
    });

    // fetch list of jurisdiction paths
    this.updateJurisdictionPaths();
  }

  handleTabSelect(tab) {
    const query = this.state.query;
    query.tab = tab;
    query.page = 0;
    this.updateTable(query);
    this.updateAssignedUsers(this.props.jurisdiction.id, this.state.query.scope, this.props.workflow, tab);
    localStorage.setItem(`${this.props.workflow}Tab`, tab);
  }

  handleChange(event) {
    const form = this.state.form;
    const query = this.state.query;
    if (event.target.name === 'jurisdictionPath') {
      this.setState({ form: { ...form, jurisdictionPath: event.target.value } });
      const jurisdictionId = Object.keys(this.state.jurisdictionPaths).find(id => this.state.jurisdictionPaths[parseInt(id)] === event.target.value);
      if (jurisdictionId) {
        this.updateTable({ ...query, jurisdiction: jurisdictionId, page: 0 });
        this.updateAssignedUsers(jurisdictionId, this.state.query.scope, this.props.workflow, this.state.query.tab);
      }
    } else if (event.target.name === 'assignedUser') {
      if (event.target.value === '') {
        this.setState({ form: { ...form, assignedUser: event.target.value } });
        this.updateTable({ ...query, user: 'all', page: 0 });
      } else if (!isNaN(event.target.value) && parseInt(event.target.value) > 0 && parseInt(event.target.value) <= 9999) {
        this.setState({ form: { ...form, assignedUser: event.target.value } });
        this.updateTable({ ...query, user: event.target.value, page: 0 });
      }
    } else if (event.target.name === 'entries') {
      this.updateTable({ ...query, entries: parseInt(event.target.value), page: 0 });
    } else if (event.target.name === 'search') {
      this.updateTable({ ...query, search: event.target.value, page: 0 });
    }
  }

  handleScopeChange(scope) {
    if (scope !== this.state.query.scope) {
      const query = this.state.query;
      this.updateTable({ ...query, scope, page: 0 });
      this.updateAssignedUsers(this.props.jurisdiction.id, scope, this.props.workflow, this.state.query.tab);
    }
  }

  handleUserChange(user) {
    if (user !== this.state.query.user) {
      const form = this.state.form;
      const query = this.state.query;
      this.setState({ form: { ...form, assignedUser: '' } });
      this.updateTable({ ...query, user, page: 0 });
    }
  }

  handlePagination(page) {
    const query = this.state.query;
    this.updateTable({ ...query, page: page.selected });
  }

  handleSort(field, direction) {
    const query = this.state.query;
    this.updateTable({ ...query, order: field, direction, page: 0 });
  }

  handleSelectAllPatients() {
    const selectedPatients = this.state.selectedPatients;
    this.setState({ selectedPatients: selectedPatients.fill(selectedPatients.includes(false)) });
  }

  handleSelectPatient(index) {
    const selectedPatients = this.state.selectedPatients;
    selectedPatients[parseInt(index)] = !selectedPatients[parseInt(index)];
    this.setState({ selectedPatients });
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

    // remove jurisdiction and assigned user filters if tab is transferred out
    if (query.tab === 'transferred_out') {
      query.jurisdiction = this.props.jurisdiction.id;
      query.scope = 'all';
      query.user = 'all';
    }

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
          if (response && response.data && response.data.linelist) {
            this.setState({ patients: response.data, selectedPatients: Array(response.data.linelist.length).fill(false), loading: false });
          } else {
            this.setState({ selectedPatients: [], loading: false });
          }
        });
    });
  }

  updateJurisdictionPaths() {
    axios.get('/jurisdictions/paths').then(response => {
      this.setState({ jurisdictionPaths: response.data.jurisdictionPaths });
    });
  }

  updateAssignedUsers(jurisdiction_id, scope, workflow, tab) {
    if (tab !== 'transferred_out') {
      axios
        .get('/jurisdictions/assigned_users', {
          params: {
            jurisdiction_id,
            scope,
            workflow: workflow,
            tab: tab,
          },
        })
        .then(response => {
          this.setState({ assignedUsers: response.data.assignedUsers });
        });
    }
  }

  formatTimestamp(timestamp) {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
  }

  renderTableHeader(field, label, sortable, tooltip, icon) {
    return (
      <React.Fragment>
        {this.state.patients.fields.includes(field) && (
          <th
            onClick={() => {
              if (sortable) this.handleSort(field, this.state.query.order === field && this.state.query.direction === 'asc' ? 'desc' : 'asc');
            }}
            className={sortable ? 'pr-3' : ''}
            style={{ cursor: sortable ? 'pointer' : 'default' }}>
            {sortable && (
              <div style={{ position: 'relative' }}>
                <i className="fas fa-sort float-right my-1" style={{ color: '#b8b8b8', position: 'absolute', right: '-12px' }}></i>
                {this.state.query.order === field && this.state.query.direction === 'asc' && (
                  <span>
                    <i className="fas fa-sort-up float-right my-1" style={{ position: 'absolute', right: '-12px' }}></i>
                  </span>
                )}
                {this.state.query.order === field && this.state.query.direction === 'desc' && (
                  <span>
                    <i className="fas fa-sort-down float-right my-1" style={{ position: 'absolute', right: '-12px' }}></i>
                  </span>
                )}
              </div>
            )}
            <span>{label}</span>
            {icon && (
              <div className="text-center ml-0">
                <i className={`fa-fw ${icon}`}></i>
              </div>
            )}
            {tooltip && <InfoTooltip tooltipTextKey={tooltip} location="right"></InfoTooltip>}
          </th>
        )}
      </React.Fragment>
    );
  }

  render() {
    return (
      <div className="mx-2 pb-4">
        <Nav variant="tabs" activeKey={this.state.query.tab}>
          {Object.entries(this.props.tabs).map(([tab, tabProps]) => {
            return (
              <Nav.Item key={tab} className={tab === 'all' ? 'ml-auto' : ''}>
                <Nav.Link eventKey={tab} onSelect={this.handleTabSelect} id={`${tab}_tab`}>
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
                  {this.state.query.tab !== 'transferred_out' && (
                    <React.Fragment>
                      <Col lg={17} md={15} className="my-1">
                        <InputGroup size="sm">
                          <InputGroup.Prepend>
                            <InputGroup.Text className="rounded-0">
                              <i className="fas fa-map-marked-alt"></i>
                              <span className="ml-1">Jurisdiction</span>
                            </InputGroup.Text>
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
                          <OverlayTrigger overlay={<Tooltip>Include Sub-Jurisdictions</Tooltip>}>
                            <Button
                              id="allJurisdictions"
                              size="sm"
                              variant={this.state.query.scope === 'all' ? 'primary' : 'outline-secondary'}
                              style={{ outline: 'none', boxShadow: 'none' }}
                              onClick={() => this.handleScopeChange('all')}>
                              All
                            </Button>
                          </OverlayTrigger>
                          <OverlayTrigger overlay={<Tooltip>Exclude Sub-Jurisdictions</Tooltip>}>
                            <Button
                              id="exactJurisdiction"
                              size="sm"
                              variant={this.state.query.scope === 'exact' ? 'primary' : 'outline-secondary'}
                              style={{ outline: 'none', boxShadow: 'none' }}
                              onClick={() => this.handleScopeChange('exact')}>
                              Exact
                            </Button>
                          </OverlayTrigger>
                        </InputGroup>
                      </Col>
                      <Col lg={7} md={9} className="my-1">
                        <InputGroup size="sm">
                          <InputGroup.Prepend>
                            <InputGroup.Text className="rounded-0">
                              <i className="fas fa-users"></i>
                              <span className="ml-1">Assigned User</span>
                            </InputGroup.Text>
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
                          <OverlayTrigger
                            overlay={<Tooltip>Search for {this.props.workflow === 'exposure' ? 'monitorees' : 'cases'} with any or no assigned user</Tooltip>}>
                            <Button
                              id="allAssignedUsers"
                              size="sm"
                              variant={this.state.query.user === 'all' ? 'primary' : 'outline-secondary'}
                              style={{ outline: 'none', boxShadow: 'none' }}
                              onClick={() => this.handleUserChange('all')}>
                              All
                            </Button>
                          </OverlayTrigger>
                          <OverlayTrigger
                            overlay={<Tooltip>Search for {this.props.workflow === 'exposure' ? 'monitorees' : 'cases'} with no assigned user</Tooltip>}>
                            <Button
                              id="noAssignedUser"
                              size="sm"
                              variant={this.state.query.user === 'none' ? 'primary' : 'outline-secondary'}
                              style={{ outline: 'none', boxShadow: 'none' }}
                              onClick={() => this.handleUserChange('none')}>
                              None
                            </Button>
                          </OverlayTrigger>
                        </InputGroup>
                      </Col>
                    </React.Fragment>
                  )}
                  <Col lg={4} md={5} sm={6} className="my-1">
                    <InputGroup size="sm">
                      <InputGroup.Prepend>
                        <InputGroup.Text className="rounded-0">
                          <i className="fas fa-list"></i>
                          <span className="ml-1">Show</span>
                        </InputGroup.Text>
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
                        name="search"
                        value={this.state.query.search}
                        onChange={this.handleChange}
                        onKeyPress={this.handleKeyPress}
                      />
                      {this.state.query !== 'transferred_out' && (
                        <DropdownButton
                          as={ButtonGroup}
                          size="sm"
                          variant="primary"
                          title={
                            <React.Fragment>
                              <i className="fas fa-tools"></i> Actions{' '}
                            </React.Fragment>
                          }
                          className="ml-2"
                          disabled={!this.state.selectedPatients.includes(true)}>
                          {this.state.query.tab !== 'closed' && (
                            <Dropdown.Item className="px-3" onClick={() => this.setState({ action: 'Close Records' })}>
                              <i className="fas fa-window-close text-center" style={{ width: '1em' }}></i>
                              <span className="ml-2">Close Records</span>
                            </Dropdown.Item>
                          )}
                          <Dropdown.Item className="px-3" onClick={() => this.setState({ action: 'Update Case Status' })}>
                            <i className="fas fa-clipboard-list text-center" style={{ width: '1em' }}></i>
                            <span className="ml-2">Update Case Status</span>
                          </Dropdown.Item>
                        </DropdownButton>
                      )}
                    </InputGroup>
                  </Col>
                </Form.Row>
              </Form>
              {this.state.loading && (
                <div className="text-center" style={{ height: '0' }}>
                  <Spinner variant="secondary" animation="border" size="lg" />
                </div>
              )}
              {this.state.patients && (
                <React.Fragment>
                  <Table striped bordered hover size="sm" className="mb-2">
                    <thead>
                      <tr>
                        {this.renderTableHeader('name', 'Monitoree', true, null, null)}
                        {this.renderTableHeader('jurisdiction', 'Jurisdiction', true, null, null)}
                        {this.renderTableHeader('transferred_from', 'From Jurisdiction', true, null, null)}
                        {this.renderTableHeader('transferred_to', 'To Jurisdiction', true, null, null)}
                        {this.renderTableHeader('assigned_user', 'Assigned User', true, null, null)}
                        {this.renderTableHeader('state_local_id', 'State/Local ID', true, null, null)}
                        {this.renderTableHeader('dob', 'Date of Birth', true, null, null)}
                        {this.renderTableHeader('end_of_monitoring', 'End of Monitoring', true, null, null)}
                        {this.renderTableHeader('symptom_onset', 'Symptom Onset', true, null, null)}
                        {this.renderTableHeader('risk_level', 'Risk Level', true, null, null)}
                        {this.renderTableHeader('monitoring_plan', 'Monitoring Plan', true, null, null)}
                        {this.renderTableHeader('public_health_action', 'Latest Public Health Action', true, null, null)}
                        {this.renderTableHeader('expected_purge_date', 'Eligible For Purge After', true, 'purgeDate', null)}
                        {this.renderTableHeader('reason_for_closure', 'Reason for Closure', true, null, null)}
                        {this.renderTableHeader('closed_at', 'Closed At', true, null, null)}
                        {this.renderTableHeader('transferred_at', 'Transferred At', true, null, null)}
                        {this.renderTableHeader('latest_report', 'Latest Report', true, null, null)}
                        {this.renderTableHeader('report_eligibility', '', false, null, 'far fa-bell')}
                        {this.renderTableHeader('status', 'Status', false, null, null)}
                        {this.state.patients.fields.includes('name') && this.state.query.tab !== 'transferred_out' && (
                          <th style={{ cursor: 'pointer' }} onClick={this.handleSelectAllPatients}>
                            <Form.Check
                              type="checkbox"
                              className="text-center ml-0"
                              checked={this.state.selectedPatients.length > 0 && !this.state.selectedPatients.includes(false)}
                              onChange={() => {}}
                            />
                          </th>
                        )}
                      </tr>
                    </thead>
                    <tbody>
                      {this.state.patients.linelist.length === 0 && this.state.patients.fields.length > 0 && (
                        <tr className="odd">
                          <td colSpan={this.state.patients.fields.length + 1} className="text-center">
                            No data available in table
                          </td>
                        </tr>
                      )}
                      {this.state.patients.linelist.map((patient, index) => {
                        return (
                          <tr key={patient.id} id={`patient${patient.id}`}>
                            {'name' in patient && (
                              <td>
                                {this.state.query.tab === 'transferred_out' ? (
                                  <span>{patient.name}</span>
                                ) : (
                                  <a href={`/patients/${patient.id}`}>{patient.name}</a>
                                )}
                              </td>
                            )}
                            {'jurisdiction' in patient && <td>{patient.jurisdiction}</td>}
                            {'transferred_from' in patient && <td>{patient.transferred_from}</td>}
                            {'transferred_to' in patient && <td>{patient.transferred_to}</td>}
                            {'assigned_user' in patient && <td>{patient.assigned_user}</td>}
                            {'state_local_id' in patient && <td>{patient.state_local_id}</td>}
                            {'dob' in patient && <td>{moment(patient.dob, 'YYYY-MM-DD').format('MM/DD/YYYY')}</td>}
                            {'end_of_monitoring' in patient && (
                              <td>
                                {patient.end_of_monitoring === 'Continuous Exposure'
                                  ? 'Continuous Exposure'
                                  : moment(patient.end_of_monitoring, 'YYYY-MM-DD').format('MM/DD/YYYY')}
                              </td>
                            )}
                            {'symptom_onset' in patient && (
                              <td>{patient.symptom_onset ? moment(patient.symptom_onset, 'YYYY-MM-DD').format('MM/DD/YYYY') : ''}</td>
                            )}
                            {'risk_level' in patient && <td>{patient.risk_level}</td>}
                            {'monitoring_plan' in patient && <td>{patient.monitoring_plan}</td>}
                            {'public_health_action' in patient && <td>{patient.public_health_action}</td>}
                            {'expected_purge_date' in patient && <td>{this.formatTimestamp(patient.expected_purge_date)}</td>}
                            {'reason_for_closure' in patient && <td>{patient.reason_for_closure}</td>}
                            {'closed_at' in patient && <td>{this.formatTimestamp(patient.closed_at)}</td>}
                            {'transferred_at' in patient && <td>{this.formatTimestamp(patient.transferred_at)}</td>}
                            {'latest_report' in patient && <td>{this.formatTimestamp(patient.latest_report)}</td>}
                            {'report_eligibility' in patient && (
                              <td>
                                <EligibilityTooltip report_eligibility={patient.report_eligibility} id={patient.id} inline={false} />
                              </td>
                            )}
                            {'status' in patient && <td>{patient.status}</td>}
                            {'id' in patient && this.state.query.tab !== 'transferred_out' && (
                              <td style={{ cursor: 'pointer' }} onClick={() => this.handleSelectPatient(index)}>
                                <Form.Check
                                  type="checkbox"
                                  className="text-center ml-0"
                                  style={{ cursor: 'pointer' }}
                                  checked={this.state.selectedPatients[parseInt(index)]}
                                  onChange={() => {}}
                                />
                              </td>
                            )}
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
                    <ReactPaginate
                      pageCount={Math.ceil(this.state.patients.total / this.state.query.entries)}
                      pageRangeDisplayed={4}
                      marginPagesDisplayed={1}
                      initialPage={this.state.query.page}
                      onPageChange={this.handlePagination}
                      previousLabel="Previous"
                      nextLabel="Next"
                      breakLabel="..."
                      containerClassName="pagination mb-0"
                      activeClassName="active"
                      disabledClassName="disabled"
                      pageClassName="paginate_button page-item"
                      previousClassName="paginate_button page-item"
                      nextClassName="paginate_button page-item"
                      breakClassName="paginate_button page-item"
                      pageLinkClassName="page-link text-primary"
                      previousLinkClassName={this.state.query.page === 0 ? 'page-link' : 'page-link text-primary'}
                      nextLinkClassName={
                        this.state.query.page === Math.ceil(this.state.patients.total / this.state.query.entries) - 1 ? 'page-link' : 'page-link text-primary'
                      }
                      activeLinkClassName="page-link text-light"
                      breakLinkClassName="page-link text-primary"
                    />
                  </div>
                </React.Fragment>
              )}
            </Card.Body>
          </Card>
        </TabContent>
        <Modal size="lg" centered show={this.state.action !== undefined} onHide={() => this.setState({ action: undefined })}>
          <Modal.Header closeButton>
            <Modal.Title>{this.state.action}</Modal.Title>
          </Modal.Header>
          {this.state.action === 'Close Records' && (
            <CloseRecords
              authenticity_token={this.props.authenticity_token}
              patients={this.state.patients.linelist.filter((_, index) => this.state.selectedPatients[parseInt(index)])}
              close={() => this.setState({ action: undefined })}
            />
          )}
          {this.state.action === 'Update Case Status' && (
            <UpdateCaseStatus
              authenticity_token={this.props.authenticity_token}
              patients={this.state.patients.linelist.filter((_, index) => this.state.selectedPatients[parseInt(index)])}
              close={() => this.setState({ action: undefined })}
            />
          )}
        </Modal>
      </div>
    );
  }
}

PatientsTable.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction: PropTypes.exact({
    id: PropTypes.number,
    path: PropTypes.string,
  }),
  workflow: PropTypes.oneOf(['exposure', 'isolation']),
  tabs: PropTypes.object,
};

export default PatientsTable;
