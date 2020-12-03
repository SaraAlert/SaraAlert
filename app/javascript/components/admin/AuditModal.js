import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import CustomTable from '../layout/CustomTable';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';

class AuditModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Triggered by', field: 'user', isSortable: true },
          { label: 'Action', field: 'change', filter: this.formatChange, isSortable: false },
          { label: 'Timestamp', field: 'timestamp', filter: this.formatTimestamp, isSortable: true },
        ],
        rowData: [],
        totalRows: 0,
        selectedRows: [],
        selectAll: false,
      },
      query: {
        page: 0,
        entries: 25,
      },
      entryOptions: [10, 15, 25, 50, 100],
      cancelToken: axios.CancelToken.source(),
      isLoading: false,
      show: false,
      all_jurisdiction_paths: {},
    };
  }

  hide = () => {
    this.setState({ isLoading: false }, () => {
      this.props.onClose();
    });
  };

  componentDidMount() {
    this.updateTable(this.state.query);

    // Gets all jurisdiction paths on initial mount.
    this.getAllJurisdictionPaths();
  }

  updateTable = query => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState({ query, cancelToken, isLoading: true }, () => {
      this.queryServer(query);
    });
  };

  queryServer = _.debounce(query => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post('/users/audits/' + this.props.user.id, {
        ...query,
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
        } else {
          console.log(error);
          this.setState({ isLoading: false });
        }
      })
      .then(response => {
        if (response && response.data && response.data.audit_rows) {
          this.setState(state => {
            const displayedColData = this.state.table.colData.filter(colData => response.data.audit_rows.includes(colData.field));
            return {
              table: { ...state.table, displayedColData, rowData: response.data.audit_rows, totalRows: response.data.total },
              isLoading: false,
            };
          });
        } else {
          this.setState({ isLoading: false });
        }
      });
  }, 500);

  formatTimestamp(timestamp) {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
  }

  /**
   * Gets the all possible jurisdictions path via an axios GET request.
   */
  getAllJurisdictionPaths() {
    axios.get('/jurisdictions/allpaths').then(response => {
      const responseData = response.data.all_jurisdiction_paths;

      // Swap keys and values for ease of use
      let all_jurisdiction_paths = Object.assign({}, ...Object.entries(responseData).map(([id, path]) => ({ [path]: parseInt(id) })));

      this.setState({ all_jurisdiction_paths });
    });
  }

  formatChange = change => {
    switch (change.name) {
      case 'locked_at':
        if (!change.details || !Array.isArray(change.details) || !change.details.length) {
          return (
            <span>
              <b>Account Status</b>: Updated
            </span>
          );
        } else if (change.details[0]) {
          return (
            <span>
              <b>Account Status</b>: Unlocked
            </span>
          );
        } else {
          return (
            <span>
              <b>Account Status</b>: Locked
            </span>
          );
        }
      case 'jurisdiction_id':
        if (!change.details || !Array.isArray(change.details) || change.details.length < 2) {
          return (
            <span>
              <b>Jurisdiction</b>: Updated
            </span>
          );
        } else {
          return (
            <span>
              <b>Jurisdiction</b>: Changed from &quot;{_.invert(this.state.all_jurisdiction_paths)[change.details[0]]}&quot; to &quot;
              {_.invert(this.state.all_jurisdiction_paths)[change.details[1]]}&quot;
            </span>
          );
        }
      case 'created_at':
        return (
          <span>
            <b>Account Created</b>
          </span>
        );
      case 'api_enabled':
        if (!change.details || !Array.isArray(change.details) || !change.details.length) {
          return (
            <span>
              <b>API Access</b>: Updated
            </span>
          );
        } else if (change.details[0]) {
          return (
            <span>
              <b>API Access</b>: Disabled
            </span>
          );
        } else {
          return (
            <span>
              <b>API Access</b>: Enabled
            </span>
          );
        }
      case 'role':
        if (!change.details || !Array.isArray(change.details) || change.details.length < 2) {
          return (
            <span>
              <b>Role</b>: Updated
            </span>
          );
        } else {
          return (
            <span>
              <b>Role</b>: Changed from &quot;{change.details[0]}&quot; to &quot;{change.details[1]}&quot;
            </span>
          );
        }
      case 'email':
        if (!change.details || !Array.isArray(change.details) || change.details.length < 2) {
          return (
            <span>
              <b>Email</b>: Updated
            </span>
          );
        } else {
          return (
            <span>
              <b>Email</b>: Changed from &quot;{change.details[0]}&quot; to &quot;{change.details[1]}&quot;
            </span>
          );
        }
      case 'authy_enabled':
        if (!change.details || !Array.isArray(change.details) || !change.details.length) {
          return (
            <span>
              <b>2FA</b>: Updated
            </span>
          );
        } else if (change.details[0]) {
          return (
            <span>
              <b>2FA</b>: Enabled
            </span>
          );
        } else {
          return (
            <span>
              <b>2FA</b>: Disabled
            </span>
          );
        }
      case 'force_password_change':
        return (
          <span>
            <b>Password Changed/Reset</b>
          </span>
        );
      case 'last_sign_in_with_authy':
        return (
          <span>
            <b>User Signed In</b>
          </span>
        );
    }
  };

  /**
   * Called when table is to be updated because of a sorting change.
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
   * Called when the number of entries to be shown on a page changes.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Event when num entries changes
   */
  handleEntriesChange = event => {
    const value = event.target.value;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: value },
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

  render() {
    return (
      <React.Fragment>
        <Modal show={this.props.show} onHide={this.hide} dialogClassName="modal-am" aria-labelledby="contained-modal-title-vcenter" centered>
          <Modal.Header closeButton>
            <Modal.Title>Audit Events</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <span className="pb-3 d-inline-block">
              <b>User:</b> {this.props.user.email}
            </span>
            <CustomTable
              columnData={this.state.table.colData}
              rowData={this.state.table.rowData}
              totalRows={this.state.table.totalRows}
              handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
              handleEntriesChange={this.handleEntriesChange}
              isEditable={false}
              isSelectable={false}
              isAuditable={false}
              isLoading={this.state.isLoading}
              page={this.state.query.page}
              handlePageUpdate={this.handlePageUpdate}
              entryOptions={this.state.entryOptions}
              entries={this.state.query.entries}
            />
          </Modal.Body>
          <Modal.Footer>
            <Button variant="secondary btn-square" onClick={this.hide}>
              Close
            </Button>
          </Modal.Footer>
        </Modal>
      </React.Fragment>
    );
  }
}

AuditModal.propTypes = {
  user: PropTypes.object,
  onClose: PropTypes.func,
  show: PropTypes.bool,
  authenticity_token: PropTypes.string,
};

export default AuditModal;
