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
import { ToastContainer } from 'react-toastify';
import ReactTooltip from 'react-tooltip';

import { formatDate, formatTimestamp } from '../../utils/DateTime';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';

import AdvancedFilter from './query/AdvancedFilter';
import BadgeHOH from '../util/BadgeHOH';
import CloseRecords from './actions/CloseRecords';
import UpdateCaseStatus from './actions/UpdateCaseStatus';
import UpdateAssignedUser from './actions/UpdateAssignedUser';
import InfoTooltip from '../util/InfoTooltip';
import CustomTable from '../layout/CustomTable';
import JurisdictionFilter from './query/JurisdictionFilter';
import AssignedUserFilter from './query/AssignedUserFilter';
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
          { field: 'dob', label: 'Date of Birth', isSortable: true, tooltip: null, filter: formatDate },
          { field: 'end_of_monitoring', label: 'End of Monitoring', isSortable: true, tooltip: null, filter: this.formatEndOfMonitoring },
          { field: 'extended_isolation', label: 'Extended Isolation To', isSortable: true, tooltip: 'extendedIsolation', filter: formatDate },
          { field: 'first_positive_lab_at', label: 'First Positive Lab', isSortable: true, filter: formatDate },
          { field: 'symptom_onset', label: 'Symptom Onset', isSortable: true, tooltip: null, filter: this.formatSymptomOnset },
          { field: 'risk_level', label: 'Risk Level', isSortable: true, tooltip: null },
          { field: 'monitoring_plan', label: 'Monitoring Plan', isSortable: true, tooltip: null },
          { field: 'public_health_action', label: 'Latest Public Health Action', isSortable: true, tooltip: null },
          { field: 'expected_purge_date', label: 'Eligible for Purge After', isSortable: true, tooltip: 'purgeDate', filter: formatTimestamp },
          { field: 'reason_for_closure', label: 'Reason for Closure', isSortable: true, tooltip: null },
          { field: 'closed_at', label: 'Closed At', isSortable: true, tooltip: null, filter: formatTimestamp },
          { field: 'transferred_at', label: 'Transferred At', isSortable: true, tooltip: null, filter: formatTimestamp },
          { field: 'latest_report', label: 'Latest Report', isSortable: true, tooltip: null, filter: this.formatLatestReport },
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
      jurisdiction_paths: {},
      assigned_users: [],
      query: {
        workflow: props.workflow,
        tab: Object.keys(props.tabs)[0],
        jurisdiction: props.jurisdiction.id,
        scope: 'all',
        user: null,
        search: '',
        page: 0,
        entries: 25,
        tz_offset: new Date().getTimezoneOffset(),
      },
      entryOptions: [10, 15, 25, 50, 100],
      cancelToken: axios.CancelToken.source(),
    };
  }

  componentDidMount = () => {
    // load local storage variables when present
    const query = {};

    // Set tab from local storage if it exists and is a valid tab
    let tab = this.getLocalStorage(`${this.props.workflow}Tab`);
    if (tab === null || !Object.keys(this.props.tabs).includes(tab)) {
      query.tab = this.state.query.tab;
      this.setLocalStorage(`${this.props.workflow}Tab`, query.tab);
    } else {
      query.tab = tab;
    }

    // Set jurisdiction if it exists in local storage
    let jurisdiction = this.getLocalStorage('SaraJurisdiction');
    if (jurisdiction) {
      query.jurisdiction = parseInt(jurisdiction);
    }

    // Set scope if it exists in local storage
    let scope = this.getLocalStorage('SaraScope');
    if (scope) {
      query.scope = scope;
    }

    // Set assigned user if it exists in local storage
    let assigned_user = this.getLocalStorage('SaraAssignedUser');
    if (assigned_user) {
      query.user = assigned_user;
    }

    // Set search if it exists in local storage
    let search = this.getLocalStorage(`SaraSearch`);
    if (search) {
      query.search = search;
    }

    // Set page & sort settings if they exist in local storage & user is in the same workflow as before
    let priorWorkflow = this.getLocalStorage(`Workflow`);
    let page = this.getLocalStorage(`SaraPage`);
    let sortField = this.getLocalStorage(`SaraSortField`);
    let sortDirection = this.getLocalStorage(`SaraSortDirection`);
    if (priorWorkflow && this.props.workflow === priorWorkflow) {
      if (parseInt(page)) {
        query.page = parseInt(page);
      }
      if (sortField && sortDirection) {
        query.order = sortField;
        query.direction = sortDirection === 'asc' ? 'asc' : 'desc';
      }
    } else {
      this.removeLocalStorage(`SaraPage`);
      this.removeLocalStorage(`SaraSortField`);
      this.removeLocalStorage(`SaraSortDirection`);
      // Update workflow local storage to be the current workflow
      this.setLocalStorage(`Workflow`, this.props.workflow);
      query.page = 0;
    }

    // Set entries if it exists in local storage
    let entries = this.getLocalStorage(`SaraEntries`);
    if (parseInt(entries)) {
      query.entries = parseInt(entries);
    }

    // Update the assigned users drop down & patients table a single time
    this.updateAssignedUsers({ ...this.state.query, ...query });
    this.updateTable({ ...this.state.query, ...query });

    // fetch workflow and tab counts
    Object.keys(this.props.tabs).forEach(tab => {
      axios.get(`${window.BASE_PATH}/public_health/patients/counts/${this.props.workflow}/${tab}`).then(response => {
        const count = {};
        count[`${tab}Count`] = response.data.total;
        this.setState(count);
      });
    });
  };

  clearAllFilters = async () => {
    if (await confirmDialog('Are you sure you want to clear all filters? All active filters and searches will be cleared.')) {
      this.removeLocalStorage(`SaraFilter`);
      this.removeLocalStorage(`SaraPage`);
      this.removeLocalStorage(`SaraEntries`);
      this.removeLocalStorage(`SaraSearch`);
      this.removeLocalStorage(`SaraJurisdiction`);
      this.removeLocalStorage(`SaraAssignedUser`);
      this.removeLocalStorage(`SaraScope`);
      this.removeLocalStorage(`SaraSortField`);
      this.removeLocalStorage(`SaraSortDirection`);
      location.reload();
      this.setState(state => {
        const query = state.query;
        delete query.filter;
        return { query };
      });
    }
  };

  handleTabSelect = tab => {
    this.removeLocalStorage(`SaraPage`);

    const query = {};
    query.tab = tab;

    // specifically grab jurisdiction & assigned user filter values when coming from the Transferred Out line list (cause they were hidden)
    if (this.state.query.tab === 'transferred_out') {
      // Set jurisdiction if it exists in local storage
      let jurisdiction = this.getLocalStorage('SaraJurisdiction');
      if (jurisdiction) {
        query.jurisdiction = parseInt(jurisdiction);
      }

      // Set scope if it exists in local storage
      let scope = this.getLocalStorage('SaraScope');
      if (scope) {
        query.scope = scope;
      }

      // Set assigned user if it exists in local storage
      let assigned_user = this.getLocalStorage('SaraAssignedUser');
      if (assigned_user) {
        query.user = assigned_user;
      }
    }
    this.setState(
      state => {
        return { query: { ...state.query, ...query, page: 0 } };
      },
      () => {
        this.updateAssignedUsers(this.state.query);
        this.updateTable(this.state.query);
        this.setLocalStorage(`${this.props.workflow}Tab`, tab);
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
        this.setLocalStorage(`SaraPage`, page.selected);
      }
    );
  };

  /**
   * Called when the number of entries to be shown on a page changes.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Event when num entries changes
   */
  handleEntriesChange = event => {
    this.removeLocalStorage(`SaraPage`);
    const value = event?.target?.value || event;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: parseInt(value), page: 0 },
        };
      },
      () => {
        this.updateTable(this.state.query);
        this.setLocalStorage(`SaraEntries`, value);
      }
    );
  };

  handleJurisdictionChange = jurisdiction => {
    if (jurisdiction !== this.state.query.jurisdiction) {
      this.updateAssignedUsers({ ...this.state.query, jurisdiction });
      this.updateTable({ ...this.state.query, jurisdiction, page: 0 });
      this.removeLocalStorage(`SaraPage`);
      this.setLocalStorage(`SaraJurisdiction`, jurisdiction);
    }
  };

  handleScopeChange = scope => {
    if (scope !== this.state.query.scope) {
      this.updateAssignedUsers({ ...this.state.query, scope });
      this.updateTable({ ...this.state.query, scope, page: 0 });
      this.removeLocalStorage(`SaraPage`);
      this.setLocalStorage(`SaraScope`, scope);
    }
  };

  handleAssignedUserChange = user => {
    if (user !== this.state.query.user) {
      this.updateTable({ ...this.state.query, user, page: 0 });
      this.removeLocalStorage(`SaraPage`);
      if (user) {
        this.setLocalStorage(`SaraAssignedUser`, user);
      } else {
        this.removeLocalStorage(`SaraAssignedUser`);
      }
    }
  };

  handleSearchChange = event => {
    this.updateTable({ ...this.state.query, search: event.target?.value, page: 0 });
    this.removeLocalStorage(`SaraPage`);
    this.setLocalStorage(`SaraSearch`, event.target.value);
  };

  handleKeyPress = event => {
    if (event.which === 13) {
      event.preventDefault();
    }
  };

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
      query.user = null;
    }

    // capture sticky setting for sorting when present
    if (query.order && query.direction) {
      this.setLocalStorage(`SaraSortField`, query.order);
      this.setLocalStorage(`SaraSortDirection`, query.direction);
    }

    this.setState(
      state => {
        return { query: { ...state.query, ...query }, cancelToken, loading: true };
      },
      () => {
        this.queryServer(this.state.query);
      }
    );

    // set query
    this.props.setQuery(query);
  };

  queryServer = _.debounce(query => {
    axios
      .post(window.BASE_PATH + '/public_health/patients', { query, cancelToken: this.state.cancelToken.token })
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

          // update count for custom export
          this.props.setFilteredMonitoreesCount(response.data.total);
        } else {
          this.setState({
            selectedPatients: [],
            selectAll: false,
            actionsEnabled: false,
            loading: false,
          });

          // update count for custom export
          this.props.setFilteredMonitoreesCount(0);
        }
      });
  }, 500);

  /**
   * Function to update patient results with the set advanced filter
   * @param {Object} filter
   * @param {Bool} keepStickySettings - flag for when existing sticky settings should presist during a filter update
   */
  advancedFilterUpdate = (filter, keepStickySettings) => {
    // When applicable, set the pagination & sort settings when the page is reloaded with a sticky advanced filter
    const localStoragePage = this.getLocalStorage('SaraPage');
    const sortField = this.getLocalStorage('SaraSortField');
    const sortDirection = this.getLocalStorage('SaraSortDirection');
    let page = 0;
    let sort = false;
    if (keepStickySettings) {
      if (localStoragePage) {
        page = parseInt(localStoragePage);
      }
      if (sortField && sortDirection) {
        sort = true;
      }
    } else {
      this.removeLocalStorage(`SaraPage`);
      this.removeLocalStorage(`SaraSortField`);
      this.removeLocalStorage(`SaraSortDirection`);
    }

    this.setState(
      state => {
        const query = state.query;
        query.filter = filter?.filter(field => field?.filterOption != null);
        query.page = page;
        if (sort) {
          query.order = sortField;
          query.direction = sortDirection;
        }
        return { query };
      },
      () => {
        this.updateTable(this.state.query);
      }
    );
  };

  /**
   * Method to update the datalist of assigned users & the Patients Table
   * @param {Object} query - updated query fo patients table
   */
  updateAssignedUsers = query => {
    if (query.tab !== 'transferred_out') {
      axios
        .post(window.BASE_PATH + '/jurisdictions/assigned_users', {
          query: { jurisdiction: query.jurisdiction, scope: query.scope, workflow: query.workflow, tab: query.tab },
        })
        .then(response => {
          this.setState({ assigned_users: response.data.assigned_users });
        });
    }
  };

  linkPatient = data => {
    const name = data.value;
    const rowData = data.rowData;
    if (this.state.query.tab === 'transferred_out') {
      return name;
    }
    if (rowData.is_hoh) {
      return (
        <div>
          <BadgeHOH patientId={rowData.id.toString()} customClass={'badge-hoh ml-1'} location={'right'} />
          <a href={`${window.BASE_PATH}/patients/${rowData.id}`}>{name}</a>
        </div>
      );
    }
    return <a href={`${window.BASE_PATH}/patients/${rowData.id}`}>{name}</a>;
  };

  formatEndOfMonitoring = data => {
    const endOfMonitoring = data.value;
    if (endOfMonitoring === 'Continuous Exposure') {
      return 'Continuous Exposure';
    }
    return moment(endOfMonitoring, 'YYYY-MM-DD').format('MM/DD/YYYY');
  };

  formatSymptomOnset = data => {
    return data?.value || 'None reported';
  };

  formatLatestReport = data => {
    const rowData = data.rowData;
    return (
      <Row className="pl-1">
        <Col xs="1" className="align-self-center">
          {!!rowData?.latest_report?.symptomatic && (
            <span data-for={`${rowData.id.toString()}-symptomatic-icon`} data-tip="">
              <i className="fas fa-exclamation-triangle symptomatic-icon"></i>
              <ReactTooltip id={`${rowData.id.toString()}-symptomatic-icon`} multiline={false} place="left" type="dark" effect="solid">
                <span>{`Monitoree's latest report was symptomatic`}</span>
              </ReactTooltip>
            </span>
          )}
        </Col>
        <Col>{rowData.latest_report.timestamp && formatTimestamp(rowData.latest_report.timestamp)}</Col>
      </Row>
    );
  };

  getRowCheckboxAriaLabel = rowData => {
    return `Monitoree ${rowData.name}`;
  };

  createEligibilityTooltip = data => {
    const reportEligibility = data.value;
    const rowData = data.rowData;
    return <EligibilityTooltip id={rowData.id.toString()} report_eligibility={reportEligibility} inline={false} />;
  };

  /**
   * Get a local storage value
   * @param {String} key - relevant local storage key
   */
  getLocalStorage = key => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      return localStorage.getItem(key);
    } catch (error) {
      console.error(error);
      return null;
    }
  };

  /**
   * Set a local storage value
   * @param {String} key - relevant local storage key
   * @param {String} value - value to set
   */
  setLocalStorage = (key, value) => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      localStorage.setItem(key, value);
    } catch (error) {
      console.error(error);
    }
  };

  /**
   * Remove a local storage value
   * @param {String} key - relevant local storage key
   */
  removeLocalStorage = key => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      localStorage.removeItem(key);
    } catch (error) {
      console.error(error);
    }
  };

  render = () => {
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
                  <div id="tab-description" className="lead mt-1 mb-3">
                    {this.props.tabs[this.state.query.tab].description} You are currently in the <u>{this.props.workflow}</u> workflow.
                    {this.props.tabs[this.state.query.tab].tooltip && (
                      <InfoTooltip tooltipTextKey={this.props.tabs[this.state.query.tab].tooltip} location="right"></InfoTooltip>
                    )}
                  </div>
                </Col>
                <Col>
                  <div className="float-right">
                    <Button id="clear-all-filters" size="sm" onClick={this.clearAllFilters}>
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
                      <Col lg={16} md={14} className="my-1">
                        <JurisdictionFilter
                          jurisdiction_paths={this.props.jurisdiction_paths}
                          jurisdiction={this.state.query.jurisdiction}
                          scope={this.state.query.scope}
                          onJurisdictionChange={this.handleJurisdictionChange}
                          onScopeChange={this.handleScopeChange}
                        />
                      </Col>
                      <Col lg={8} md={10} className="my-1">
                        <AssignedUserFilter
                          workflow={this.props.workflow}
                          assigned_users={this.state.assigned_users}
                          assigned_user={this.state.query.user}
                          onAssignedUserChange={this.handleAssignedUserChange}
                        />
                      </Col>
                    </React.Fragment>
                  )}
                </Form.Row>
                <InputGroup size="sm" className="d-flex justify-content-between">
                  <InputGroup.Prepend>
                    <OverlayTrigger overlay={<Tooltip>Search by monitoree name, date of birth, state/local id, cdc id, or nndss/case id</Tooltip>}>
                      <InputGroup.Text className="rounded-0">
                        <i className="fas fa-search"></i>
                        <label htmlFor="search" className="ml-1 mb-0">
                          Search
                        </label>
                      </InputGroup.Text>
                    </OverlayTrigger>
                  </InputGroup.Prepend>
                  <Form.Control
                    autoComplete="off"
                    size="sm"
                    id="search"
                    aria-label="Search"
                    value={this.state.query.search || ''}
                    onChange={this.handleSearchChange}
                    onKeyPress={this.handleKeyPress}
                  />
                  <AdvancedFilter
                    advancedFilterUpdate={this.advancedFilterUpdate}
                    authenticity_token={this.props.authenticity_token}
                    workflow={this.props.workflow}
                    updateStickySettings={true}
                  />
                  {this.state.query.tab !== 'transferred_out' && (
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
                      <Dropdown.Item className="px-3" onClick={() => this.setState({ action: 'Update Assigned User' })}>
                        <i className="fas fa-users text-center" style={{ width: '1em' }}></i>
                        <span className="ml-2">Update Assigned User</span>
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
                handlePageUpdate={this.handlePageUpdate}
                getRowCheckboxAriaLabel={this.getRowCheckboxAriaLabel}
                isSelectable={true}
                isEditable={false}
                isLoading={this.state.loading}
                page={this.state.query.page}
                selectedRows={this.state.selectedPatients}
                selectAll={this.state.selectAll}
                entryOptions={this.state.entryOptions}
                entries={parseInt(this.state.query.entries)}
                orderBy={this.state.query.order !== undefined ? this.state.query.order : ''}
                sortDirection={this.state.query.direction !== undefined ? this.state.query.direction : ''}
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
              monitoring_reasons={this.props.monitoring_reasons}
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
          {this.state.action === 'Update Assigned User' && (
            <UpdateAssignedUser
              authenticity_token={this.props.authenticity_token}
              patients={this.state.table.rowData.filter((_, index) => this.state.selectedPatients.includes(index))}
              close={() => this.setState({ action: undefined })}
              assigned_users={this.state.assigned_users}
            />
          )}
        </Modal>
        <ToastContainer position="top-center" autoClose={2000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </div>
    );
  };
}

PatientsTable.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.oneOf(['exposure', 'isolation']),
  jurisdiction: PropTypes.exact({
    id: PropTypes.number,
    path: PropTypes.string,
  }),
  tabs: PropTypes.object,
  setQuery: PropTypes.func,
  setFilteredMonitoreesCount: PropTypes.func,
  monitoring_reasons: PropTypes.array,
};

export default PatientsTable;
