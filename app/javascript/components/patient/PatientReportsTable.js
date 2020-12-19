import React from 'react';
import { Card, DropdownButton, Button, Row, Col, Dropdown, InputGroup, OverlayTrigger, Form, Tooltip } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import CustomTable from '../layout/CustomTable';
import reportError from '../util/ReportError';
import LastDateExposure from '../subject/LastDateExposure';
import CurrentStatus from '../subject/CurrentStatus';
import ClearReports from '../subject/ClearReports';
import PauseNotifications from '../subject/PauseNotifications';
import ContactAttempt from '../subject/ContactAttempt';
import AddReportNote from '../subject/AddReportNote';
import ClearSingleReport from '../subject/ClearSingleReport';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';
import ReportModal from './ReportModal';

class PatientReportsTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Actions', field: '', isSortable: false, filter: this.createActionsButton },
          { label: 'ID', field: 'id', isSortable: true },
          { label: 'Needs Review', field: 'symptomatic', isSortable: true },
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
      showReportModal: false,
    };
  }

  componentDidMount() {
    this.populateSymptomCols();
    this.updateTable(this.state.query);
  }

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

  populateSymptomCols = () => {
    for (const symptom of this.props.symptoms) {
      const symptom_col = { label: symptom.label, field: symptom.name, isSortable: true, filter: this.filterSymptomCell };
      this.setState(state => {
        const updated_table_data = { ...state.table };
        updated_table_data.colData.push(symptom_col);
        return {
          table: updated_table_data,
        };
      });
    }
  };

  filterSymptomCell = data => {
    const rowData = data.rowData;
    const symptomName = data.colData.field;
    const passesThreshold = rowData.passes_threshold_data[symptomName.toString()];
    const className = passesThreshold ? 'concern' : '';
    return <span className={className}>{data.value}</span>;
  };

  /**
   * Called when table data is to be updated because of some change to the table setting.
   * @param {Object} query - Updated query for table data after change.
   */
  updateTable = query => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState({ query, cancelToken, isLoading: true }, () => {
      this.queryServer(query);
    });
  };

  /**
   * Returns updated table data via an axios POST request.
   */
  queryServer = _.debounce(query => {
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
        if (response && response.data && response.data) {
          this.setState(state => {
            return {
              table: { ...state.table, rowData: response.data.table_data, totalRows: response.data.total },
              isLoading: false,
            };
          });
        } else {
          this.setState({ isLoading: false });
        }
      });
  }, 500);

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
   * Called when the number of entries to be shown on a page changes.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Event when num entries changes
   */
  handleEntriesChange = event => {
    const value = event.target.value;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: value },
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
      showAddReportModal: true,
    });
  };

  /**
   * Closes the add report modal by updating state.
   */
  handleAddReportModalClose = () => {
    this.setState({
      showAddReportModal: false,
    });
  };

  /**
   * Called when the Add User button is clicked.
   * Updates the state to show the appropriate modal for adding a user.
   */
  handleEditReportClick = row => {
    this.setState({
      showEditReportModal: true,
      editRow: row,
    });
  };

  /**
   * Closes the edit report modal by updating state.
   */
  handleEditReportModalClose = () => {
    this.setState({
      showEditReportModal: false,
      editRow: null,
    });
  };

  createActionsButton = data => {
    const rowIndex = data.rowIndex;
    const rowData = data.rowData;
    return (
      <DropdownButton
        size="sm"
        variant="primary"
        title={
          <React.Fragment>
            <i className="fas fa-cogs fw"></i>
          </React.Fragment>
        }>
        <Dropdown.Item className="px-4 hi" onClick={() => this.handleEditReportClick(rowIndex)}>
          <i className="fas fa-edit fa-fw"></i>
          <span className="ml-2">Edit</span>
        </Dropdown.Item>
        <AddReportNote assessment={rowData} patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
        {!this.props.patient.isolation && (
          <ClearSingleReport assessment_id={rowData.id} patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
        )}
      </DropdownButton>
    );
  };

  getRowClassName = rowData => {
    return rowData.symptomatic === 'Yes' ? 'table-danger' : '';
  };

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 mt-3 mb-4 card-square">
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
                  {!this.props.patient.isolation && <ClearReports authenticity_token={this.props.authenticity_token} patient={this.props.patient} />}
                  <PauseNotifications authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
                  <ContactAttempt authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
                </Col>
                <Col lg={5}>
                  <InputGroup size="md">
                    <InputGroup.Prepend>
                      <OverlayTrigger overlay={<Tooltip>Search by id or reporter.</Tooltip>}>
                        <InputGroup.Text className="rounded-0">
                          <i className="fas fa-search"></i>
                          <span className="ml-1">Search</span>
                        </InputGroup.Text>
                      </OverlayTrigger>
                    </InputGroup.Prepend>
                    <Form.Control id="search-input" autoComplete="off" size="md" name="search" onChange={this.handleSearchChange} />
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
        {this.state.showAddReportModal && (
          <ReportModal
            show={this.state.showAddReportModal}
            onClose={this.handleAddReportModalClose}
            assessment={{}}
            current_user={this.props.current_user}
            symptoms={this.props.symptoms}
            patient={this.props.patient}
            authenticity_token={this.props.authenticity_token}
            translations={this.props.translations}
            calculated_age={this.props.calculated_age}
            idPre={'new'}
            mode="create"
          />
        )}
        {this.state.showEditReportModal && (
          <ReportModal
            show={this.state.showEditReportModal}
            onClose={this.handleEditReportModalClose}
            assessment={this.state.table.rowData[this.state.editRow]}
            current_user={this.props.current_user}
            threshold_condition_hash={this.state.table.rowData[this.state.editRow].threshold_condition_hash}
            symptoms={this.state.table.rowData[this.state.editRow].symptoms}
            patient={this.props.patient}
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

PatientReportsTable.propTypes = {
  patient: PropTypes.object,
  symptoms: PropTypes.array,
  is_household_member: PropTypes.bool,
  report_eligibility: PropTypes.object,
  patient_status: PropTypes.string,
  calculated_age: PropTypes.number,
  monitoring_period_days: PropTypes.number,
  current_user: PropTypes.object,
  translations: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default PatientReportsTable;
