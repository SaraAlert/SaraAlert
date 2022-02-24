import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal } from 'react-bootstrap';

import { formatTimestamp } from '../../utils/DateTime';
import axios from 'axios';
import _ from 'lodash';

import CustomTable from '../layout/CustomTable';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class AuditModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { label: 'Triggered by', field: 'user', className: 'wrap-words', isSortable: true, colWidth: '30%' },
          { label: 'Action', field: 'change', className: 'wrap-words', filter: this.formatChange, isSortable: false, colWidth: '60%' },
          { label: 'Timestamp', field: 'timestamp', filter: formatTimestamp, isSortable: true, colWidth: '10%' },
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

  /**
   * Called when table data is to be updated because of some change to the table setting.
   * @param {Object} query - Updated query for table data after change.
   */
  updateTable = query => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState({ query, cancelToken, isLoading: true }, () => {
      this.queryServer(query);
    });
  };

  /**
   * Returns updated table data via an axios POST request.
   */
  queryServer = _.debounce(query => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(`${window.BASE_PATH}/users/audits/${this.props.user.id}`, {
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
          reportError(error);
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

  /**
   * Gets the all possible jurisdictions path via an axios GET request.
   */
  getAllJurisdictionPaths() {
    axios.get(`${window.BASE_PATH}/jurisdictions/allpaths`).then(response => {
      const responseData = response.data.all_jurisdiction_paths;

      // Swap keys and values for ease of use
      let all_jurisdiction_paths = Object.assign({}, ...Object.entries(responseData).map(([id, path]) => ({ [path]: parseInt(id) })));

      this.setState({ all_jurisdiction_paths });
    });
  }

  /**
   * Formatting method for displaying each audit action in the table.
   * @param {Object} data - Data about the cell this filter is called on.
   */
  formatChange = data => {
    //Audit to display holding the updated element ({String} name) and the before & after values ({Array} details)
    const change = data.value;
    switch (change.name) {
      case 'locked_at':
        return (
          <span>
            <b>Account Status</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || !change.details.length ? ' Updated' : change.details[0] ? 'Unlocked' : 'Locked'}
          </span>
        );
      case 'notes':
        return (
          <span>
            <b>Notes</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || !change.details.length
              ? ' Updated'
              : ' Changed from "' +
                (change.details[0] == null ? '' : change.details[0]) +
                '" to "' +
                (change.details[1] == null ? '' : change.details[1]) +
                '"'}
          </span>
        );
      case 'jurisdiction_id':
        return (
          <span>
            <b>Jurisdiction</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || change.details.length < 2
              ? ' Updated'
              : ' Changed from "' +
                _.invert(this.state.all_jurisdiction_paths)[change.details[0]] +
                '" to "' +
                _.invert(this.state.all_jurisdiction_paths)[change.details[1]] +
                '"'}
          </span>
        );
      case 'created_at':
        return (
          <span>
            <b>Account Created</b>
          </span>
        );
      case 'api_enabled':
        return (
          <span>
            <b>API Access</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || !change.details.length ? ' Updated' : change.details[0] ? 'Disabled' : 'Enabled'}
          </span>
        );
      case 'role':
        return (
          <span>
            <b>Role</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || change.details.length < 2
              ? ' Updated'
              : ' Changed from "' + _.startCase(change.details[0]) + '" to "' + _.startCase(change.details[1]) + '"'}
          </span>
        );
      case 'email':
        return (
          <span>
            <b>Email</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || change.details.length < 2
              ? ' Updated'
              : ' Changed from "' + change.details[0] + '" to "' + change.details[1] + '"'}
          </span>
        );
      case 'authy_enabled':
        return (
          <span>
            <b>2FA</b>
            <br></br>
            {!change.details || !Array.isArray(change.details) || !change.details.length ? ' Updated' : change.details[0] ? 'Disabled' : 'Enabled'}
          </span>
        );
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
      case 'manual_lock_reason':
        return (
          <span>
            <b>Manually Set Status</b>
            <InfoTooltip tooltipTextKey={'manualLockReasonAudit'} location="right"></InfoTooltip>
            <br></br>
            {!change.details || !Array.isArray(change.details) || change.details.length < 2
              ? ' Updated'
              : ' Changed from "' +
                (change.details[0] == null ? '' : change.details[0]) +
                '" to "' +
                (change.details[1] == null ? '' : change.details[1]) +
                '"'}
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

  render() {
    return (
      <React.Fragment>
        <Modal show={this.props.show} onHide={this.hide} dialogClassName="modal-audit" aria-labelledby="contained-modal-title-vcenter" centered>
          <Modal.Header closeButton>
            <Modal.Title>Audit Events</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <span className="pb-3 d-inline-block wrap">
              <b>User:</b> {this.props.user.email}
            </span>
            <CustomTable
              dataType="audits"
              columnData={this.state.table.colData}
              rowData={this.state.table.rowData}
              totalRows={this.state.table.totalRows}
              handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
              handleEntriesChange={this.handleEntriesChange}
              isEditable={false}
              isSelectable={false}
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
