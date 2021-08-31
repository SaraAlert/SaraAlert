import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Dropdown, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';

import { formatDate } from '../../../utils/DateTime';
import { formatPhoneNumberVisually, phoneNumberToE164Format } from '../../../utils/Patient';

import axios from 'axios';
import _ from 'lodash';

import { patientHref, navQueryParam } from '../../../utils/Navigation';
import InfoTooltip from '../../util/InfoTooltip';
import CloseContactModal from './CloseContactModal';
import confirmDialog from '../../util/ConfirmDialog';
import CustomTable from '../../layout/CustomTable';
import reportError from '../../util/ReportError';
import DeleteDialog from '../../util/DeleteDialog';

class CloseContactTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Actions', field: '', isSortable: false, className: 'text-center', filter: this.renderActionsDropdown },
          { label: 'First Name', field: 'first_name', isSortable: true },
          { label: 'Last Name', field: 'last_name', isSortable: true },
          { label: 'Phone Number', field: 'primary_telephone', isSortable: true, filter: d => formatPhoneNumberVisually(d.value) },
          { label: 'Email', field: 'email', isSortable: true },
          { label: 'Last Date of Exposure', field: 'last_date_of_exposure', isSortable: true, filter: formatDate },
          { label: 'Assigned User', field: 'assigned_user', isSortable: true },
          { label: 'Contact Attempts', field: 'contact_attempts', isSortable: true, filter: v => (v.value ? v.value : '0') },
          { label: 'Enrolled?', field: 'enrolled_id', isSortable: true, filter: v => (v.value ? 'Yes' : 'No') },
          // Lodash's `truncate` includes an ellipses, and will only fire when the length is greater than `length`
          // However, it throws a false-positive for our linter (which thinks we're calling fs.truncate)
          /* eslint-disable security/detect-non-literal-fs-filename */
          { label: 'Notes', field: 'notes', isSortable: true, filter: v => _.truncate(v.value, { length: 503 }) },
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
      activeRow: null,
      showEditModal: false,
      showAddModal: false,
      showDeleteModal: false,
      delete_reason: null,
      delete_reason_text: null,
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
      .get('/close_contacts', {
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
   * Gets the data for the current close contact if there is one selected/being edited.
   */
  getCurrentCloseContact = () => {
    return this.state.activeRow !== null && !!this.state.table.rowData ? this.state.table.rowData[this.state.activeRow] : {};
  };

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
   * Called when the user clicks on the Contact Attempt for a Close Contact
   */
  handleContactAttempt = async data => {
    if (await confirmDialog('Are you sure you want to log an additional contact attempt?', { title: 'New Contact Attempt' })) {
      let currentCC = _.cloneDeep(this.state.table.rowData[`${data}`]);
      currentCC['contact_attempts'] = currentCC['contact_attempts'] + 1;
      this.setState(
        {
          showEditModal: false,
          activeRow: null,
        },
        () => {
          this.updateCloseContact(currentCC, true);
        }
      );
    }
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
   * Toggle the Add New Close Contact modal by updating state.
   */
  toggleAddModal = () => {
    this.setState({
      showAddModal: !this.state.showAddModal,
    });
  };

  /**
   * Closes the Add New Close Contact modal and makes a request to add a new close contact to the db.
   * @param {*} newCloseContactData - State from close contact modal containing needed close contact data.
   */
  handleAddSubmit = newCloseContactData => {
    this.updateCloseContact(newCloseContactData, false);
  };

  /**
   * Called when the edit close contact button is clicked.
   * Updates the state to show the appropriate modal for editing a close contact.
   */
  toggleEditModal = row => {
    this.setState({
      showEditModal: !this.state.showEditModal,
      activeRow: row,
    });
  };

  /**
   * Closes the Edit Close Contact modal and makes a request to update an existing close contact record.
   * @param {*} updatedCloseContactData - State from close contact modal containing updated close contact data.
   */
  handleEditSubmit = updatedCloseContactData => {
    const currentCloseContactId = this.state.table.rowData[this.state.activeRow]?.id;
    updatedCloseContactData['id'] = currentCloseContactId;
    this.updateCloseContact(updatedCloseContactData, true);
  };

  // Toggles the delete modal and clears any reason or reason text
  toggleDeleteModal = row => {
    this.setState({
      activeRow: row,
      showDeleteModal: !this.state.showDeleteModal,
      delete_reason: null,
      delete_reason_text: null,
    });
  };

  handleDeleteSubmit = () => {
    let delete_reason = this.state.delete_reason;
    if (delete_reason === 'Other' && this.state.delete_reason_text) {
      delete_reason += ', ' + this.state.delete_reason_text;
    }
    const currentCloseContactId = this.state.table.rowData[this.state.activeRow]?.id;
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .delete(`${window.BASE_PATH}/close_contacts/${currentCloseContactId}`, {
          data: {
            patient_id: this.props.patient.id,
            delete_reason,
          },
        })
        .then(() => {
          location.reload();
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  handleDeleteUpdate = event => {
    if (['delete_reason', 'delete_reason_text'].includes(event?.target?.id)) {
      this.setState({ [event.target.id]: event?.target?.value });
    }
  };

  /**
   * Makes a request to update an existing close contact record on the backend and reloads page once complete.
   * @param {*} newCloseContactData
   * @param {*} isEdit - whether this is an edit or a new close contact
   */
  updateCloseContact = (ccData, isEdit) => {
    this.setState({ isLoading: true }, () => {
      let url = `${window.BASE_PATH}/close_contacts`;
      if (isEdit) {
        url += `/${ccData.id}`;
      }
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(url, {
          patient_id: this.props.patient.id,
          first_name: ccData.first_name || '',
          last_name: ccData.last_name || '',
          primary_telephone: ccData.primary_telephone ? phoneNumberToE164Format(ccData.primary_telephone) : '',
          email: ccData.email || '',
          last_date_of_exposure: ccData.last_date_of_exposure || null,
          assigned_user: ccData.assigned_user || null,
          notes: ccData.notes || '',
          enrolled_id: ccData.enrolled_id || null,
          contact_attempts: ccData.contact_attempts || 0,
        })
        .then(() => {
          location.reload();
        })
        .catch(error => {
          this.setState({ isLoading: false });
          reportError(error);
        });
    });
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
    const direction = this.state.table.rowData && this.state.table.rowData.length > 4 ? null : 'up';
    return (
      <Dropdown drop={direction}>
        <Dropdown.Toggle
          id={`close-contact-action-button-${rowData.id}`}
          size="sm"
          variant="primary"
          aria-label={`Close Contact Action Button for Close Contact ${rowData.id}`}>
          <i className="fas fa-cogs fw" />
        </Dropdown.Toggle>
        <Dropdown.Menu drop={direction}>
          <Dropdown.Item className="px-4" onClick={() => this.toggleEditModal(rowIndex)}>
            <i className="fas fa-edit fa-fw" />
            <span className="ml-2"> Edit</span>
          </Dropdown.Item>
          <Dropdown.Item className="px-4" onClick={() => this.handleContactAttempt(rowIndex)}>
            <i className="fas fa-phone fa-flip-horizontal" />
            <span className="ml-2">Contact Attempt</span>
          </Dropdown.Item>
          {rowData.enrolled_id && (
            <Dropdown.Item className="px-4" onClick={() => (location.href = patientHref(rowData.enrolled_id, this.props.workflow))}>
              <i className="fas fa-search" />
              <span className="ml-2">View Record</span>
            </Dropdown.Item>
          )}
          {!rowData.enrolled_id && this.props.can_enroll_close_contacts && (
            <Dropdown.Item
              className="px-4"
              onClick={() => (location.href = `${window.BASE_PATH}/patients/new?cc=${rowData.id}${navQueryParam(this.props.workflow, false)}`)}>
              <i className="fas fa-plus" />
              <span className="ml-2"> Enroll</span>
            </Dropdown.Item>
          )}
          <Dropdown.Item className="px-4" onClick={() => this.toggleDeleteModal(rowIndex)}>
            <i className="fas fa-trash" />
            <span className="ml-2"> Delete</span>
          </Dropdown.Item>
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 my-4 card-square">
          <Card.Header as="h1" className="patient-card-header">
            Close Contacts <InfoTooltip tooltipTextKey="closeContacts" location="right" />
          </Card.Header>
          <Card.Body className="my-1">
            <Row className="mb-4">
              <Col>
                <Button variant="primary" className="mr-2" onClick={() => this.toggleAddModal()}>
                  <i className="fas fa-plus fa-fw"></i>
                  <span className="ml-2">Add New Close Contact</span>
                </Button>
              </Col>
              <Col xl={6} lg={10} md={12}>
                <InputGroup size="md" className="mt-3 mt-md-0 ">
                  <InputGroup.Prepend>
                    <OverlayTrigger overlay={<Tooltip>Search by First Name, Last Name, Phone Number, Email, Assigned User, or Contact Attempts.</Tooltip>}>
                      <InputGroup.Text className="rounded-0">
                        <i className="fas fa-search"></i>
                        <label
                          htmlFor="close-contact-search-input"
                          className="ml-2 mb-0"
                          aria-label="Search Close Contact Table by First Name, Last Name, Phone Number, Email, Assigned User, or Contact Attempts.">
                          Search
                        </label>
                      </InputGroup.Text>
                    </OverlayTrigger>
                  </InputGroup.Prepend>
                  <Form.Control
                    id="close-contact-search-input"
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
              dataType="close-contacts"
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
            />
          </Card.Body>
        </Card>
        {this.state.showDeleteModal && (
          <DeleteDialog
            type={'Close Contact'}
            delete={this.handleDeleteSubmit}
            toggle={this.toggleDeleteModal}
            onChange={this.handleDeleteUpdate}
            show_text_input={true}
          />
        )}
        {(this.state.showAddModal || this.state.showEditModal) && (
          <CloseContactModal
            title={this.state.showAddModal ? 'Add New Close Contact' : 'Edit Close Contact'}
            currentCloseContact={this.state.showAddModal ? {} : this.getCurrentCloseContact()}
            onClose={this.state.showAddModal ? this.toggleAddModal : this.toggleEditModal}
            onSave={this.state.showAddModal ? this.handleAddSubmit : this.handleEditSubmit}
            isEditing={this.state.showEditModal}
            assigned_users={this.props.assigned_users}
          />
        )}
      </React.Fragment>
    );
  }
}

CloseContactTable.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  assigned_users: PropTypes.array,
  can_enroll_close_contacts: PropTypes.bool,
  workflow: PropTypes.string,
};

export default CloseContactTable;
