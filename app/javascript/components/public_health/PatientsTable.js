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
  TabContent,
  Tooltip,
  Row,
} from 'react-bootstrap';

import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import moment from 'moment-timezone';

import AdvancedFilter from './AdvancedFilter';
import CloseRecords from './actions/CloseRecords';
import UpdateCaseStatus from './actions/UpdateCaseStatus';
import InfoTooltip from '../util/InfoTooltip';
import CustomTable from '../layout/CustomTable';
import EligibilityTooltip from '../util/EligibilityTooltip';
import confirmDialog from '../util/ConfirmDialog';

class PatientsTable extends React.Component {
  constructor(props) {
    super(props);
    this.handleTabSelect = this.handleTabSelect.bind(this);
    this.advancedFilterUpdate = this.advancedFilterUpdate.bind(this);
    this.state = {
      table: {
        colData: [
          { field: 'name', label: 'Monitoree', isSortable: true, tooltip: null, filter: this.linkPatient },
          { field: 'jurisdiction', label: 'Jurisdiction', isSortable: true, tooltip: null },
          { field: 'transferred_from', label: 'From Jurisdiction', isSortable: true, tooltip: null },
          { field: 'transferred_to', label: 'To Jurisdiction', isSortable: true, tooltip: null },
          { field: 'assigned_user', label: 'Assigned User', isSortable: true, tooltip: null },
          { field: 'state_local_id', label: 'State/Local ID', isSortable: true, tooltip: null },
          { field: 'dob', label: 'Date of Birth', isSortable: true, tooltip: null, filter: this.formatDate },
          { field: 'end_of_monitoring', label: 'End of Monitoring', isSortable: true, tooltip: null, filter: this.formatEndOfMonitoring },
          { field: 'extended_isolation', label: 'Extended Isolation To', isSortable: true, tooltip: 'extendedIsolation', filter: this.formatDate },
          { field: 'symptom_onset', label: 'Symptom Onset', isSortable: true, tooltip: null, filter: this.formatDate },
          { field: 'risk_level', label: 'Risk Level', isSortable: true, tooltip: null },
          { field: 'monitoring_plan', label: 'Monitoring Plan', isSortable: true, tooltip: null },
          { field: 'public_health_action', label: 'Latest Public Health Action', isSortable: true, tooltip: null },
          { field: 'expected_purge_date', label: 'Eligible For Purge After', isSortable: true, tooltip: 'purgeDate', filter: this.formatTimestamp },
          { field: 'reason_for_closure', label: 'Reason for Closure', isSortable: true, tooltip: null },
          { field: 'closed_at', label: 'Closed At', isSortable: true, tooltip: null, filter: this.formatTimestamp },
          { field: 'transferred_at', label: 'Transferred At', isSortable: true, tooltip: null, filter: this.formatTimestamp },
          { field: 'latest_report', label: 'Latest Report', isSortable: true, tooltip: null, filter: this.formatTimestamp },
          { field: 'status', label: 'Status', isSortable: false, tooltip: null },
          { field: 'report_eligibility', label: '', isSortable: false, tooltip: null, filter: this.createEligibilityTooltip, icon: 'far fa-comment' },
        ],
        displayedColData: [],
        rowData: [],
        totalRows: 0,
      },
      loading: false,
      actionsEnabled: false,
      selectedPatients: [],
      selectAll: false,
      jurisdictionPaths: {},
      assignedUsers: [],
      form: {
        jurisdictionPath: props.jurisdiction.path,
        assignedUser: '',
      },
      query: {
        tab: Object.keys(props.tabs)[0],
        jurisdiction: props.jurisdiction.id,
        scope: 'all',
        user: 'all',
        search: '',
        page: 0,
        entries: 25,
      },
      entryOptions: [10, 15, 25, 50, 100],
      cancelToken: axios.CancelToken.source(),
      filter: null,
    };
    this.state.jurisdictionPaths[props.jurisdiction.id] = props.jurisdiction.path;
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

    // Select page if it exists in local storage
    let page = localStorage.getItem(`SaraPage`);
    if (page) {
      this.handlePageUpdate(JSON.parse(page));
    }

    // Set entries if it exists in local storage
    let entries = localStorage.getItem(`SaraEntries`);
    if (parseInt(entries)) {
      this.handleEntriesChange(parseInt(entries));
    }

    // Set search if it exists in local storage
    let search = localStorage.getItem(`SaraSearch`);
    if (search) {
      this.setState(
        state => {
          return {
            query: { ...state.query, search: search },
          };
        },
        () => {
          this.updateTable(this.state.query);
        }
      );
    }

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

  clearAllFilters = async () => {
    if (await confirmDialog('Are you sure you want to clear all filters? All active filters and searches will be cleared.')) {
      localStorage.removeItem(`SaraFilter`);
      localStorage.removeItem(`SaraPage`);
      localStorage.removeItem(`SaraEntries`);
      localStorage.removeItem(`SaraSearch`);
      location.reload();
      this.setState({ filter: null });
    }
  };

  handleTabSelect = tab => {
    localStorage.removeItem(`SaraPage`);
    this.setState(
      state => {
        return { query: { ...state.query, tab, page: 0 } };
      },
      () => {
        this.updateTable(this.state.query);
        this.updateAssignedUsers(this.props.jurisdiction.id, this.state.query.scope, this.props.workflow, tab);
        localStorage.setItem(`${this.props.workflow}Tab`, tab);
      }
    );
  };

  /**
   * Called when a page is clicked in the pagination component.
   * Updates the table based on the selected page.
   *
   * @param {Object} page - Page object from react-paginate
   */
  handlePageUpdate = page => {
    this.setState(
      state => {
        return {
          query: { ...state.query, page: page.selected },
        };
      },
      () => {
        this.updateTable(this.state.query);
        localStorage.setItem(`SaraPage`, JSON.stringify(page));
      }
    );
  };

  /**
   * Called when the number of entries to be shown on a page changes.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Event when num entries changes
   */
  handleEntriesChange = event => {
    localStorage.removeItem(`SaraPage`);
    const value = event?.target?.value || event;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: value, page: 0 },
        };
      },
      () => {
        this.updateTable(this.state.query);
        localStorage.setItem(`SaraEntries`, value);
      }
    );
  };

  handleChange = event => {
    localStorage.removeItem(`SaraPage`);
    const form = this.state.form;
    const query = this.state.query;
    if (event.target.id === 'jurisdiction_path') {
      this.setState({ form: { ...form, jurisdictionPath: event.target.value } });
      const jurisdictionId = Object.keys(this.state.jurisdictionPaths).find(id => this.state.jurisdictionPaths[parseInt(id)] === event.target.value);
      if (jurisdictionId) {
        this.updateTable({ ...query, jurisdiction: jurisdictionId, page: 0 });
        this.updateAssignedUsers(jurisdictionId, this.state.query.scope, this.props.workflow, this.state.query.tab);
      }
    } else if (event.target.id === 'assigned_user') {
      if (event.target.value === '') {
        this.setState({ form: { ...form, assignedUser: event.target.value } });
        this.updateTable({ ...query, user: 'all', page: 0 });
      } else if (!isNaN(event.target.value) && parseInt(event.target.value) > 0 && parseInt(event.target.value) <= 9999) {
        this.setState({ form: { ...form, assignedUser: event.target.value } });
        this.updateTable({ ...query, user: event.target.value, page: 0 });
      }
    } else if (event.target.id === 'search') {
      this.updateTable({ ...query, search: event.target.value, page: 0 });
      localStorage.setItem(`SaraSearch`, event.target.value);
    }
  };

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

  handleKeyPress(event) {
    if (event.which === 13) {
      event.preventDefault();
    }
  }

  /**
   * Callback called when child Table component detects a selection change.
   * @param {Number[]} selectedRows - Array of selected row indices.
   */
  handleSelect = selectedRows => {
    // All rows are selected if the number selected is the max number shown or the total number of rows completely
    const selectAll = selectedRows.length >= this.state.query.entries || selectedRows.length >= this.state.table.totalRows;
    this.setState({
      actionsEnabled: selectedRows.length > 0,
      selectedPatients: selectedRows,
      selectAll,
    });
  };

  updateTable = query => {
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
        .post('/public_health/patients', {
          workflow: this.props.workflow,
          ...query,
          filter: this.state.filter,
          cancelToken: this.state.cancelToken.token,
        })

        .catch(error => {
          if (!axios.isCancel(error)) {
            this.setState(state => {
              return {
                table: { ...state.table, rowData: [], totalRows: 0 },
                loading: false,
              };
            });
          }
        })
        .then(response => {
          if (response && response.data && response.data.linelist) {
            this.setState(state => {
              const displayedColData = this.state.table.colData.filter(colData => response.data.fields.includes(colData.field));
              return {
                table: { ...state.table, displayedColData, rowData: response.data.linelist, totalRows: response.data.total },
                selectedPatients: [],
                selectAll: false,
                loading: false,
                actionsEnabled: false,
              };
            });
          } else {
            this.setState({
              selectedPatients: [],
              selectAll: false,
              actionsEnabled: false,
              loading: false,
            });
          }
        });
    });
  };

  advancedFilterUpdate(filter) {
    localStorage.removeItem(`SaraPage`);
    this.setState(
      state => ({ filter: filter?.filter(field => field?.filterOption != null), query: { ...state.query, page: 0 } }),
      () => {
        this.updateTable(this.state.query);
      }
    );
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

  linkPatient = (name, id, isHoH) => {
    if (this.state.query.tab === 'transferred_out') {
      return name;
    }
    if (isHoH) {
      return (
        <div>
          <span data-for={`${id}-hoh`} data-tip="" className="badge-hoh ml-1">
            <Badge variant="dark">
              <span>HoH</span>
            </Badge>
          </span>
          <ReactTooltip id={`${id}-hoh`} multiline={true} place="right" type="dark" effect="solid" className="tooltip-container">
            <span>Monitoree is Head of Household that reports on behalf of household members</span>
          </ReactTooltip>
          <a href={`/patients/${id}`}>{name}</a>
        </div>
      );
    }
    return <a href={`/patients/${id}`}>{name}</a>;
  };

  formatTimestamp(timestamp) {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
  }

  formatDate(date) {
    return date ? moment(date, 'YYYY-MM-DD').format('MM/DD/YYYY') : '';
  }

  formatEndOfMonitoring(endOfMonitoring) {
    if (endOfMonitoring === 'Continuous Exposure') {
      return 'Continuous Exposure';
    }
    return moment(endOfMonitoring, 'YYYY-MM-DD').format('MM/DD/YYYY');
  }

  createEligibilityTooltip(reportEligibility, patientId) {
    return <EligibilityTooltip id={patientId} report_eligibility={reportEligibility} inline={false} />;
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
              <Row>
                <Col md="18">
                  <div className="lead mt-1 mb-3">
                    {this.props.tabs[this.state.query.tab].description} You are currently in the <u>{this.props.workflow}</u> workflow.
                    {this.props.tabs[this.state.query.tab].tooltip && (
                      <InfoTooltip tooltipTextKey={this.props.tabs[this.state.query.tab].tooltip} location="right"></InfoTooltip>
                    )}
                  </div>
                </Col>
                <Col>
                  <div className="float-right">
                    <Button size="sm" onClick={this.clearAllFilters}>
                      <i className="fas fa-eraser"></i>
                      <span className="ml-1">Clear All Filters</span>
                    </Button>
                  </div>
                </Col>
              </Row>
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
                            id="jurisdiction_path"
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
                            id="assigned_user"
                            list="assignedUsers"
                            value={this.state.form.assignedUser}
                            onChange={this.handleChange}
                          />
                          <datalist id="assignedUsers">
                            {this.state.assignedUsers?.map(num => {
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
                </Form.Row>
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
                    value={this.state.query.search}
                    onChange={this.handleChange}
                    onKeyPress={this.handleKeyPress}
                  />
                  <AdvancedFilter
                    advancedFilterUpdate={this.advancedFilterUpdate}
                    authenticity_token={this.props.authenticity_token}
                    workflow={this.props.workflow}
                  />
                  {this.state.query !== 'transferred_out' && (
                    <DropdownButton
                      as={ButtonGroup}
                      size="sm"
                      variant="primary"
                      title={
                        <React.Fragment>
                          <i className="fas fa-tools"></i> Bulk Actions{' '}
                        </React.Fragment>
                      }
                      className="ml-2"
                      disabled={!this.state.actionsEnabled}>
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
              </Form>
              <CustomTable
                columnData={this.state.table.displayedColData}
                rowData={this.state.table.rowData}
                totalRows={this.state.table.totalRows}
                handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
                handleSelect={this.handleSelect}
                handleEntriesChange={this.handleEntriesChange}
                isEditable={false}
                isLoading={this.state.loading}
                page={this.state.query.page}
                handlePageUpdate={this.handlePageUpdate}
                selectedRows={this.state.selectedPatients}
                selectAll={this.state.selectAll}
                entryOptions={this.state.entryOptions}
                entries={parseInt(this.state.query.entries)}
              />
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
              patients={this.state.table.rowData.filter((_, index) => this.state.selectedPatients.includes(index))}
              close={() => this.setState({ action: undefined })}
            />
          )}
          {this.state.action === 'Update Case Status' && (
            <UpdateCaseStatus
              authenticity_token={this.props.authenticity_token}
              patients={this.state.table.rowData.filter((_, index) => this.state.selectedPatients.includes(index))}
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
