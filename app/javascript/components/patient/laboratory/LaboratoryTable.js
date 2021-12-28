import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Dropdown, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';
import axios from 'axios';
import _ from 'lodash';
import { formatDate } from '../../../utils/DateTime';

import LaboratoryModal from './LaboratoryModal';
import CustomTable from '../../layout/CustomTable';
import DeleteDialog from '../../util/DeleteDialog';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class LaboratoryTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Actions', field: '', isSortable: false, className: 'text-center', filter: this.renderActionsDropdown },
          { label: 'ID', field: 'id', isSortable: true },
          { label: 'Type', field: 'lab_type', isSortable: true },
          { label: 'Specimen Collected', field: 'specimen_collection', isSortable: true, filter: formatDate },
          { label: 'Report', field: 'report', isSortable: true, filter: formatDate },
          { label: 'Result', field: 'result', isSortable: true },
        ],
        rowData: [],
        totalRows: 0,
        selectedRows: [],
        selectAll: false,
      },
      query: {
        page: 0,
        entries: 10,
        order: 'id',
        direction: 'desc',
      },
      entryOptions: [10, 15, 25],
      cancelToken: axios.CancelToken.source(),
      loading: false,
      activeRow: null,
      showAddModal: false,
      showEditModal: false,
      showDeleteModal: false,
    };
  }

  componentDidMount() {
    // Fetch initial table data
    this.updateTable(this.state.query);
  }

  /**
   * Called when table data is to be updated because of some change to the table setting.
   * @param {Object} query - Updated query for table data after change.
   */
  updateTable = (query = false) => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState({ query, cancelToken, loading: true }, () => {
      this.queryServer(query);
    });
  };

  /**
   * Returns updated table data via an axios GET request.
   * Debounces the query to avoid too many querys at once when someone is typing in the search bar, for example.
   * @param {Object} query - Updated query for table data after change.
   */
  queryServer = _.debounce(query => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .get(`${window.BASE_PATH}/laboratories`, {
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
              loading: false,
            };
          });
        } else {
          reportError(error);
          this.setState({ loading: false });
        }
      })
      .then(response => {
        if (response && response.data && response.data.table_data && !_.isNil(response.data.total)) {
          this.setState(state => {
            return {
              table: {
                ...state.table,
                rowData: response.data.table_data,
                totalRows: response.data.total,
              },
              loading: false,
            };
          });
        } else {
          this.setState({ loading: false });
        }
      });
  }, 500);

  /**
   * Called when table is to be updated because of a query change.
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
        return { query: { ...state.query, search: value, page: 0 } };
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
   * Gets the data for the current laboratory if there is one selected/being edited.
   */
  getCurrLab = () => {
    return this.state.activeRow !== null && !!this.state.table.rowData ? this.state.table.rowData[this.state.activeRow] : {};
  };

  /**
   * Determines if the lab in the current active row is the only positive lab
   */
  isOnlyPosLab = () => {
    const activeLab = this.getCurrLab();
    return this.props.num_pos_labs === 1 && activeLab.result === 'positive' && !_.isNil(activeLab.specimen_collection);
  };

  /**
   * Called when the "Add New Laboratory" button is clicked or when the add lab modal is closed
   * Updates the state to show/hide the appropriate modal for adding a lab.
   */
  toggleAddModal = () => {
    let current = this.state.showAddModal;
    this.setState({
      showAddModal: !current,
    });
  };

  /**
   * Closes the Add New Laboratory modal and makes a request to add a new lab to the db.
   * @param {*} newLabData - State from lab modal containing needed lab data.
   */
  handleAddSubmit = (newLabData, symptomOnset) => {
    this.submitLaboratory(newLabData, symptomOnset, false);
  };

  /**
   * Called when the edit lab button is clicked or when the edit lab modal is closed.
   * Updates the state to show/hide the appropriate modal for editing a lab.
   */
  toggleEditModal = row => {
    let current = this.state.showEditModal;
    this.setState({
      showEditModal: !current,
      activeRow: row,
    });
  };

  /**
   * Closes the Edit Lab modal and makes a request to update an existing lab record.
   * @param {*} updatedLabData - State from lab modal containing updated lab data.
   */
  handleEditSubmit = (updatedLabData, symptomOnset) => {
    const currentCloseContactId = this.state.table.rowData[this.state.activeRow]?.id;
    updatedLabData['id'] = currentCloseContactId;
    this.submitLaboratory(updatedLabData, symptomOnset, true);
  };

  /**
   * Makes a request to add or update an lab record on the backend and reloads page once complete.
   * @param {*} labData - could be a new lab or updates to an eisting lab
   * @param {*} isEdit - whether this is creating a new lab or editing an existing lab
   */
  submitLaboratory = (labData, symptom_onset, isEdit) => {
    this.setState({ loading: true }, () => {
      let url = `${window.BASE_PATH}/laboratories`;
      if (isEdit) {
        url += `/${labData.id}`;
      }
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(url, {
          patient_id: this.props.patient.id,
          lab_type: labData.lab_type,
          specimen_collection: labData.specimen_collection,
          report: labData.report,
          result: labData.result,
          symptom_onset,
        })
        .then(() => {
          location.reload();
        })
        .catch(error => {
          this.setState({ loading: false });
          reportError(error);
        });
    });
  };

  /**
   * Called when the delete laboratory button is clicked or when the delete dialog is closed.
   * Updates the state to show/hide the appropriate modal for deleting a laboratory.
   */
  toggleDeleteModal = row => {
    let current = this.state.showDeleteModal;
    this.setState({
      showDeleteModal: !current,
      activeRow: row,
      delete_reason: null,
      delete_reason_text: null,
    });
  };

  /**
   * Makes a request to delete an existing laboratory record on the backend and reloads page once complete.
   */
  handleDeleteSubmit = patientUpdates => {
    const currLabId = this.state.table.rowData[this.state.activeRow]?.id;
    let deleteReason = this.state.delete_reason;
    if (deleteReason === 'Other' && this.state.delete_reason_text) {
      deleteReason += ', ' + this.state.delete_reason_text;
    }
    const updates = {
      patient_id: this.props.patient.id,
      delete_reason: deleteReason,
    };
    if (patientUpdates.symptom_onset) {
      updates['symptom_onset'] = patientUpdates.symptom_onset;
    }
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .delete(`${window.BASE_PATH}/laboratories/${currLabId}`, { data: updates })
      .then(() => {
        location.reload();
      })
      .catch(error => {
        reportError(error);
      });
  };

  /**
   * onChange handler for necessary delete modal values
   */
  handleDeleteChange = event => {
    if (['delete_reason', 'delete_reason_text'].includes(event?.target?.id)) {
      this.setState({ [event.target.id]: event?.target?.value });
    }
  };

  /**
   * Creates the action button & dropdown for each row in the table.
   * @param {Object} data - Data about the cell this filter is called on.
   */
  renderActionsDropdown = data => {
    const rowIndex = data.rowIndex;
    const rowData = data.rowData;
    // Set the direction to be "up" when there are not enough rows in the table to have space for the dropdown.
    // The table custom class handles the rest.
    // NOTE: If this dropdown increases in height, the custom table class passed to CustomTable will need to be updated.
    const direction = this.state.table.rowData && this.state.table.rowData.length > 2 ? null : 'up';
    return (
      <Dropdown drop={direction}>
        <Dropdown.Toggle id={`laboratory-action-button-${rowData.id}`} size="sm" variant="primary" aria-label="Lab Result Action Dropdown">
          <i className="fas fa-cogs fw"></i>
        </Dropdown.Toggle>
        <Dropdown.Menu>
          <Dropdown.Item className="px-4" onClick={() => this.toggleEditModal(rowIndex)}>
            <i className="fas fa-edit fa-fw"></i>
            <span className="ml-2">Edit</span>
          </Dropdown.Item>
          <Dropdown.Item className="px-4" onClick={() => this.toggleDeleteModal(rowIndex)}>
            <i className="fas fa-trash fa-fw"></i>
            <span className="ml-2">Delete</span>
          </Dropdown.Item>
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  render() {
    return (
      <React.Fragment>
        <Card id="labs-table" className="mx-2 my-4 card-square">
          <Card.Header as="h1" className="patient-card-header">
            Lab Results
            <InfoTooltip tooltipTextKey="labResults" location="right" className="pl-1" />
          </Card.Header>
          <Card.Body className="my-1">
            <Row className="mb-4">
              <Col>
                <Button onClick={this.toggleAddModal}>
                  <i className="fas fa-plus fa-fw"></i>
                  <span className="ml-2">Add New Lab Result</span>
                </Button>
              </Col>
              <Col lg={5}>
                <InputGroup size="md">
                  <InputGroup.Prepend>
                    <OverlayTrigger overlay={<Tooltip>Search by ID, Lab Type, or Result.</Tooltip>}>
                      <InputGroup.Text className="rounded-0">
                        <i className="fas fa-search"></i>
                        <label htmlFor="laboratories-search-input" className="ml-1 mb-0" aria-label="Search Laboratories Table by ID, Lab Type, or Result.">
                          Search
                        </label>
                      </InputGroup.Text>
                    </OverlayTrigger>
                  </InputGroup.Prepend>
                  <Form.Control
                    id="laboratories-search-input"
                    autoComplete="off"
                    size="md"
                    name="search"
                    onChange={this.handleSearchChange}
                    aria-label="Search"
                  />
                </InputGroup>
              </Col>
            </Row>
            <CustomTable
              dataType="laboratories"
              columnData={this.state.table.colData}
              rowData={this.state.table.rowData}
              totalRows={this.state.table.totalRows}
              handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
              handleEntriesChange={this.handleEntriesChange}
              loading={this.state.loading}
              page={this.state.query.page}
              handlePageUpdate={this.handlePageUpdate}
              entryOptions={this.state.entryOptions}
              entries={this.state.query.entries}
              orderBy={!_.isNil(this.state.query.order) ? this.state.query.order : ''}
              sortDirection={!_.isNil(this.state.query.direction) ? this.state.query.direction : ''}
              tableCustomClass="table-has-dropdown"
            />
          </Card.Body>
        </Card>
        {(this.state.showAddModal || this.state.showEditModal) && (
          <LaboratoryModal
            currentLabData={this.state.showAddModal ? {} : this.getCurrLab()}
            onClose={this.state.showAddModal ? this.toggleAddModal : this.toggleEditModal}
            onSave={this.state.showAddModal ? this.handleAddSubmit : this.handleEditSubmit}
            editMode={this.state.showEditModal}
            loading={this.state.loading}
            only_positive_lab={this.isOnlyPosLab()}
            isolation={this.props.patient.isolation}
          />
        )}
        {this.state.showDeleteModal && (
          <DeleteDialog
            type={'Lab Result'}
            delete={this.handleDeleteSubmit}
            toggle={this.toggleDeleteModal}
            onChange={this.handleDeleteChange}
            showSymptomOnsetInput={this.props.patient.isolation && !this.props.patient.symptom_onset && this.isOnlyPosLab()}
          />
        )}
      </React.Fragment>
    );
  }
}

LaboratoryTable.propTypes = {
  patient: PropTypes.object,
  current_user: PropTypes.object,
  authenticity_token: PropTypes.string,
  num_pos_labs: PropTypes.number,
};

export default LaboratoryTable;
