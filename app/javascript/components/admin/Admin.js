import React from 'react';
import PropTypes from 'prop-types';
import { Button, Table } from 'react-bootstrap';
import 'react-toastify/dist/ReactToastify.css';
import UserModal from './UserModal';
import axios from 'axios';
import { CSVLink } from 'react-csv';

class Admin extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      dataColumns: {
        id: { name: 'Id', dataField: 'id' },
        email: { name: 'email', dataField: 'email' },
        jurisdictionPath: { name: 'Jurisdiction', dataField: 'jurisdiction_path' },
        role: { name: 'Role', dataField: 'role' },
        isLocked: { name: 'Status', dataField: 'is_locked', options: { true: 'Locked', false: 'Unlocked' } },
        is2faEnabled: { name: '2FA Enabled', dataField: 'is_2fa_enabled', options: { true: 'Yes', false: 'No' } },
        isApiEnabled: { name: 'API Enabled', dataField: 'api_enabled', options: { true: 'Yes', false: 'No' } },
      },
      showEditUserModal: false,
      showAddUserModal: false,
      editRow: null,
      selectedRows: [],
      selectAll: false,
    };
  }

  handleAddUserClick = () => {
    // Show edit user Modal
    this.setState({
      showAddUserModal: true,
      editRow: null,
    });
  };

  handleEditClick = row => {
    // Show edit user Modal
    this.setState({
      showEditUserModal: true,
      editRow: row,
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
      this.handleAddNewUser(formData);
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

  handleReset2Fa = row => {
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

  handleImportClick = () => {
    //TODO: import and read csv
  };

  getCSVData = () => {
    // NOTE: react-csv has a bug where false values don't show up in the downloaded CSV
    // This has been addressed and recently merged: https://github.com/react-csv/react-csv/pull/193
    // Once this gets released and we update our version this code won't be necessary.
    return this.props.data.map(userData => {
      return {
        ...userData,
        api_enabled: userData.api_enabled.toString(),
        is_2fa_enabled: userData.is_2fa_enabled.toString(),
        is_locked: userData.is_locked.toString(),
      };
    });
  };

  handleCheckboxChange = (e, row) => {
    const checked = e.target.checked;
    if (checked && !this.state.selectedRows.includes(row)) {
      this.setState(prevState => ({
        selectedRows: [...prevState.selectedRows, row],
      }));
    } else {
      this.setState(prevState => {
        const newArr = [...prevState.selectedRows];
        const index = newArr.indexOf(row);
        newArr.splice(index, 1);
        return {
          selectedRows: newArr,
        };
      });
    }
  };

  toggleSelectAll = () => {
    this.setState(prevState => {
      const selectAll = !prevState.selectAll;
      const selectedRows = selectAll ? [...Array(this.props.data.length).keys()] : [];
      return {
        selectAll,
        selectedRows,
      };
    });
  };

  render() {
    const showModal = this.state.showEditUserModal || this.state.showAddUserModal;
    return (
      <div>
        {showModal && (
          <UserModal
            show={showModal}
            onSave={formData => this.handleSave(this.showAddUserModal, formData)}
            onClose={this.handleModalClose}
            title={this.state.showEditUserModal ? 'Edit User' : 'Add User'}
            jurisdictionPaths={Object.keys(this.props.jurisdiction_paths)}
            roles={this.props.role_types}
            initialUserData={this.state.editRow === null ? {} : this.props.data[this.state.editRow]}
          />
        )}

        <div className="d-flex justify-content-between">
          <div className="mb-1">
            <Button className="mx-1" size="lg" onClick={this.handleAddUserClick}>
              <i className="fas fa-plus-circle"></i>
              &nbsp;Add User
            </Button>
            <Button className="mx-1" size="lg" onClick={this.handleImportClick}>
              <i className="fas fa-upload"></i>
              &nbsp;Import Users from CSV
            </Button>
            <CSVLink data={this.getCSVData()} className="btn btn-secondary btn-lg mx-1" filename={'sara-accounts.csv'}>
              <i className="fas fa-download"></i>
              &nbsp;Export to CSV
            </CSVLink>
          </div>
          <div className="mb-1 align-self-center">
            <span className="mr-2">
              <i className="fas fa-filter"></i>
            </span>
            <input type="text" placeholder="Search" aria-label="Search" />
          </div>
        </div>

        {this.state.selectedRows.length > 0 && (
          <div className="mb-1">
            {this.state.selectedRows.length} Selected
            <Button variant="danger" className="mx-1" size="sm">
              <i className="fas fa-trash"></i>&nbsp;Delete
            </Button>
            <Button variant="secondary" className="mx-1" size="sm">
              Reset password
            </Button>
            <Button variant="secondary" className="mx-1" size="sm">
              Reset 2FA
            </Button>
            <Button variant="secondary" className="mx-1" size="sm">
              <i className="fas fa-envelope"></i>&nbsp;Send Email
            </Button>
          </div>
        )}

        <Table striped>
          <thead>
            <tr>
              <th>
                <input type="checkbox" onClick={this.toggleSelectAll}></input>
              </th>
              {Object.values(this.state.dataColumns).map((col, index) => {
                return <th key={index}>{col.name}</th>;
              })}
              <th>Edit</th>
            </tr>
          </thead>
          <tbody>
            {this.props.data.map((userData, row) => {
              return (
                <tr key={userData.id}>
                  <td>
                    <input
                      type="checkbox"
                      checked={this.state.selectAll || this.state.selectedRows.includes(row)}
                      onChange={e => this.handleCheckboxChange(e, row)}></input>
                  </td>
                  {Object.values(this.state.dataColumns).map((col, index) => {
                    // If this column has value options, use the data value as a key to those options
                    const value = col.options ? col.options[userData[col.dataField]] : userData[col.dataField];
                    return <td key={index}>{value}</td>;
                  })}
                  <td>
                    <div className="float-left edit-button" onClick={() => this.handleEditClick(row)}>
                      <i className="fas fa-edit"></i>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
        {/* TODO: add pagination*/}
      </div>
    );
  }
}

Admin.propTypes = {
  data: PropTypes.array,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  role_types: PropTypes.array,
  is_usa_admin: PropTypes.bool,
};

export default Admin;
