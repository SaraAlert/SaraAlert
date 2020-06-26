import React from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import 'react-bootstrap-table/dist/react-bootstrap-table.min.css';
import { Button, ButtonGroup } from 'react-bootstrap';
import { BootstrapTable, TableHeaderColumn, InsertModalHeader, InsertModalFooter } from 'react-bootstrap-table';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import ReleaseUpdate from './ReleaseUpdate';
import { CSVLink } from 'react-csv';

class Admin extends React.Component {
  constructor(props) {
    super(props);
    var dataLen = props.data.length;
    for (var i = 0; i < dataLen; i++) {
      if (Array.isArray(props.data[parseInt(i)]['jurisdiction_path'])) {
        props.data[parseInt(i)]['jurisdiction_path'] = props.data[parseInt(i)]['jurisdiction_path'].join(', ');
      }
    }
    this.onAddRow = this.onAddRow.bind(this);
    this.afterSaveCell = this.afterSaveCell.bind(this);
  }

  onAddRow(row) {
    if (this.props.data.map(a => a.email).includes(row.email)) {
      alert('User already exists');
      return;
    }
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { jurisdiction: this.props.jurisdiction_paths[row.jurisdiction_path], email: row.email, role_title: row.role };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/create_user',
      data: submit_data,
    })
      .then(() => {
        return true;
      })
      .catch(() => {
        return false;
      });
    send_result.then(success => {
      if (success) {
        row['failed_attempts'] = 0;
        row['locked'] = 'Unlocked';
        row['configured_2fa'] = 'No';
        this.props.data.push(row);
        this.setState({ data: this.props.data });
      } else {
        alert('Error adding new user. Was the specified email address valid?');
      }
    });
  }

  afterSaveCell(row) {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = {
      jurisdiction: this.props.jurisdiction_paths[row.jurisdiction_path.replace(/,(?=[^\s])/g, ', ')],
      email: row.email,
      role_title: row.role,
    };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/edit_user',
      data: submit_data,
    })
      .then(() => {
        return true;
      })
      .catch(() => {
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.setState({ data: this.props.data });
      } else {
        alert('Error editing user.');
      }
    });
  }

  beforeSaveCell(row, cellName, cellValue) {
    // This is to prevent a Generic Object Injection Sink warning
    let prevVal = Object.values(row)[Object.keys(row).indexOf(cellName)];
    if (prevVal != cellValue) {
      // make cell name more human-friendly
      let hrCellName = cellName;
      if (cellName === 'jurisdiction_path') {
        hrCellName = 'jurisdiction';
      }
      alert(row.email + "'s " + hrCellName + ' will be changed from "' + prevVal + '" to "' + cellValue + '"');
      return true;
    } else {
      return false;
    }
  }

  addUserModalHeader = () => {
    return <InsertModalHeader title="Add User" hideClose={true} />;
  };

  addUserModalFooter = () => {
    return <InsertModalFooter saveBtnText="Add User" />;
  };

  addButtons = onClick => {
    return (
      <div>
        <Button variant="primary" size="lg" className="btn-block btn-square my-2" onClick={onClick}>
          Add User
        </Button>
        <CSVLink data={this.props.data} className="btn btn-primary btn-lg mb-3" filename={'sara-accounts.csv'}>
          Export to CSV
        </CSVLink>
      </div>
    );
  };

  createCustomButtonGroup = props => {
    return (
      <ButtonGroup size="xs" className="pb-1">
        {props.insertBtn}
      </ButtonGroup>
    );
  };

  createCustomToolBar = props => {
    return (
      <div className="col-4">
        <div className="row-xs">{props.components.btnGroup}</div>
        <div className="row-xs">{props.components.searchPanel}</div>
      </div>
    );
  };

  onClickUnlockButton = row => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { email: row.email };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/unlock_user',
      data: submit_data,
    })
      .then(() => {
        toast.success('User account unlocked: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return true;
      })
      .catch(() => {
        toast.error('Failed to unlock account: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.props.data.find(r => r.email === row.email).locked = 'Unlocked';
        this.setState({ data: this.props.data });
      } else {
        alert('Error unlocking user.');
      }
    });
  };

  onClickLockButton = row => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { email: row.email };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/lock_user',
      data: submit_data,
    })
      .then(() => {
        toast.success('User account locked: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return true;
      })
      .catch(() => {
        toast.error('Failed to lock account: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.props.data.find(r => r.email === row.email).locked = 'Locked';
        this.setState({ data: this.props.data });
      } else {
        alert('Error locking user.');
      }
    });
  };

  onClickApiEnableButton = row => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { email: row.email };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/enable_api',
      data: submit_data,
    })
      .then(() => {
        toast.success('API enabled for user account: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return true;
      })
      .catch(() => {
        toast.error('Failed to enable API for user account: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.props.data.find(r => r.email === row.email).api_enabled = true;
        this.setState({ data: this.props.data });
      } else {
        alert('Error enabling API for user.');
      }
    });
  };

  onClickApiDisableButton = row => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { email: row.email };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/disable_api',
      data: submit_data,
    })
      .then(() => {
        toast.success('API disabled for user account: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return true;
      })
      .catch(() => {
        toast.error('Failed to disable API for user account: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.props.data.find(r => r.email === row.email).api_enabled = false;
        this.setState({ data: this.props.data });
      } else {
        alert('Error disabling API for user.');
      }
    });
  };

  onClickSendResetButton = row => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { email: row.email };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/reset_password',
      data: submit_data,
    })
      .then(() => {
        toast.success('User password reset for: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return true;
      })
      .catch(() => {
        toast.error('Failed to reset password for: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.setState({ data: this.props.data });
      } else {
        alert('Error sending password reset.');
      }
    });
  };

  onClickReset2FAButton = row => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let submit_data = { email: row.email };
    let send_result = axios({
      method: 'post',
      url: window.BASE_PATH + '/admin/reset_2fa',
      data: submit_data,
    })
      .then(() => {
        toast.success('User 2FA reset: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return true;
      })
      .catch(() => {
        toast.error('Failed to reset 2FA for: ' + row.email, {
          autoClose: 2000,
          position: toast.POSITION.TOP_CENTER,
        });
        return false;
      });
    send_result.then(success => {
      if (success) {
        this.props.data.find(r => r.email === row.email).configured_2fa = 'No';
        this.setState({ data: this.props.data });
      } else {
        alert('Error reseting 2FA Pairing');
      }
    });
  };

  // eslint-disable-next-line no-unused-vars
  lockUnlockButton = (cell, row, enumObject, rowIndex) => {
    if (row['locked'] === 'Unlocked') {
      return (
        <Button variant="primary" size="md" className="btn-block btn-square btn-danger" onClick={() => this.onClickLockButton(row)}>
          Lock
        </Button>
      );
    } else {
      return (
        <Button variant="primary" size="md" className="btn-block btn-square btn-success" onClick={() => this.onClickUnlockButton(row)}>
          Unlock
        </Button>
      );
    }
  };

  // eslint-disable-next-line no-unused-vars
  apiButton = (cell, row, enumObject, rowIndex) => {
    if (row['api_enabled']) {
      return (
        <Button variant="primary" size="md" className="btn-block btn-square btn-danger" onClick={() => this.onClickApiDisableButton(row)}>
          Disable
        </Button>
      );
    } else {
      return (
        <Button variant="primary" size="md" className="btn-block btn-square btn-success" onClick={() => this.onClickApiEnableButton(row)}>
          Enable
        </Button>
      );
    }
  };

  // eslint-disable-next-line no-unused-vars
  sendResetButton = (cell, row, enumObject, rowIndex) => {
    return (
      <Button variant="primary" size="md" className="btn-block btn-square btn-info" onClick={() => this.onClickSendResetButton(row)}>
        Reset Password
      </Button>
    );
  };

  // eslint-disable-next-line no-unused-vars
  reset2FAButton = (cell, row, enumObject, rowIndex) => {
    return (
      <Button variant="primary" size="md" className="btn-block btn-square btn-secondary" onClick={() => this.onClickReset2FAButton(row)}>
        Reset 2FA
      </Button>
    );
  };

  render() {
    const options = {
      onAddRow: this.onAddRow,
      btnGroup: this.createCustomButtonGroup,
      insertBtn: this.addButtons,
      insertModalHeader: this.addUserModalHeader,
      insertModalFooter: this.addUserModalFooter,
      toolBar: this.createCustomToolBar,
      sortIndicator: true,
    };
    const cellEdit = {
      mode: 'click',
      beforeSaveCell: this.beforeSaveCell,
      afterSaveCell: this.afterSaveCell,
      blurToSave: true,
    };
    return (
      <div>
        <ToastContainer />
        <ReleaseUpdate is_usa_admin={this.props.is_usa_admin} user_count={this.props.data.length} authenticity_token={this.props.authenticity_token} />
        <h4>Note: To edit a user, click the cell you would like to edit, select a new value and then click anywhere outside of the table.</h4>
        <BootstrapTable
          data={this.props.data}
          cellEdit={cellEdit}
          insertRow={true}
          search={true}
          multiColumnSearch={true}
          options={options}
          className="table table-striped py-2">
          <TableHeaderColumn dataField="email" dataSort={true} isKey={true}>
            Email
          </TableHeaderColumn>
          <TableHeaderColumn dataField="id" dataSort={true} editable={false} hiddenOnInsert={true}>
            ID
          </TableHeaderColumn>
          <TableHeaderColumn
            dataField="jurisdiction_path"
            dataSort={true}
            editable={{ type: 'select', options: { values: Object.keys(this.props.jurisdiction_paths).map(p => p.replace(/, /g, ',')) } }}>
            Jurisdiction
          </TableHeaderColumn>
          <TableHeaderColumn dataField="role" dataSort={true} editable={{ type: 'select', options: { values: this.props.role_types } }}>
            Role
          </TableHeaderColumn>
          <TableHeaderColumn dataField="configured_2fa" searchable={false} editable={false} hiddenOnInsert={true} dataSort={true}>
            2FA Enabled
          </TableHeaderColumn>
          <TableHeaderColumn dataField="locked" editable={false} hiddenOnInsert={true} dataSort={true}>
            Status
          </TableHeaderColumn>
          <TableHeaderColumn dataField="button" dataFormat={this.lockUnlockButton.bind(this)} searchable={false} editable={false} hiddenOnInsert={true}>
            Lock/Unlock
          </TableHeaderColumn>
          <TableHeaderColumn dataField="button" dataFormat={this.sendResetButton.bind(this)} searchable={false} editable={false} hiddenOnInsert={true}>
            Reset Password
          </TableHeaderColumn>
          <TableHeaderColumn dataField="button" dataFormat={this.reset2FAButton.bind(this)} searchable={false} editable={false} hiddenOnInsert={true}>
            Reset 2FA
          </TableHeaderColumn>
          <TableHeaderColumn dataField="button" dataFormat={this.apiButton.bind(this)} searchable={false} editable={false} hiddenOnInsert={true}>
            API Access
          </TableHeaderColumn>
        </BootstrapTable>
        {this.props.is_usa_admin && (
          <div className="my-4">
            <u>Stats</u>
            <br />
            Users: {this.props.data?.length || 0}
            <br />
            Jurisdictions: {Object.keys(this.props.jurisdiction_paths)?.length || 0}
          </div>
        )}
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
