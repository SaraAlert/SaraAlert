import React from 'react';
import axios from 'axios';
import { toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { BootstrapTable, TableHeaderColumn } from 'react-bootstrap-table';

const roleTypes = ['admin', 'enroller', 'monitor'];

class Admin extends React.Component {
  constructor(props) {
    super(props);
    var dataLen = props.data.length;
    for (var i = 0; i < dataLen; i++) {
      props.data[i]['role'] = props.roles[i]['name'];
    }
    this.onAddRow = this.onAddRow.bind(this);
  }

  onAddRow(row) {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    const data = new Object({ user: row });
    const message = 'User Successfully Added';
    toast.success(message, {});
    axios({
      method: 'post',
      url: '/admin/create_user',
      data: data,
    })
      .then(function() {
        alert('Successfully added new user.');
      })
      .catch(() => {
        alert('Error adding new user.');
      });
  }

  addUserModalHeader = () => {
    return <InsertModalHeader title="Add User" />;
  };

  addUserModalFooter = save => {
    return <InsertModalFooter saveBtnText="Add User" />;
  };

  render() {
    const options = {
      onAddRow: this.onAddRow,
      insertModalHeader: this.addUserModalHeader,
      insertModalFooter: this.addUserModalFooter,
    };

    return (
      <BootstrapTable data={this.props.data} insertRow={true} options={options}>
        <TableHeaderColumn width="150px" dataField="email" isKey>
          Email
        </TableHeaderColumn>
        <TableHeaderColumn width="150px" dataField="jurisdiction_path">
          Jurisdiction
        </TableHeaderColumn>
        <TableHeaderColumn width="150px" dataField="force_password_change">
          Force Password Change
        </TableHeaderColumn>
        <TableHeaderColumn width="150px" dataField="role" editable={{ type: 'select', options: { values: roleTypes } }}>
          Role
        </TableHeaderColumn>
      </BootstrapTable>
    );
  }
}

export default Admin;
