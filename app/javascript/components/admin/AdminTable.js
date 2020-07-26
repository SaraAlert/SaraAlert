import React from 'react';
import PropTypes from 'prop-types';
import { Button, DropdownButton, Dropdown, InputGroup, Form, OverlayTrigger, Tooltip } from 'react-bootstrap';
import 'react-toastify/dist/ReactToastify.css';
import UserModal from './UserModal';
import axios from 'axios';
import { CSVLink } from 'react-csv';
import ActionTable from '../layout/ActionTable';

class AdminTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Id', field: 'id', isSortable: true },
          { label: 'email', field: 'email', isSortable: true },
          { label: 'Jurisdiction', field: 'jurisdictionPath', isSortable: true },
          { label: 'Role', field: 'role', isSortable: true },
          { label: 'Status', field: 'isLocked', isSortable: false, options: { true: 'Locked', false: 'Unlocked' } },
          { label: '2FA Enabled', field: 'is2FAEnabled', isSortable: false, options: { true: 'Yes', false: 'No' } },
          { label: 'API Enabled', field: 'isAPIEnabled', isSortable: false, options: { true: 'Yes', false: 'No' } },
        ],
        rowData: [],
        totalRows: 0,
        selectedRows: [],
      },
      query: {
        page: 0,
        search: '',
      },
      showAddUserModal: false,
      actionsEnabled: false,
      cancelToken: axios.CancelToken.source(),
      isLoading: false,
    };
  }

  componentDidMount() {
    this.updateTableData(this.state.query);
  }

  updateTableData = query => {
    // Cancel any previous unfinished requests to prevent race condition inconsistencies and
    // generate new cancel token for this request.
    this.state.cancelToken.cancel();
    const cancelToken = axios.CancelToken.source();

    this.setState({ cancelToken, isLoading: true }, () => {
      axios
        .get('/admin/users', {
          params: { ...query },
          cancelToken: this.state.cancelToken.token,
        })
        .catch(error => {
          if (!axios.isCancel(error)) {
            this.setState(state => {
              return {
                table: { ...state.table, rowData: [], totalRows: 0 },
                isLoading: false,
              };
            });
          }
        })
        .then(response => {
          if (response && response.data && response.data.linelist) {
            console.log('response data:', response.data);
            this.setState(state => {
              return {
                table: { ...state.table, rowData: response.data.linelist, totalRows: response.data.total },
                selectedRows: [],
                isLoading: false,
              };
            });
          } else {
            this.setState({ selectedRows: [], isLoading: false });
          }
        });
    });
  };

  handleAddUserClick = () => {
    // Show edit user Modal
    this.setState({
      showAddUserModal: true,
      editRow: null,
    });
  };

  /**
   * Callback called when child Table component detects a selection change.
   * @param {Number[]} selectedRows - Array of selected row indices.
   */
  handleSelect = selectedRows => {
    this.setState({
      actionsEnabled: selectedRows.length > 0,
      selectedRows: selectedRows,
    });
  };

  handleActionClick = () => {
    console.log('action button clicked');
  };

  handleSave = (isNewUser, formData) => {
    console.log('is new user?:', isNewUser);
    this.handleModalClose();
    console.log('form data:', formData);

    if (isNewUser) {
      this.handleAddUser(formData);
    } else {
      this.handleEditUser(formData);
    }
  };

  handleAddUser = data => {
    const path = 'create_user';

    const dataToSend = {
      email: data.email,
      jurisdiction: this.props.jurisdiction_paths[data.jurisdictionPath],
      role_title: data.role,
    };

    const handleSuccess = response => {
      console.log('Response:', response);
      this.updateTableData(this.state.query);
    };

    const handleError = error => {
      console.log('Error:', error);
      alert('Error adding new user. New user not saved.');
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  handleEditUser = data => {
    const path = 'edit_user';
    const dataToSend = {
      email: data.email,
      jurisdiction: this.props.jurisdiction_paths[data.jurisdictionPath],
      role_title: data.role,
    };

    const handleSuccess = response => {
      console.log('Response:', response);
      this.updateTableData(this.state.query);
    };

    const handleError = error => {
      console.log('Error:', error);
      alert('Error editing new user. Changes not saved.');
    };

    this.axiosPostRequest(path, dataToSend, handleSuccess, handleError);
  };

  handleModalClose = () => {
    this.setState({
      showEditUserModal: false,
      showAddUserModal: false,
      editRow: null,
    });
  };

  handleDeleteUser = row => {
    console.log(row);
    //TODO
  };

  handleResetPassword = row => {
    console.log(row);
    //TODO
  };

  handleReset2FA = row => {
    console.log(row);
    //TODO
  };

  axiosPostRequest = (path, data, handleSuccess, handleError) => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/' + path,
      data: data,
    })
      .then(handleSuccess)
      .catch(handleError);
  };

  getCSVData = () => {
    // NOTE: react-csv has a bug where false values don't show up in the downloaded CSV
    // This has been addressed and recently merged: https://github.com/react-csv/react-csv/pull/193
    // Once this gets released and we update our version this code won't be necessary.
    return this.state.table.rowData.map(userData => {
      return {
        ...userData,
        api_enabled: userData.isAPIEnabled.toString(),
        is_2fa_enabled: userData.is2FAEnabled.toString(),
        is_locked: userData.isLocked.toString(),
      };
    });
  };

  handleEditClick = row => {
    this.setState({
      showEditUserModal: true,
      editRow: row,
    });
  };

  handleSearchChange = event => {
    const value = event.target.value;
    this.setState(
      state => {
        return { query: { ...state.query, search: value } };
      },
      () => {
        this.updateTableData(this.state.query);
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
        return { query: { ...state.query, page: page.selected } };
      },
      () => {
        this.updateTableData(this.state.query);
      }
    );
  };

  //TODO: rename this or clean this up
  handleTableUpdate = query => {
    const fullQuery = { ...this.state.query, ...query };
    this.updateTableData(fullQuery);
  };

  render() {
    const showModal = this.state.showEditUserModal || this.state.showAddUserModal;
    return (
      <div>
        {showModal && (
          <UserModal
            show={showModal}
            onSave={formData => this.handleSave(this.state.showAddUserModal, formData)}
            onClose={this.handleModalClose}
            title={this.state.showEditUserModal ? 'Edit User' : 'Add User'}
            jurisdictionPaths={Object.keys(this.props.jurisdiction_paths)}
            roles={this.props.role_types}
            initialUserData={this.state.editRow === null ? {} : this.state.table.rowData[this.state.editRow]}
          />
        )}
        <div className="d-flex justify-content-between mb-2">
          <div className="mb-1">
            <Button className="mx-1" size="lg" onClick={this.handleAddUserClick}>
              <i className="fas fa-plus-circle"></i>
              &nbsp;Add User
            </Button>
            <CSVLink data={this.getCSVData()} className="btn btn-secondary btn-lg mx-1" filename={'sara-accounts.csv'}>
              <i className="fas fa-download"></i>
              &nbsp;Export to CSV
            </CSVLink>
          </div>
          <div>
            <InputGroup size="md">
              <InputGroup.Prepend>
                <OverlayTrigger overlay={<Tooltip>Search by monitoree name, date of birth, state/local id, cdc id, or nndss/case id</Tooltip>}>
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
                  <Dropdown.Item className="px-3" onClick={() => {}}>
                    <i className="fas fa-undo"></i>
                    <span className="ml-2">Reset Password</span>
                  </Dropdown.Item>
                )}
                <Dropdown.Item className="px-3" onClick={() => {}}>
                  <i className="fas fa-key"></i>
                  <span className="ml-2">Reset 2FA</span>
                </Dropdown.Item>
                <Dropdown.Item className="px-3" onClick={() => {}}>
                  <i className="fas fa-envelope"></i>
                  <span className="ml-2">Send Email</span>
                </Dropdown.Item>
              </DropdownButton>
            </InputGroup>
          </div>
        </div>

        <ActionTable
          columnData={this.state.table.colData}
          rowData={this.state.table.rowData}
          totalRows={this.state.table.totalRows}
          handleTableUpdate={this.handleTableUpdate}
          handleSelect={this.handleSelect}
          handleEdit={this.handleEditClick}
          isEditable={true}
          isLoading={this.state.isLoading}
          page={this.state.query.page}
          handlePageUpdate={this.handlePageUpdate}
          selectedRows={this.state.table.selectedRows}></ActionTable>
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
