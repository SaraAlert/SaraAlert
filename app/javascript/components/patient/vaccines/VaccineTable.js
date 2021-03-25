import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Dropdown, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';

import { formatDate } from '../../../utils/DateTime';
import axios from 'axios';
import _ from 'lodash';

import CustomTable from '../../layout/CustomTable';
import reportError from '../../util/ReportError';
import VaccineModal from './VaccineModal';

class VaccineTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Actions', field: '', isSortable: false, filter: this.createActionsButton },
          { label: 'ID', field: 'id', isSortable: true },
          { label: 'Vaccine Group', field: 'group_name', isSortable: true },
          { label: 'Product Name', field: 'product_name', isSortable: true },
          { label: 'Administration Date', field: 'administration_date', isSortable: true, filter: formatDate },
          { label: 'Dose Number', field: 'dose_number', isSortable: true },
          { label: 'Notes', field: 'notes', isSortable: true },
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
      showEditVaccineModal: false,
      showAddVaccineModal: false,
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

    this.setState({ query, cancelToken, isLoading: true }, () => {
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
      .get(`${window.BASE_PATH}/vaccines`, {
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
        if (response && response.data && response.data.table_data && response.data.total !== null && response.data.total !== undefined) {
          this.setState(state => {
            return {
              table: {
                ...state.table,
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
   * Called when the Add New Vaccine button is clicked.
   * Updates the state to show the appropriate modal for adding a vaccine.
   */
  handleAddVaccineClick = () => {
    this.setState({
      showAddVaccineModal: true,
    });
  };

  /**
   * Closes the Add New Vaccine modal by updating state.
   */
  handleAddVaccineModalClose = () => {
    this.setState({
      showAddVaccineModal: false,
    });
  };

  /**
   * Closes the Add New Vaccine modal and makes a request to add a new vaccine to the db.
   * @param {*} newVaccineData - State from vaccine modal containing needed vaccine data.
   */
  handleAddVaccineModalSave = newVaccineData => {
    this.setState({ showAddVaccineModal: false }, () => {
      this.addNewVaccine(newVaccineData);
    });
  };

  /**
   * Makes a request to create a new vaccine on the backend and reloads page once complete.
   * @param {*} newVaccineData
   */
  addNewVaccine = newVaccineData => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(`${window.BASE_PATH}/vaccines`, {
        group_name: newVaccineData.group_name,
        product_name: newVaccineData.product_name,
        administration_date: newVaccineData.administration_date,
        dose_number: newVaccineData.dose_number,
        notes: newVaccineData.notes,
        patient_id: this.props.patient.id,
      })
      .then(() => {
        // Refresh the page to see the updated table data
        location.reload();
      })
      .catch(err => {
        reportError(err?.response?.data?.error ? err.response.data.error : err, false);
      });
  };

  /**
   * Called when the edit vaccine button is clicked.
   * Updates the state to show the appropriate modal for editing a vaccine.
   */
  handleEditVaccineClick = row => {
    this.setState({
      showEditVaccineModal: true,
      editRow: row,
    });
  };

  /**
   * Closes the edit vaccine modal by updating state.
   */
  handleEditVaccineModalClose = () => {
    this.setState({
      showEditVaccineModal: false,
      editRow: null,
    });
  };

  /**
   * Closes the EditVaccine modal and makes a request to update an existing vaccine record.
   * @param {*} updatedVaccineData - State from vaccine modal containing updated vaccine data.
   */
  handleEditVaccineModalSave = updatedVaccineData => {
    const currVaccineId = this.state.table.rowData[this.state.editRow]?.id;

    this.setState(
      {
        showEditVaccineModal: false,
        editRow: null,
      },
      () => {
        this.editVaccine(updatedVaccineData, currVaccineId);
      }
    );
  };

  /**
   * Makes a request to update an existing vaccine record on the backend and reloads page once complete.
   * @param {*} newVaccineData
   */
  editVaccine = (updatedVaccineData, currVaccineId) => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;

    axios
      .put(`${window.BASE_PATH}/vaccines/${currVaccineId}`, {
        group_name: updatedVaccineData.group_name,
        product_name: updatedVaccineData.product_name,
        administration_date: updatedVaccineData.administration_date,
        dose_number: updatedVaccineData.dose_number,
        notes: updatedVaccineData.notes,
        patient_id: this.props.patient.id,
      })
      .then(() => {
        // Refresh the page to see the updated table data
        location.reload();
      })
      .catch(err => {
        reportError(err?.response?.data?.error ? err.response.data.error : err, false);
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
        <Dropdown.Toggle id={`vaccine-action-button-${rowData.id}`} size="sm" variant="primary" aria-label={`vaccine-action-button-${rowData.id}`}>
          <i className="fas fa-cogs fw"></i>
        </Dropdown.Toggle>
        <Dropdown.Menu className="test-class" drop={'up'}>
          <Dropdown.Item className="px-4 hi" onClick={() => this.handleEditVaccineClick(rowIndex)}>
            <i className="fas fa-edit fa-fw"></i>
            <span className="ml-2">Edit</span>
          </Dropdown.Item>
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  /**
   * Gets the data for the current vaccine if there is one selected/being edited.
   */
  getCurrVaccine = () => {
    return this.state.editRow !== null && !!this.state.table.rowData ? this.state.table.rowData[this.state.editRow] : {};
  };

  render() {
    return (
      <React.Fragment>
        <Card id="vaccines-table" className="mx-2 mt-3 mb-4 card-square">
          <Card.Header className="h5">Vaccinations</Card.Header>
          <Card.Body>
            <div className="mt-4">
              <Row className="my-4">
                <Col>
                  <Button variant="primary" className="mr-2" onClick={this.handleAddVaccineClick}>
                    <i className="fas fa-plus fa-fw"></i>
                    <span className="ml-2">Add New Vaccination</span>
                  </Button>
                </Col>
                <Col lg={5}>
                  <InputGroup size="md">
                    <InputGroup.Prepend>
                      <OverlayTrigger overlay={<Tooltip>Search by ID, Group Name, or Product Name.</Tooltip>}>
                        <InputGroup.Text className="rounded-0">
                          <i className="fas fa-search"></i>
                          <label htmlFor="vaccines-search-input" className="ml-1 mb-0">
                            Search
                          </label>
                        </InputGroup.Text>
                      </OverlayTrigger>
                    </InputGroup.Prepend>
                    <Form.Control
                      id="vaccines-search-input"
                      autoComplete="off"
                      size="md"
                      name="search"
                      onChange={this.handleSearchChange}
                      aria-label="Search"
                    />
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
                />
              </div>
            </div>
          </Card.Body>
        </Card>
        {(this.state.showAddVaccineModal || this.state.showEditVaccineModal) && (
          <VaccineModal
            title={this.state.showAddVaccineModal ? 'Add New Vaccination' : 'Edit Vaccination'}
            currentVaccineData={this.state.showAddVaccineModal ? {} : this.getCurrVaccine()}
            onClose={this.state.showAddVaccineModal ? this.handleAddVaccineModalClose : this.handleEditVaccineModalClose}
            onSave={this.state.showAddVaccineModal ? this.handleAddVaccineModalSave : this.handleEditVaccineModalSave}
            isEditing={this.state.showEditVaccineModal}
            vaccine_mapping={this.props.vaccine_mapping}
            group_name_options={this.props.group_name_options ? this.props.group_name_options : []}
            additional_product_name_options={this.props.additional_product_name_options}
            dose_number_options={this.props.dose_number_options}
          />
        )}
      </React.Fragment>
    );
  }
}

VaccineTable.propTypes = {
  patient: PropTypes.object,
  current_user: PropTypes.object,
  authenticity_token: PropTypes.string,
  vaccine_mapping: PropTypes.object,
  group_name_options: PropTypes.array,
  additional_product_name_options: PropTypes.array,
  dose_number_options: PropTypes.array,
};

export default VaccineTable;
