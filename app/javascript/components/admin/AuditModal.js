import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { Spinner } from 'react-bootstrap';
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
          { label: 'Triggered by', field: 'user' },
          { label: 'Action', field: 'change' },
          { label: 'Timestamp', field: 'timestamp', filter: this.formatTimestamp },
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
      entryOptions: [10, 15, 25],
      cancelToken: axios.CancelToken.source(),
      isLoading: false,

      show: false,
    };
  }

  hide = () => {
    this.setState({ isLoading: false }, () => {
      this.props.onClose();
    });
  };

  componentDidMount() {
    this.updateTable(this.state.query);
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

  // renderChange = (change, change_details) => {
  //   return (
  //     <React.Fragment>
  //       {change === 'jurisdiction_id' && (
  //         <React.Fragment>
  //           <b>Jurisdiction:</b>&nbsp;
  //           {_.invert(this.props.jurisdiction_paths)[change_details[0]]}
  //           <i className="mx-2 fas fa-arrow-right"></i>
  //           {_.invert(this.props.jurisdiction_paths)[change_details[1]]}
  //         </React.Fragment>
  //       )}
  //       {change === 'role' && (
  //         <React.Fragment>
  //           <b>Role:</b>&nbsp;
  //           {_.startCase(change_details[0])}
  //           <i className="mx-2 fas fa-arrow-right"></i>
  //           {_.startCase(change_details[1])}
  //         </React.Fragment>
  //       )}
  //       {change === 'locked_at' && (
  //         <React.Fragment>
  //           <b>Status:</b>&nbsp;
  //           {change_details[0] && (
  //             <span>
  //               Locked<i className="mx-2 fas fa-arrow-right"></i>Unlocked
  //             </span>
  //           )}
  //           {!change_details[0] && (
  //             <span>
  //               Unlocked<i className="mx-2 fas fa-arrow-right"></i>Locked
  //             </span>
  //           )}
  //         </React.Fragment>
  //       )}
  //       {change === 'api_enabled' && (
  //         <React.Fragment>
  //           <b>API Enabled:</b>&nbsp;
  //           {change_details[0] && (
  //             <span>
  //               Yes<i className="mx-2 fas fa-arrow-right"></i>No
  //             </span>
  //           )}
  //           {!change_details[0] && (
  //             <span>
  //               No<i className="mx-2 fas fa-arrow-right"></i>Yes
  //             </span>
  //           )}
  //         </React.Fragment>
  //       )}
  //       {change === 'email' && (
  //         <React.Fragment>
  //           <b>Email:</b>&nbsp;
  //           {change_details[0]}
  //           <i className="mx-2 fas fa-arrow-right"></i>
  //           {change_details[1]}
  //         </React.Fragment>
  //       )}
  //       {change === 'authy_enabled' && (
  //         <React.Fragment>
  //           <b>2FA Enabled:</b>&nbsp;
  //           {change_details[0] && (
  //             <span>
  //               Yes<i className="mx-2 fas fa-arrow-right"></i>No
  //             </span>
  //           )}
  //           {!change_details[0] && (
  //             <span>
  //               No<i className="mx-2 fas fa-arrow-right"></i>Yes
  //             </span>
  //           )}
  //         </React.Fragment>
  //       )}
  //       {change === 'force_password_change' && (
  //         <React.Fragment>
  //           <b>Password Changed/Reset</b>
  //         </React.Fragment>
  //       )}
  //       {change === 'last_sign_in_with_authy' && (
  //         <React.Fragment>
  //           <b>User Signed In</b>
  //         </React.Fragment>
  //       )}
  //     </React.Fragment>
  //   );
  // };

  // renderEvent = (event, index) => {
  //   return (
  //     <tr key={`${index}${this.props.user.id}ae`}>
  //       <td>{event.user}</td>
  //       <td>{this.renderChange(event.change, event.change_details)}</td>
  //       <td>{this.formatTimestamp(event.timestamp)}</td>
  //     </tr>
  //   );
  // };

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
            {this.state.isLoading && (
              <div className="text-center">
                <Spinner variant="secondary" animation="border" size="lg" />
              </div>
            )}
            <CustomTable
              columnData={this.state.table.colData}
              rowData={this.state.table.rowData}
              totalRows={this.state.table.totalRows}
              handleTableUpdate={query => this.updateTable({ ...this.state.query, page: query.page })}
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
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default AuditModal;
