import React from 'react';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import moment from 'moment-timezone';
import { Card, Button, Row, Col, Dropdown, InputGroup, OverlayTrigger, Form, Tooltip } from 'react-bootstrap';

import AddAssessmentNote from './steps/AddAssessmentNote';
import ClearAssessments from './steps/ClearAssessments';
import ClearSingleAssessment from './steps/ClearSingleAssessment';
import ContactAttempt from '../subject/ContactAttempt';
import CurrentStatus from '../subject/CurrentStatus';
import CustomTable from '../layout/CustomTable';
import LastDateExposure from '../subject/LastDateExposure';
import PauseNotifications from '../subject/PauseNotifications';
import reportError from '../util/ReportError';
import AssessmentModal from './AssessmentModal';

class AssessmentTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Actions', field: '', isSortable: false, filter: this.createActionsButton },
          { label: 'ID', field: 'id', isSortable: true },
          // NOTE: This column is only shown in the Exposure workflow. There is a check when the table data
          // is initially loaded that removes this column data if the Patient is in the Isolation workflow.
          { label: 'Needs Review', field: 'symptomatic', isSortable: true, tooltip: 'exposureNeedsReviewColumn' },
          { label: 'Reporter', field: 'who_reported', isSortable: true },
          { label: 'Created At', field: 'created_at', isSortable: true, filter: this.formatTimestamp },
        ],
        rowData: [],
        totalRows: 0,
        selectedRows: [],
        selectAll: false,
      },
      query: {
        page: 0,
        entries: 10,
      },
      entryOptions: [10, 15, 25],
      cancelToken: axios.CancelToken.source(),
      isLoading: false,
      editRow: null,
      showAssessmentModal: false,
    };
  }

  componentDidMount() {
    // Fetch initial table data
    this.updateTable(this.state.query, true);
  }

  /**
   * Called when table data is to be updated because of some change to the table setting.
   * @param {Object} query - Updated query for table data after change.
   * @param {Boolean} isInitialLoad - Flag for if it's the initial load on component mount.
   */
  updateTable = (query, isInitialLoad = false) => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState({ query, cancelToken, isLoading: true }, () => {
      this.queryServer(query, isInitialLoad);
    });
  };

  /**
   * Returns updated table data via an axios GET request.
   * Debounces the query to avoid too many querys at once when someone is typing in the search bar, for example.
   * @param {Object} query - Updated query for table data after change.
   * @param {Boolean} isInitialLoad - Flag for if it's the initial load on component mount. Used to determine if colData needs to be updated.
   */
  queryServer = _.debounce((query, isInitialLoad = false) => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .get('/patients/' + this.props.patient.submission_token + '/assessments', {
        params: {
          patient_id: this.props.patient.id,
          ...query,
          cancelToken: this.state.cancelToken.token,
        },
      })
      .catch(error => {
        if (!axios.isCancel(error)) {
          this.setState(state => {
            return {
              table: { ...state.table, rowData: [], totalRows: 0 },
              isLoading: false,
            };
          });
        } else {
          reportError(error);
          this.setState({ isLoading: false });
        }
      })
      .then(response => {
        if (response && response.data && response.data.table_data && response.data.symptoms && response.data.total) {
          this.setState(state => {
            let updatedColData = state.table.colData;
            // If first load, populate symptom columns in the table.
            if (isInitialLoad) {
              const symptomColData = this.getSymptomCols(response.data.symptoms);
              updatedColData = state.table.colData.concat(symptomColData);
              // Only show the Needs Review column if the patient is in the Exposure workflow
              if (this.props.patient.isolation) {
                delete updatedColData[2];
              }
            }
            return {
              table: {
                ...state.table,
                colData: updatedColData,
                rowData: response.data.table_data,
                totalRows: response.data.total,
              },
              isLoading: false,
            };
          });
        } else {
          this.setState({ isLoading: false });
        }
      });
  }, 500);

  /**
   * Generates column data for symptoms.
   * NOTE: These are the aggregate symptoms from all reports in the table, to ensure no
   * data loss if patient has been transferred between jurisdictions with different symptom
   * configurations.
   */
  getSymptomCols = symptoms => {
    // Sort alphabetically
    const sortedSymptoms = symptoms.sort((a, b) => {
      return a?.name?.localeCompare(b?.name);
    });

    // Create column data for each symptom
    let symptomColData = [];
    for (const symptom of sortedSymptoms) {
      symptomColData.push({ label: symptom?.label, field: symptom?.name, isSortable: true, filter: this.filterSymptomCell });
    }

    return symptomColData;
  };

  /**
   * Updates the content of a given cell in the table based on the row/col data.
   * Specifically, if a given value passes a symptom threshold - it highlights the text red.
   * @param {Object} data - Data about the cell this filter is called on.
   */
  filterSymptomCell = data => {
    const rowData = data.rowData;
    const symptomName = data.colData.field;
    const passesThreshold = rowData.passes_threshold_data[symptomName.toString()];
    const className = passesThreshold ? 'concern' : '';
    return <span className={className}>{data.value}</span>;
  };

  /**
   * Called when table is to be updated because of a sorting change.
   * @param {Object} query - Updated query for table data after change.
   */
  handleTableUpdate = query => {
    this.setState(
      state => ({
        query: { ...state.query, ...query },
      }),
      () => {
        this.updateTable(this.state.query);
      }
    );
  };

  /**
   * Handles change of input in the search bar. Updates table based on input.
   * @param {SyntheticEvent} event - Event when the search input changes
   */
  handleSearchChange = event => {
    const value = event.target.value;
    this.setState(
      state => {
        return { query: { ...state.query, search: value } };
      },
      () => {
        this.updateTable(this.state.query);
      }
    );
  };

  /**
   * Called when the number of entries to be shown on a page changes. Resets page to be 0.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Event when num entries changes
   */
  handleEntriesChange = event => {
    const value = event.target.value;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: value, page: 0 },
        };
      },
      () => {
        this.updateTable(this.state.query);
      }
    );
  };

  /**
   * Called when a page is clicked in the pagination component.
   * Updates the table based on the selected page.
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
      }
    );
  };

  /**
   * Called when the Add User button is clicked.
   * Updates the state to show the appropriate modal for adding a user.
   */
  handleAddReportClick = () => {
    this.setState({
      showAddAssessmentModal: true,
    });
  };

  /**
   * Closes the add report modal by updating state.
   */
  handleAddAssessmentModalClose = () => {
    this.setState({
      showAddAssessmentModal: false,
    });
  };

  /**
   * Called when the Add User button is clicked.
   * Updates the state to show the appropriate modal for adding a user.
   */
  handleEditReportClick = row => {
    this.setState({
      showEditAssessmentModal: true,
      editRow: row,
    });
  };

  /**
   * Closes the edit report modal by updating state.
   */
  handleEditAssessmentModalClose = () => {
    this.setState({
      showEditAssessmentModal: false,
      editRow: null,
    });
  };

  /**
   * Formats values in the timestamp column to be human readable
   * @param {Object} data - Data about the cell this filter is called on.
   */
  formatTimestamp(data) {
    const timestamp = data.value;
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
  }

  /**
   * Creates the action button & dropdown for each row in the table.
   * @param {Object} data - Data about the cell this filter is called on.
   */
  createActionsButton = data => {
    const rowIndex = data.rowIndex;
    const rowData = data.rowData;
    // Set the direction to be "up" when there are not enough rows in the table to have space for the dropdown.
    // The table custom class handles the rest.
    // NOTE: If this dropdown increases in height, the custom table class passed to CustomTable will need to be updated.
    const direction = this.state.table.rowData && this.state.table.rowData.length > 2 ? null : 'up';
    return (
      <Dropdown drop={direction}>
        <Dropdown.Toggle id={`report-action-button-${rowData.id}`} size="sm" variant="primary" aria-label="report-actions-dropdown">
          <i className="fas fa-cogs fw"></i>
        </Dropdown.Toggle>
        <Dropdown.Menu className="test-class" drop={'up'}>
          <Dropdown.Item className="px-4 hi" onClick={() => this.handleEditReportClick(rowIndex)}>
            <i className="fas fa-edit fa-fw"></i>
            <span className="ml-2">Edit</span>
          </Dropdown.Item>
          <AddAssessmentNote assessment={rowData} patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
          {!this.props.patient.isolation && (
            <ClearSingleAssessment assessment_id={rowData.id} patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
          )}
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  /**
   * Determines row classname. Row will be updated with a class that makes it red if the assessment
   * is considered symptomatic.
   * @param {Object} rowData - Report data.
   */
  getRowClassName = rowData => {
    return rowData.symptomatic === 'Yes' ? 'table-danger' : '';
  };

  render() {
    return (
      <React.Fragment>
        <Card id="assessments-table" className="mx-2 mt-3 mb-4 card-square">
          <Card.Header className="h5">Reports</Card.Header>
          <Card.Body>
            <div className="mt-4">
              <CurrentStatus report_eligibility={this.props.report_eligibility} status={this.props.patient_status} isolation={this.props.patient?.isolation} />
              <Row className="my-4">
                <Col>
                  <Button variant="primary" className="mr-2" onClick={this.handleAddReportClick}>
                    <i className="fas fa-plus fa-fw"></i>
                    <span className="ml-2">Add New Report</span>
                  </Button>
                  {!this.props.patient.isolation && <ClearAssessments authenticity_token={this.props.authenticity_token} patient={this.props.patient} />}
                  <PauseNotifications authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
                  <ContactAttempt authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
                </Col>
                <Col lg={5}>
                  <InputGroup size="md">
                    <InputGroup.Prepend>
                      <OverlayTrigger overlay={<Tooltip>Search by id or reporter.</Tooltip>}>
                        <InputGroup.Text className="rounded-0">
                          <i className="fas fa-search"></i>
                          <label htmlFor="reports-search-input" className="ml-1 mb-0">
                            Search
                          </label>
                        </InputGroup.Text>
                      </OverlayTrigger>
                    </InputGroup.Prepend>
                    <Form.Control id="reports-search-input" autoComplete="off" size="md" name="search" onChange={this.handleSearchChange} aria-label="Search" />
                  </InputGroup>
                </Col>
              </Row>
              <div className="mb-4">
                <CustomTable
                  columnData={this.state.table.colData}
                  rowData={this.state.table.rowData}
                  totalRows={this.state.table.totalRows}
                  handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
                  handleEntriesChange={this.handleEntriesChange}
                  isLoading={this.state.isLoading}
                  page={this.state.query.page}
                  handlePageUpdate={this.handlePageUpdate}
                  entryOptions={this.state.entryOptions}
                  entries={this.state.query.entries}
                  getRowClassName={this.getRowClassName}
                  getCustomTableClassName={() => 'reports-table'}
                />
              </div>
            </div>
            <LastDateExposure
              authenticity_token={this.props.authenticity_token}
              patient={this.props.patient}
              is_household_member={this.props.is_household_member}
              monitoring_period_days={this.props.monitoring_period_days}
            />
          </Card.Body>
        </Card>
        {this.state.showAddAssessmentModal && (
          <AssessmentModal
            show={this.state.showAddAssessmentModal}
            onClose={this.handleAddAssessmentModalClose}
            assessment={{}}
            current_user={this.props.current_user}
            threshold_condition_hash={this.props.threshold_condition_hash}
            symptoms={this.props.symptoms}
            patient={this.props.patient}
            patient_initials={this.props.patient_initials}
            authenticity_token={this.props.authenticity_token}
            translations={this.props.translations}
            calculated_age={this.props.calculated_age}
            idPre={'new'}
          />
        )}
        {this.state.showEditAssessmentModal && (
          <AssessmentModal
            show={this.state.showEditAssessmentModal}
            onClose={this.handleEditAssessmentModalClose}
            assessment={this.state.table.rowData[this.state.editRow]}
            current_user={this.props.current_user}
            threshold_condition_hash={this.state.table.rowData[this.state.editRow].threshold_condition_hash}
            symptoms={this.state.table.rowData[this.state.editRow].symptoms}
            patient={this.props.patient}
            patient_initials={this.props.patient_initials}
            authenticity_token={this.props.authenticity_token}
            translations={this.props.translations}
            calculated_age={this.props.calculated_age}
            updateId={this.state.table.rowData[this.state.editRow].id}
            idPre={this.state.table.rowData[this.state.editRow].id.toString()}
          />
        )}
      </React.Fragment>
    );
  }
}

AssessmentTable.propTypes = {
  patient: PropTypes.object,
  symptoms: PropTypes.array,
  threshold_condition_hash: PropTypes.string,
  is_household_member: PropTypes.bool,
  report_eligibility: PropTypes.object,
  patient_status: PropTypes.string,
  calculated_age: PropTypes.number,
  patient_initials: PropTypes.string,
  monitoring_period_days: PropTypes.number,
  current_user: PropTypes.object,
  translations: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default AssessmentTable;
