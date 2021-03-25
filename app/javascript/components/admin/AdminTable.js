import React from 'react';
import PropTypes from 'prop-types';
import { Button, ButtonGroup, Col, Dropdown, DropdownButton, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';
import 'react-toastify/dist/ReactToastify.css';
import UserModal from './UserModal';
import EmailModal from './EmailModal';
import AuditModal from './AuditModal';
import confirmDialog from '../util/ConfirmDialog';
import axios from 'axios';
import _ from 'lodash';
import { CSVLink } from 'react-csv';
import CustomTable from '../layout/CustomTable';
import { ToastContainer, toast } from 'react-toastify';

class AdminTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Id', field: 'id', isSortable: true },
          { label: 'Email', field: 'email', className: 'wrap', isSortable: true },
          { label: 'Jurisdiction', field: 'jurisdiction_path', isSortable: true },
          { label: 'Role', field: 'role_title', isSortable: false },
          { label: 'Status', field: 'is_locked', isSortable: false, options: { true: 'Locked', false: 'Unlocked' } },
          { label: 'API Enabled', field: 'is_api_enabled', isSortable: false, options: { true: 'Yes', false: 'No' } },
          { label: '2FA Enabled', field: 'is_2fa_enabled', isSortable: false, options: { true: 'Yes', false: 'No' } },
          { label: 'Failed Login Attempts', field: 'num_failed_logins', isSortable: true },
          { label: 'Audit', field: 'Audit', isSortable: false, tooltip: null, filter: this.createAuditButton, onClick: this.handleAuditClick },
        ],
        rowData: [],
        totalRows: 0,
        selectedRows: [],
        selectAll: false,
      },
      query: {
        page: 0,
        search: '',
        entries: 25,
        locked: null,
      },
      allUsersCount: null,
      entryOptions: [10, 15, 25, 50, 100],
      showEditUserModal: false,
      showAuditModal: false,
      showAddUserModal: false,
      showEmailAllModal: false,
      actionsEnabled: false,
      cancelToken: axios.CancelToken.source(),
      isLoading: false,
      editRow: null,
      auditRow: null,
      csvData: [],
      jurisdiction_paths: {},
    };
    // Ref for the CSVLink component used to click it when async data fetch has completed
    this.csvLink = React.createRef();
  }

  /**
   * Creates a "Audit" button for each row of the table.
   * @param {Object} rowData - Data about the cell this filter is called on.
   */
  createAuditButton(data) {
    const rowData = data.rowData;
    return (
      <div id={rowData.id} className="float-left edit-button" aria-label="Open Audit Modal Row Button">
        <i className="fas fa-user-clock"></i>
      </div>
    );
  }

  getRowCheckboxAriaLabel(rowData) {
    return `User: ${rowData.email}`;
  }

  componentDidMount() {
    // Update table data on initial mount.
    this.getTableData(this.state.query, true);

    // Gets jurisdiction path options on initial mount.
    this.getJurisdictionPaths();
  }

  componentDidUpdate() {
    /**
     * This check is necessary due to a bug with react-csv where it cannot currently handle async onClick events despite
     * claiming support. Read about this error (and solutions that inspired this) here:
     * https://github.com/react-csv/react-csv/issues/189
     * PR to solve issue is open here: https://github.com/react-csv/react-csv/pull/201
     * Once this PR is merged, we can just use the asyncOnClick and onClick props on CSVLink rather
     * than having to use a ref and manually click the element.
     */
    if (this.state.csvData.length && this.csvLink.current && this.csvLink.current.link) {
      // Trigger click on next event cycle
      setTimeout(() => {
        this.csvLink.current.link.click();
        this.setState({ csvData: [] });
      });
    }
  }

  /**
   * Makes an axios POST request based on input.
   * @param {String} path - Admin route to POST to (after the /admin/ string)
   * @param {Object} data  - Data to send in POST.
   * @param {Function} handleSuccess - Success callback.
   * @param {Function} handleError  - Error callback.
   */
  axiosAdminPostRequest = (path, data, handleSuccess, handleError) => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/admin/' + path, data)
      .then(handleSuccess)
      .catch(handleError);
  };

  /**
   * Makes an axios GET request based on input.
   * @param {String} path - Admin route to POST to (after the /admin/ string)
   * @param {Object} params - Params to send along in request.
   * @param {Function} handleSuccess - Success callback.
   * @param {Function} handleError  - Error callback.
   * @param {Boolean} isLoading - Desired value of isLoading in state.
   */
  axiosAdminGetRequest = (path, params, handleSuccess, handleError, isLoading) => {
    // Cancel any previous unfinished requests to prevent race condition inconsistencies and
    // generate new cancel token for this request.
    this.state.cancelToken.cancel();
    const cancelToken = axios.CancelToken.source();

    this.setState({ cancelToken, isLoading }, () => {
      axios
        .get(window.BASE_PATH + '/admin/' + path, {
          params: params,
          cancelToken: this.state.cancelToken.token,
        })
        .then(handleSuccess)
        .catch(handleError);
    });
  };

  /**
   * Called when the audit button is clicked on a given row.
   * Updates the state to show the appropriate modal for auditing a user and the the current row being audited.
   */
  handleAuditClick = user_id => {
    this.setState({
      showAuditModal: true,
      auditRow: this.state.table.rowData.find(u => u.id == user_id),
    });
  };

  /**
   * Gets the jurisdictions path options via an axios GET request.
   */
  getJurisdictionPaths() {
    axios.get(window.BASE_PATH + '/jurisdictions/paths').then(response => {
      const responseData = response.data.jurisdiction_paths;

      // Swap keys and values for ease of use
      let jurisdiction_paths = Object.assign({}, ...Object.entries(responseData).map(([id, path]) => ({ [path]: parseInt(id) })));

      this.setState({ jurisdiction_paths });
    });
  }

  /**
   * Queries the backend with passed in query data and updates the table data stored in local state.
   * @param {Object} query - Optional query data handled in route for determining the data returned.
   * @param {Boolean} initialLoad - Only true when method is called from componentDidMount to store the total number of users (no filters applied)
   */
  getTableData = (query, initialLoad) => {
    const path = 'users';
    const params = { ...query };
    const handleSuccess = response => {
      if (response && response.data && response.data.user_rows) {
        // If there's a valid response, update state accordingly
        this.setState(
          state => {
            return {
              table: { ...state.table, selectedRows: [], selectAll: false, rowData: response.data.user_rows, totalRows: response.data.total },
              isLoading: false,
              actionsEnabled: false,
            };
          },
          () => {
            if (initialLoad) {
              this.setState({ allUsersCount: response.data.total });
            }
          }
        );
      } else {
        // If the response doesn't have the expected data, don't update table data
        this.setState(state => {
          return {
            table: { ...state.table, selectedRows: [], selectAll: false },
            isLoading: false,
            actionsEnabled: false,
          };
        });
      }
    };

    const handleError = error => {
      // If there was an error, but it wasn't due to a cancellation
      if (!axios.isCancel(error)) {
        this.setState(state => {
          return {
            table: { ...state.table, rowData: [], totalRows: 0 },
            isLoading: false,
          };
        });
        console.log(error);
      }
    };
    this.axiosAdminGetRequest(path, params, handleSuccess, handleError, true);
  };

  /**
   * Called when the Add User button is clicked.
   * Updates the state to show the appropriate modal for adding a user.
   */
  handleAddUserClick = () => {
    this.setState({
      showAddUserModal: true,
      editRow: null,
    });
  };

  /**
   * Called when the edit button is clicked on a given row.
   * Updates the state to show the appropriate modal for editing a user and the the current row being edited.
   */
  handleEditClick = row => {
    this.setState({
      showEditUserModal: true,
      editRow: row,
    });
  };

  /**
   * Closes the user modal by updating state.
   */
  handleUserModalClose = () => {
    this.setState({
      showEditUserModal: false,
      showAddUserModal: false,
      editRow: null,
    });
  };

  /**
   * Closes the user audit modal by updating state.
   */
  handleAuditModalClose = () => {
    this.setState({
      showAuditModal: false,
      editRow: null,
    });
  };

  /**
   * Closes user modal and either saves a new user if the modal was for adding a user
   * or updates an existing one otherwise.
   * @param {Boolean} isNewUser - True if this is a new user being asv
   * @param {Obejct} formData - Data submitted via the modal form.
   */
  handleUserModalSave = (isNewUser, formData) => {
    if (isNewUser) {
      this.addUser(formData);
    } else {
      this.editUser(this.state.editRow, formData);
    }
    this.handleUserModalClose();
  };

  /**
   * Makes POST request to admin/create_use to add a new user to backend.
   * @param {Object} data
   */
  addUser = data => {
    const path = 'create_user';

    const dataToSend = {
      email: data.email,
      jurisdiction: this.state.jurisdiction_paths[data.jurisdiction_path],
      role_title: data.roleTitle,
      is_api_enabled: data.isAPIEnabled,
    };

    const handleSuccess = () => {
      toast.success('Successfully added new user.', {
        position: toast.POSITION.TOP_CENTER,
      });
      this.getTableData(this.state.query);
    };

    const handleError = error => {
      toast.error('Failed to add new user. Please verify email is valid.', {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosAdminPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Makes POST request to admin/edit_user to update an existing user on the backend.
   * @param {Number} row - Row being edited.
   * @param {Object} data - Form data from edit user modal.
   */
  editUser = (row, data) => {
    const path = 'edit_user';

    const dataToSend = {
      id: this.state.table.rowData[parseInt(row)].id,
      email: data.email,
      jurisdiction: this.state.jurisdiction_paths[data.jurisdiction_path],
      role_title: data.roleTitle,
      is_api_enabled: data.isAPIEnabled,
      is_locked: data.isLocked,
    };

    const handleSuccess = () => {
      this.getTableData(this.state.query);
    };

    const handleError = error => {
      toast.error('Failed to edit user. Please verify email is valid.', {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosAdminPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Called when the Send Email to All button is clicked.
   * Updates the state appropriately to show the modal.
   */
  handleEmailAllClick = () => {
    this.setState({
      showEmailAllModal: true,
    });
  };

  /**
   * Called when the email action modal cancel or X button is clicked.
   * Updates the state appropriately to hide the modal.
   */
  handleEmailModalClose = () => {
    this.setState({
      showEmailAllModal: false,
    });
  };

  /**
   * Closes email modal and send emails to ALL users admin has access to with POST request.
   * @param {Object} data - Data submitted from the email modal.
   */
  handleEmailAllSave = data => {
    this.handleEmailModalClose();

    const path = 'email_all';
    const dataToSend = {
      comment: data.comment,
    };

    const handleSuccess = () => {
      toast.success('Successfully sent emails to all users.', {
        position: toast.POSITION.TOP_CENTER,
      });
    };

    const handleError = error => {
      toast.error('Failed to send emails.', {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosAdminPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Called when table is to be updated because of a search or sorting change.
   * @param {Object} query - Updated query for table data after change.
   */
  handleTableUpdate = query => {
    this.setState(
      state => ({
        query: { ...state.query, ...query },
      }),
      () => {
        this.getTableData(this.state.query);
      }
    );
  };

  /**
   * Callback called when child Table component detects a selection change.
   * Updates the selected rows and enables/disables actions accordingly.
   * @param {Number[]} selectedRows - Array of selected row indices.
   */
  handleSelect = selectedRows => {
    // All rows are selected if the number selected is the max number shown or the total number of rows completely
    const selectAll = selectedRows.length >= this.state.query.entries || selectedRows.length >= this.state.table.totalRows;
    this.setState(state => {
      return {
        actionsEnabled: selectedRows.length > 0,
        table: { ...state.table, selectedRows, selectAll },
      };
    });
  };

  /**
   * Called when the number of entries to be shown on a page changes. Resets page to 0.
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
        this.getTableData(this.state.query);
      }
    );
  };

  /**
   * Called when all/unlocked/locked buttoned are toggled.
   * Updates state and then calls table update handler.
   * @param Boolean locked - true if locked, false if unlocked, null if all
   */
  handleLockedChange = locked => {
    this.setState(
      state => {
        return {
          query: { ...state.query, locked, page: 0 },
        };
      },
      () => {
        this.getTableData(this.state.query);
      }
    );
  };

  /**
   * Called when Export to CSV button is clicked.
   * Fetches all user data for export to CSV and then updates state which triggers the CSVLink
   * component to be clicked via ref.
   */
  getCSVData = () => {
    const path = 'users';

    // Get all the users at once for a full export
    const params = { entries: this.state.allUsersCount, page: 0 };

    const handleSuccess = response => {
      if (response && response.data && response.data.user_rows) {
        // NOTE: react-csv has a bug where false values don't show up in the downloaded CSV
        // This has been addressed and recently merged: https://github.com/react-csv/react-csv/pull/193
        // Once this gets released and we update our version this code won't be necessary.
        const csvData = response.data.user_rows.map(userData => {
          return {
            ...userData,
            is_api_enabled: userData.is_api_enabled.toString(),
            is_2fa_enabled: userData.is_2fa_enabled.toString(),
            is_locked: userData.is_locked.toString(),
          };
        });
        // If there's a valid response, update state accordingly
        this.setState({ csvData });
      } else {
        toast.error('Failed to export data.', {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        console.log(`Export was not successful with the following response: ${response}`);
      }
    };

    const handleError = error => {
      toast.error('Failed to export data.', {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosAdminGetRequest(path, params, handleSuccess, handleError, false);
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
        this.getTableData(this.state.query);
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
          table: { ...state.table, selectedRows: [] },
        };
      },
      () => {
        this.getTableData(this.state.query);
      }
    );
  };

  /**
   * Called when the reset password action is clicked.
   * Opens a confirmation modal and calls method to reset password for selected users if confirmed.
   */
  handleResetPasswordClick = async () => {
    const confirmText = `Are you sure you would like to reset the password(s) of ${this.state.table.selectedRows.length} user(s)?`;
    const options = {
      title: 'Reset Password(s)',
      okLabel: 'Confirm',
      cancelLabel: 'Cancel',
    };
    if (await confirmDialog(confirmText, options)) {
      this.handleResetPasswords();
    }
  };

  /**
   * Called when the reset 2FA action is clicked.
   * Opens a confirmation modal and calls method to reset 2FA for selected users if confirmed.
   */
  handleReset2FAClick = async () => {
    const confirmText = `Are you sure you would like to reset two-factor authentication for ${this.state.table.selectedRows.length} user(s)?`;
    const options = {
      title: 'Reset Two-Factor Authentication',
      okLabel: 'Confirm',
      cancelLabel: 'Cancel',
    };
    if (await confirmDialog(confirmText, options)) {
      this.handleReset2FA();
    }
  };

  /**
   * Called when the user confirms the password reset action.
   * Makes a POST request to reset the password of all selected users.
   */
  handleResetPasswords = () => {
    const path = 'reset_password';
    const ids = this.state.table.selectedRows.map(row => {
      return this.state.table.rowData[parseInt(row)].id;
    });
    const dataToSend = {
      ids: ids,
    };

    const handleSuccess = () => {
      toast.success(`Password reset for ${this.state.table.selectedRows.length} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
    };

    const handleError = error => {
      toast.error(`Failed to reset password for ${this.state.table.selectedRows.length} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosAdminPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Called when the user confirms the 2FA reset action.
   * Makes a POST request to reset 2FA for all selected users.
   */
  handleReset2FA = () => {
    const path = 'reset_2fa';
    const ids = this.state.table.selectedRows.map(row => {
      return this.state.table.rowData[parseInt(row)].id;
    });
    const dataToSend = {
      ids: ids,
    };

    const handleSuccess = () => {
      toast.success(`Two-factor authentication reset for ${this.state.table.selectedRows.length} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
    };

    const handleError = error => {
      toast.error(`Failed to reset Two-factor Authentication for ${this.state.table.selectedRows.length} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosAdminPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  render() {
    return (
      <div className="mx-2">
        <h1 className="sr-only">Admin Dashboard</h1>
        <Row id="admin-table-header" className="mb-1">
          <Col xl={24} className="col-xxl-14 px-1">
            <Button className="mr-2 mb-2" size="md" onClick={this.handleAddUserClick}>
              <i className="fas fa-plus-circle"></i>
              &nbsp;Add User
            </Button>
            <Button className="mr-2 mb-2" size="md" onClick={this.getCSVData}>
              <i className="fas fa-download"></i>
              &nbsp;Export All to CSV
            </Button>
            {this.props.is_usa_admin && (
              <Button className="mr-2 mb-2" size="md" onClick={this.handleEmailAllClick}>
                <i className="fas fa-envelope"></i>
                &nbsp;Email All Unlocked Users
              </Button>
            )}
            {this.state.csvData.length > 0 ? <CSVLink data={this.state.csvData} filename={'sara-accounts.csv'} ref={this.csvLink} /> : undefined}
            <ButtonGroup className="float-right mb-2">
              <Button
                id="admin-table-all-filter-btn"
                variant={_.isNil(this.state.query.locked) ? 'primary' : 'outline-primary'}
                onClick={() => {
                  this.handleLockedChange(null);
                }}>
                All
              </Button>
              <Button
                id="admin-table-unlocked-filter-btn"
                variant={!_.isNil(this.state.query.locked) && !this.state.query.locked ? 'primary' : 'outline-primary'}
                onClick={() => {
                  this.handleLockedChange(false);
                }}>
                Unlocked
              </Button>
              <Button
                id="admin-table-locked-filter-btn"
                variant={!_.isNil(this.state.query.locked) && this.state.query.locked ? 'primary' : 'outline-primary'}
                onClick={() => {
                  this.handleLockedChange(true);
                }}>
                Locked
              </Button>
            </ButtonGroup>
          </Col>
          <Col xl={24} className="col-xxl-10 mb-2 px-1">
            <InputGroup>
              <InputGroup.Prepend>
                <OverlayTrigger overlay={<Tooltip>Search by id, email, or jurisdiction.</Tooltip>}>
                  <InputGroup.Text className="rounded-0">
                    <i className="fas fa-search"></i>
                    <span className="ml-1">Search</span>
                  </InputGroup.Text>
                </OverlayTrigger>
              </InputGroup.Prepend>
              <Form.Control
                id="search-input"
                autoComplete="off"
                size="md"
                name="search"
                value={this.state.query.search}
                onChange={this.handleSearchChange}
                aria-label="Search"
              />
              <DropdownButton
                size="md"
                variant="primary"
                title={
                  <React.Fragment>
                    <i className="fas fa-tools"></i> Actions{' '}
                  </React.Fragment>
                }
                className="ml-2"
                disabled={!this.state.actionsEnabled}>
                <Dropdown.Item className="px-3" onClick={this.handleResetPasswordClick}>
                  <i className="fas fa-undo"></i>
                  <span className="ml-2">Reset Password</span>
                </Dropdown.Item>
                <Dropdown.Item className="px-3" onClick={this.handleReset2FAClick}>
                  <i className="fas fa-key"></i>
                  <span className="ml-2">Reset 2FA</span>
                </Dropdown.Item>
              </DropdownButton>
            </InputGroup>
          </Col>
        </Row>
        <CustomTable
          columnData={this.state.table.colData}
          rowData={this.state.table.rowData}
          totalRows={this.state.table.totalRows}
          handleTableUpdate={this.handleTableUpdate}
          handleSelect={this.handleSelect}
          handleEdit={this.handleEditClick}
          handleEntriesChange={this.handleEntriesChange}
          handlePageUpdate={this.handlePageUpdate}
          getRowCheckboxAriaLabel={this.getRowCheckboxAriaLabel}
          isSelectable={true}
          isEditable={true}
          isLoading={this.state.isLoading}
          page={this.state.query.page}
          selectedRows={this.state.table.selectedRows}
          selectAll={this.state.table.selectAll}
          entryOptions={this.state.entryOptions}
          entries={this.state.query.entries}
        />
        {Object.keys(this.state.jurisdiction_paths).length && (this.state.showEditUserModal || this.state.showAddUserModal) && (
          <UserModal
            show={this.state.showEditUserModal || this.state.showAddUserModal}
            onSave={formData => this.handleUserModalSave(this.state.showAddUserModal, formData)}
            onClose={this.handleUserModalClose}
            title={this.state.showEditUserModal ? 'Edit User' : 'Add User'}
            type={this.state.showEditUserModal ? 'edit' : 'add'}
            jurisdiction_paths={Object.keys(this.state.jurisdiction_paths)}
            roles={this.props.role_types}
            initialUserData={this.state.editRow === null ? {} : this.state.table.rowData[this.state.editRow]}
          />
        )}
        {this.state.showAuditModal && (
          <AuditModal
            show={this.state.showAuditModal}
            onClose={this.handleAuditModalClose}
            user={this.state.auditRow === null ? {} : this.state.auditRow}
            authenticity_token={this.props.authenticity_token}
          />
        )}
        {this.state.showEmailAllModal && (
          <EmailModal
            show={this.state.showEmailAllModal}
            title={'Send Email to All Unlocked Users'}
            onClose={this.handleEmailModalClose}
            onSave={this.handleEmailAllSave}
            prompt={'Enter the message to send to all unlocked users:'}
          />
        )}
        <ToastContainer position="top-center" autoClose={2000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </div>
    );
  }
}

AdminTable.propTypes = {
  authenticity_token: PropTypes.string,
  role_types: PropTypes.array,
  is_usa_admin: PropTypes.bool,
};

export default AdminTable;
