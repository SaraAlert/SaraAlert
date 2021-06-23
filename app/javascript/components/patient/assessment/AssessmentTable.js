import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Dropdown, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment';
import _ from 'lodash';
import { formatTimestamp } from '../../../utils/DateTime';

import AddAssessmentNote from './actions/AddAssessmentNote';
import AssessmentModal from './AssessmentModal';
import ClearAssessments from './actions/ClearAssessments';
import ContactAttempt from './actions/ContactAttempt';
import CurrentStatus from './actions/CurrentStatus';
import CustomTable from '../../layout/CustomTable';
import MonitoringPeriod from './actions/MonitoringPeriod';
import PauseNotifications from './actions/PauseNotifications';
import reportError from '../../util/ReportError';

class AssessmentTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Actions', field: '', isSortable: false, filter: this.createActionsButton },
          { label: 'ID', field: 'id', isSortable: true },
          {
            label: 'Needs Review',
            field: 'symptomatic',
            isSortable: true,
            tooltip: `${this.props.patient.isolation ? 'isolation' : 'exposure'}NeedsReviewColumn`,
          },
          { label: 'Reporter', field: 'who_reported', isSortable: true },
          { label: 'Created At', field: 'created_at', isSortable: true, filter: formatTimestamp },
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
      showEditAssessmentModal: false,
      showAddAssessmentModal: false,
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
      .get(window.BASE_PATH + '/patients/' + this.props.patient.submission_token + '/assessments', {
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
            }

            return {
              table: {
                ...state.table,
                colData: updatedColData,
                rowData: response.data.table_data,
                totalRows: response.data.total,
              },
              isLoading: false,
              symp_assessments: response.data.symp_assessments || 0,
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
    const className = passesThreshold ? 'text-danger' : '';
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
    const value = parseInt(event.target.value);
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
   * Called when the Add New Report button is clicked.
   * Updates the state to show the appropriate modal for adding a new report.
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
   * Called when the Edit Report button is clicked.
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
        <Dropdown.Menu drop={'up'}>
          <Dropdown.Item id={`report-edit-button-${rowData.id}`} className="px-4 hi" onClick={() => this.handleEditReportClick(rowIndex)}>
            <i className="fas fa-edit fa-fw"></i>
            <span className="ml-2">Edit</span>
          </Dropdown.Item>
          <AddAssessmentNote assessment={rowData} patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
          <ClearAssessments
            assessment_id={rowData.id}
            patient={this.props.patient}
            authenticity_token={this.props.authenticity_token}
            num_pos_labs={this.props.num_pos_labs}
            onlySympAssessment={this.state.symp_assessments === 1 && rowData.symptomatic === 'Yes'}
          />
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
        <Card id="reports" className="mx-2 my-4 card-square">
          <Card.Header as="h1" className="patient-card-header">
            {this.props.section_label}
          </Card.Header>
          <Card.Body>
            <CurrentStatus report_eligibility={this.props.report_eligibility} status={this.props.patient_status} isolation={this.props.patient?.isolation} />
            <Row className="my-4">
              <Col>
                <Button variant="primary" className="mr-2" onClick={this.handleAddReportClick}>
                  <i className="fas fa-plus fa-fw"></i>
                  <span className="ml-2">Add New Report</span>
                </Button>
                <ClearAssessments authenticity_token={this.props.authenticity_token} patient={this.props.patient} num_pos_labs={this.props.num_pos_labs} />
                <PauseNotifications authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
                <ContactAttempt
                  authenticity_token={this.props.authenticity_token}
                  patient={this.props.patient}
                  household_members={this.props.household_members}
                  current_user={this.props.current_user}
                  jurisdiction_paths={this.props.jurisdiction_paths}
                  workflow={this.props.workflow}
                />
              </Col>
              <Col lg={5}>
                <InputGroup size="md">
                  <InputGroup.Prepend>
                    <OverlayTrigger overlay={<Tooltip>Search by id or reporter.</Tooltip>}>
                      <InputGroup.Text className="rounded-0">
                        <i className="fas fa-search"></i>
                        <label htmlFor="reports-search-input" className="ml-1 mb-0" aria-label="Search Reports Table by ID or reporter.">
                          Search
                        </label>
                      </InputGroup.Text>
                    </OverlayTrigger>
                  </InputGroup.Prepend>
                  <Form.Control id="reports-search-input" autoComplete="off" size="md" name="search" onChange={this.handleSearchChange} aria-label="Search" />
                </InputGroup>
              </Col>
            </Row>
            <CustomTable
              title="Reports"
              dataType="assessments"
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
              tableCustomClass="table-has-dropdown"
              getRowClassName={this.getRowClassName}
            />
            <MonitoringPeriod
              authenticity_token={this.props.authenticity_token}
              patient={this.props.patient}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              household_members={this.props.household_members}
              monitoring_period_days={this.props.monitoring_period_days}
              workflow={this.props.workflow}
              symptomatic_assessments_exist={this.state.table.rowData.map(x => x.symptomatic).includes('Yes')}
              num_pos_labs={this.props.num_pos_labs}
              calculated_symptom_onset={this.props.calculated_symptom_onset}
              continuous_exposure_enabled={this.props.continuous_exposure_enabled}
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
  household_members: PropTypes.array,
  report_eligibility: PropTypes.object,
  patient_status: PropTypes.string,
  calculated_age: PropTypes.number,
  patient_initials: PropTypes.string,
  monitoring_period_days: PropTypes.number,
  current_user: PropTypes.object,
  translations: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
  num_pos_labs: PropTypes.number,
  calculated_symptom_onset: function(props) {
    if (props.calculated_symptom_onset && !moment(props.calculated_symptom_onset, 'YYYY-MM-DD').isValid()) {
      return new Error(
        'Invalid prop `calculated_symptom_onset` supplied to `DateInput`, `calculated_symptom_onset` must be a valid date string in the `YYYY-MM-DD` format.'
      );
    }
  },
  continuous_exposure_enabled: PropTypes.bool,
  section_label: PropTypes.string,
};

export default AssessmentTable;
