import React from 'react';
import PropTypes from 'prop-types';
import { Button, DropdownButton, Dropdown, InputGroup, Form, OverlayTrigger, Tooltip } from 'react-bootstrap';
import 'react-toastify/dist/ReactToastify.css';
import UserModal from './UserModal';
import EmailModal from './EmailModal';
import ConfirmationModal from '../layout/ConfirmationModal';
import axios from 'axios';
import { CSVLink } from 'react-csv';
import ActionTable from '../layout/ActionTable';
import { ToastContainer, toast } from 'react-toastify';

class AdminTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Id', field: 'id', isSortable: true },
          { label: 'email', field: 'email', isSortable: true },
          { label: 'Jurisdiction', field: 'jurisdiction_path', isSortable: true },
          { label: 'Role', field: 'role', isSortable: false },
          { label: 'Status', field: 'is_locked', isSortable: false, options: { true: 'Locked', false: 'Unlocked' } },
          { label: 'API Enabled', field: 'is_API_enabled', isSortable: false, options: { true: 'Yes', false: 'No' } },
          { label: '2FA Enabled', field: 'is_2FA_enabled', isSortable: false, options: { true: 'Yes', false: 'No' } },
          { label: 'Failed Login Attempts', field: 'num_failed_logins', isSortable: true },
        ],
        rowData: [],
        totalRows: 0,
        selectedRows: [],
      },
      query: {
        page: 0,
        search: '',
      },
      actions: {
        resetPassword: { name: 'Reset Password', title: 'Reset Password(s)' },
        resetTwoFactorAuth: { name: 'Reset 2FA', title: 'Reset Two-Factor Authentication' },
      },
      showEditUserModal: false,
      showAddUserModal: false,
      showEmailModal: false,
      showConfirmationModal: false,
      actionsEnabled: false,
      cancelToken: axios.CancelToken.source(),
      isLoading: false,
      editRow: null,
      currentAction: null,
      csvData: [],
    };
    // Ref for the CSVLink component used to click it when async data fetch has completed
    this.csvLink = React.createRef();
  }

  componentDidMount() {
    // Update table data on initial mount.
    this.getTableData(this.state.query);
  }

  componentDidUpdate() {
    /**
     * This check is necessary due to bug with react-csv where it cannot currently handle async onClick events despite
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
  axiosPostRequest = (path, data, handleSuccess, handleError) => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post('/admin/' + path, data)
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
  axiosGetRequest = (path, params, handleSuccess, handleError, isLoading) => {
    // Cancel any previous unfinished requests to prevent race condition inconsistencies and
    // generate new cancel token for this request.
    this.state.cancelToken.cancel();
    const cancelToken = axios.CancelToken.source();

    this.setState({ cancelToken, isLoading }, () => {
      axios
        .get('/admin/' + path, {
          params: params,
          cancelToken: this.state.cancelToken.token,
        })
        .then(handleSuccess)
        .catch(handleError);
    });
  };

  /**
   * Queries the backend with passed in query data and updates the table data stored in local state.
   * @param {Object} query - Optional query data handled in route for determining the data returned.
   */
  getTableData = query => {
    const path = 'users';
    const params = { ...query };
    const handleSuccess = response => {
      if (response && response.data && response.data.linelist) {
        // If there's a valid response, update state accordingly
        this.setState(state => {
          return {
            table: { ...state.table, rowData: response.data.linelist, totalRows: response.data.total },
            selectedRows: [],
            isLoading: false,
          };
        });
      } else {
        // If the response doesn't have the expected data, don't update table data
        this.setState({ selectedRows: [], isLoading: false });
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

    this.axiosGetRequest(path, params, handleSuccess, handleError, true);
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
   * Closes user modal and either saves a new user if the modal was for adding a user
   * or updates an existing one otherwise.
   * @param {Boolean} isNewUser - True if this is a new user being asv
   * @param {Obejct} formData - Data submitted via the modal form.
   */
  handleUserModalSave = (isNewUser, formData) => {
    this.handleUserModalClose();

    if (isNewUser) {
      this.addUser(formData);
    } else {
      this.editUser(formData);
    }
  };

  /**
   * Makes POST request to admin/create_use to add a new user to backend.
   * @param {Object} data
   */
  addUser = data => {
    const path = 'create_user';

    const dataToSend = {
      email: data.email,
      jurisdiction: this.props.jurisdiction_paths[data.jurisdictionPath],
      role: data.role,
      is_api_enabled: data.isAPIEnabled,
    };

    const handleSuccess = () => {
      this.getTableData(this.state.query);
    };

    const handleError = error => {
      alert('Error adding new user. New user not saved.');
      console.log(error);
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Makes POST request to admin/edit_user to update an existing user on the backend.
   * @param {Object} data
   */
  editUser = data => {
    const path = 'edit_user';

    const dataToSend = {
      email: data.email,
      jurisdiction: this.props.jurisdiction_paths[data.jurisdictionPath],
      role: data.role,
      is_api_enabled: data.isAPIEnabled,
      is_locked: data.isLocked,
    };

    const handleSuccess = () => {
      this.getTableData(this.state.query);
    };

    const handleError = error => {
      alert('Error editing new user. Changes not saved.');
      console.log(error);
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Called when the email action is selected.
   * Updates the state appropriately to show the modal.
   */
  handleEmailClick = () => {
    // Show edit user Modal
    this.setState({
      showEmailModal: true,
    });
  };

  /**
   * Called when the email action modal cancel or X button is clicked.
   * Updates the state appropriately to hide the modal.
   */
  handleEmailModalClose = () => {
    this.setState({
      showEmailModal: false,
    });
  };

  /**
   * Closes email modal and send emails to selected users with POST request.
   * @param {Object} data - Data submitted from the email modal.
   */
  handleEmailSave = data => {
    this.handleEmailModalClose();

    const path = 'email';
    const ids = this.state.table.selectedRows.map(row => {
      return this.state.table.rowData[parseInt(row)].id;
    });
    console.log;
    const dataToSend = {
      ids: ids,
      comment: data.comment,
    };

    const handleSuccess = () => {
      toast.success('Successfully sent email(s).', {
        position: toast.POSITION.TOP_CENTER,
      });
    };

    const handleError = error => {
      toast.error('Failed to send email(s).', {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Callback called when child Table component detects a selection change.
   * Updates the selected rows and enables/disables actions accordingly.
   * @param {Number[]} selectedRows - Array of selected row indices.
   */
  handleSelect = selectedRows => {
    this.setState(state => {
      return {
        actionsEnabled: selectedRows.length > 0,
        table: { ...state.table, selectedRows },
      };
    });
  };

  /**
   * Called when Export to CSV button is clicked.
   * Fetches all user data for export to CSV and then updates state which triggers the CSVLink
   * component to be clicked via ref.
   */
  getCSVData = () => {
    const path = 'users';

    // Get all the users at once for a full export
    const params = { entries: this.state.table.totalRows, page: 0 };

    const handleSuccess = response => {
      if (response && response.data && response.data.linelist) {
        // NOTE: react-csv has a bug where false values don't show up in the downloaded CSV
        // This has been addressed and recently merged: https://github.com/react-csv/react-csv/pull/193
        // Once this gets released and we update our version this code won't be necessary.
        const csvData = response.data.linelist.map(userData => {
          return {
            ...userData,
            isAPIEnabled: userData.isAPIEnabled.toString(),
            is2FAEnabled: userData.is2FAEnabled.toString(),
            isLocked: userData.isLocked.toString(),
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

    this.axiosGetRequest(path, params, handleSuccess, handleError, false);
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
        return { query: { ...state.query, page: page.selected } };
      },
      () => {
        this.getTableData(this.state.query);
      }
    );
  };

  /**
   * Called when a reset action is clicked.
   * Sets the state to show a confirmation modal and sets the currently selected action.
   * @param {String} currentAction - Current action that was clicked.
   */
  handleResetClick = currentAction => {
    this.setState({
      showConfirmationModal: true,
      currentAction,
    });
  };

  /**
   * Called when the confirmation modal cancel or X button is clicked.
   * Updates the state appropriately to hide the modal and reset the current action to null.
   */
  handleConfirmationModalClose = () => {
    this.setState({
      showConfirmationModal: false,
      currentAction: null,
    });
  };

  /**
   * Closes confirmatiom modal and executes currently selected action.
   */
  handleConfirmationSave = () => {
    this.handleConfirmationModalClose();
    switch (this.state.currentAction) {
      case this.state.actions.resetPassword.name:
        this.handleResetPasswords();
        break;
      case this.state.actions.resetTwoFactorAuth.name:
        this.handleReset2FA();
        break;
      default:
        console.log('No current action to execute.');
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
      toast.success(`Password reset for ${this.state.selectedRows} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
    };

    const handleError = error => {
      toast.error(`Failed to reset password for ${this.state.selectedRows} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
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
      toast.success(`Two-factor authentication reset for ${this.state.selectedRows} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
    };

    const handleError = error => {
      toast.error(`Failed to reset Two-factor Authentication for ${this.state.selectedRows} users.`, {
        autoClose: 2000,
        position: toast.POSITION.TOP_CENTER,
      });
      console.log(error);
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  /**
   * Gets the corresponding description for the confirmatiom model based on the input action.
   * @param {String} action - Action to get description for.
   */
  getActionDescription = action => {
    switch (action) {
      case this.state.actions.resetPassword.name:
        return `reset the passwords(s) of ${this.state.table.selectedRows.length} user(s)`;
      case this.state.actions.resetTwoFactorAuth.name:
        return `reset two-factor authentication for ${this.state.table.selectedRows.length} user(s)`;
      default:
        return '';
    }
  };

  render() {
    return (
      <div>
        <div className="d-flex justify-content-between mb-2">
          <div className="mb-1">
            <Button className="mx-1" size="lg" onClick={this.handleAddUserClick}>
              <i className="fas fa-plus-circle"></i>
              &nbsp;Add User
            </Button>
            <Button className="mx-1" size="lg" variant="secondary" onClick={this.getCSVData}>
              <i className="fas fa-download"></i>
              &nbsp;Export to CSV
            </Button>
            {this.state.csvData.length > 0 ? <CSVLink data={this.state.csvData} filename={'sara-accounts.csv'} ref={this.csvLink} /> : undefined}
          </div>
          <div>
            <InputGroup size="md">
              <InputGroup.Prepend>
                <OverlayTrigger overlay={<Tooltip>Search by id or email.</Tooltip>}>
                  <InputGroup.Text className="rounded-0">
                    <i className="fas fa-search"></i>
                    <span className="ml-1">Search</span>
                  </InputGroup.Text>
                </OverlayTrigger>
              </InputGroup.Prepend>
              <Form.Control autoComplete="off" size="md" name="search" value={this.state.query.search} onChange={this.handleSearchChange} />
              <DropdownButton
                size="md"
                variant="primary"
                title={
                  <React.Fragment>
                    <i className="fas fa-tools"></i> Actions{' '}
                  </React.Fragment>
                }
                className="ml-3"
                disabled={!this.state.actionsEnabled}>
                {this.state.query.tab !== 'closed' && (
                  <Dropdown.Item className="px-3" onClick={() => this.handleResetClick(this.state.actions.resetPassword.name)}>
                    <i className="fas fa-undo"></i>
                    <span className="ml-2">Reset Password</span>
                  </Dropdown.Item>
                )}
                <Dropdown.Item className="px-3" onClick={() => this.handleResetClick(this.state.actions.resetTwoFactorAuth.name)}>
                  <i className="fas fa-key"></i>
                  <span className="ml-2">Reset 2FA</span>
                </Dropdown.Item>
                {this.props.is_usa_admin && (
                  <Dropdown.Item className="px-3" onClick={this.handleEmailClick}>
                    <i className="fas fa-envelope"></i>
                    <span className="ml-2">Send Email</span>
                  </Dropdown.Item>
                )}
              </DropdownButton>
            </InputGroup>
          </div>
        </div>

        <ActionTable
          columnData={this.state.table.colData}
          rowData={this.state.table.rowData}
          totalRows={this.state.table.totalRows}
          handleTableUpdate={query => {
            this.getTableData({ ...this.state.query, ...query });
          }}
          handleSelect={this.handleSelect}
          handleEdit={this.handleEditClick}
          isEditable={true}
          isLoading={this.state.isLoading}
          page={this.state.query.page}
          handlePageUpdate={this.handlePageUpdate}
          selectedRows={this.state.table.selectedRows}
        />
        <UserModal
          show={this.state.showEditUserModal || this.state.showAddUserModal}
          onSave={formData => this.handleUserModalSave(this.state.showAddUserModal, formData)}
          onClose={this.handleUserModalClose}
          title={this.state.showEditUserModal ? 'Edit User' : 'Add User'}
          type={this.state.showEditUserModal ? 'edit' : 'add'}
          jurisdictionPaths={Object.keys(this.props.jurisdiction_paths)}
          roles={this.props.role_types}
          initialUserData={this.state.editRow === null ? {} : this.state.table.rowData[this.state.editRow]}
        />
        <EmailModal
          show={this.state.showEmailModal}
          title="Send Email to User(s)"
          onClose={this.handleEmailModalClose}
          onSave={formData => this.handleEmailSave(formData)}
          userCount={this.state.table.selectedRows.length}
        />
        <ConfirmationModal
          show={this.state.showConfirmationModal}
          title={this.state.currentAction ? this.state.currentAction.title : ''}
          onClose={this.handleConfirmationModalClose}
          onSave={this.handleConfirmationSave}
          actionDescription={this.getActionDescription(this.state.currentAction)}
        />
        <ToastContainer />
      </div>
    );
  }
}

AdminTable.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  role_types: PropTypes.array,
  is_usa_admin: PropTypes.bool,
};

export default AdminTable;
