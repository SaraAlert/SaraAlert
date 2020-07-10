import React from 'react';
import PropTypes from 'prop-types';
import { Button, Table } from 'react-bootstrap';
import 'react-toastify/dist/ReactToastify.css';
import UserModal from './UserModal';

class Admin extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      dataColumns: {
        id: { name: 'Id', dataField: 'id' },
        email: { name: 'email', dataField: 'email' },
        jurisdiction: { name: 'Jurisdiction', dataField: 'jurisdiction_path' },
        role: { name: 'Role', dataField: 'role' },
        status: { name: 'Status', dataField: 'locked' },
        twoFactorAuthEnabled: { name: '2FA Enabled', dataField: 'configured_2fa' },
      },
      selectedRows: [],
      showUserModal: false,
    };
  }

  handleAddUsersClick = () => {
    //TODO: handle single or bulk adding of users by showing appropriate modal
  };

  handleEditClick = () => {
    // Show user Modal
    this.setState({
      showUserModal: true,
    });
  };

  handleSave = () => {
    //TODO: MAKE AXIOS CALL
  };

  render() {
    return (
      <div>
        <UserModal
          show={this.state.showUserModal}
          onSave={this.handleSave}
          onClose={() => this.setState({ showUserModal: false })}
          title="Edit User"
          jurisdictionPaths={Object.keys(this.props.jurisdiction_paths)}
          roles={this.props.role_types}
          userData={{ jurisdiction: 'USA', role: 'analyst', status: 0 }}
        />

        <div className="d-flex justify-content-between">
          <div className="mb-1">
            <Button className="mx-1" size="lg" onClick={this.handleAddUsersClick}>
              <i className="fas fa-plus-circle"></i>
              &nbsp;Add User(s)
            </Button>
            <Button variant="secondary" className="m-1" size="lg">
              <i className="fas fa-download"></i>
              &nbsp;Export to CSV
            </Button>
          </div>
          <div className="mb-1 align-self-center">
            <span className="mr-2">
              <i className="fas fa-filter"></i>
            </span>
            <input type="text" placeholder="Search" aria-label="Search" />
          </div>
        </div>

        {this.state.selectedRows.length > 0 && (
          <div>
            <Button variant="secondary" size="sm">
              <i className="fas fa-trash"></i>
              Delete
            </Button>
            <Button variant="secondary" size="sm">
              <i className="fas fa-envelope"></i>
              Send Email
            </Button>
            <Button variant="secondary" size="sm">
              Reset 2FA
            </Button>
            <Button variant="secondary" size="sm">
              Reset Password
            </Button>
          </div>
        )}

        <Table striped>
          <thead>
            <tr>
              <th>
                <input type="checkbox"></input>
              </th>
              {Object.values(this.state.dataColumns).map((col, index) => {
                return <th key={index}>{col.name}</th>;
              })}
              <th>Edit</th>
            </tr>
          </thead>
          <tbody>
            {this.props.data.map(userData => {
              return (
                <tr key={userData.id}>
                  <td>
                    <input type="checkbox"></input>
                  </td>
                  {Object.values(this.state.dataColumns).map((col, index) => {
                    return <td key={index}>{userData[col.dataField]}</td>;
                  })}
                  <td>
                    <div className="float-left edit-button" onClick={() => this.handleEditClick()}>
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
