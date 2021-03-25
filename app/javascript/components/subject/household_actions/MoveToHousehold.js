import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal, InputGroup, OverlayTrigger, Tooltip } from 'react-bootstrap';

import { formatDate } from '../../../utils/DateTime';
import axios from 'axios';
import _ from 'lodash';

import BadgeHOH from '../../util/BadgeHOH';
import CustomTable from '../../layout/CustomTable';
import reportError from '../../util/ReportError';

class MoveToHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { field: 'name', label: 'Monitoree', isSortable: true, tooltip: null, filter: this.renderPatientName },
          { field: 'state_local_id', label: 'State/Local ID', isSortable: true, tooltip: null },
          { field: 'jurisdiction', label: 'Jurisdiction', isSortable: true, tooltip: null },
          { field: 'dob', label: 'Date of Birth', isSortable: true, tooltip: null, filter: formatDate },
          { field: 'select', label: '', isSortable: false, tooltip: null, filter: this.createSelectButton, className: 'text-center', onClick: this.submit },
        ],
        rowData: [],
        totalRows: 0,
      },
      query: {
        page: 0,
        search: '',
        entries: 5,
        workflow: 'all',
        tab: 'all',
        scope: 'all',
        tz_offset: new Date().getTimezoneOffset(),
        // This query should always filter out records that are not self-reporters
        filter: [
          {
            dateOption: null,
            filterOption: {
              description: 'Monitorees that are a Head of Household or self-reporter',
              name: 'hoh',
              title: 'Daily Reporters (Boolean)',
              type: 'boolean',
            },
            value: true,
          },
        ],
      },
      entryOptions: [5, 10],
      isLoading: false,
      showModal: false,
      cancelToken: axios.CancelToken.source(),
    };
  }

  /**
   * Creates a link and renders HoH badge for monitoree name in table.
   * @param {Object} data - provided by CustomTable about each cell in the column this filter is called in.
   */
  renderPatientName = data => {
    const name = data.value;
    const rowData = data.rowData;

    if (rowData.is_hoh) {
      return (
        <div>
          <BadgeHOH patientId={rowData.id.toString()} customClass={'badge-hoh ml-1'} location={'right'} />
          <a href={`${window.BASE_PATH}/patients/${rowData.id}`}>{name}</a>
        </div>
      );
    }
    return <a href={`${window.BASE_PATH}/patients/${rowData.id}`}>{name}</a>;
  };

  /**
   * Creates a "Select" button for each row of the table.
   * @param {Object} data - provided by CustomTable about each cell in the column this filter is called in.
   */
  createSelectButton(data) {
    const rowData = data?.rowData;
    const patientId = rowData?.id;
    const ariaLabel = `Select button for monitoree ${rowData?.name}  with ID ${patientId}.`;
    return (
      <Button id={`select-button-${patientId}`} variant="primary" size="md" aria-label={ariaLabel}>
        Select
      </Button>
    );
  }

  /**
   * Toggles the Move To Household modal.
   */
  toggleModal = () => {
    let current = this.state.showModal;

    // If toggling off
    if (current) {
      // Reset modal when modal is hidden
      this.resetState();
    } else {
      this.setState(
        {
          showModal: true,
          isLoading: true,
        },
        () => {
          // Make initial call for table data when modal is shown.
          this.updateTable(this.state.query);
        }
      );
    }
  };

  resetState = () => {
    const resetQuery = {
      ...this.state.query,
      page: 0,
      search: '',
      entries: 5,
    };

    const resetTable = {
      ...this.state.table,
      rowData: [],
      totalRows: 0,
    };

    this.setState({
      showModal: false,
      isLoading: false,
      query: resetQuery,
      table: resetTable,
    });
  };

  /**
   * Handles change of input in the search input.
   * @param {SyntheticEvent} event - Event when the search input changes
   */
  handleSearchChange = event => {
    const value = event.target.value;
    this.setState(
      state => {
        return { query: { ...state.query, search: value } };
      },
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
    const value = event?.target?.value || event;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: parseInt(value), page: 0 },
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
   *
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
      .post(window.BASE_PATH + '/patients/head_of_household_options', {
        query,
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
        if (response && response.data && response.data.linelist) {
          this.setState(state => {
            const displayedColData = this.state.table.colData.filter(colData => response.data.fields.includes(colData.field));
            return {
              table: { ...state.table, displayedColData, rowData: response.data.linelist, totalRows: response.data.total },
              isLoading: false,
            };
          });
        } else {
          this.setState({ isLoading: false });
        }
      });
  }, 500);

  /**
   * Makes a POST to update the HoH for the current patient.
   * @param {string} new_hoh_id
   */
  submit = new_hoh_id => {
    this.setState({ isLoading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/move_to_household', {
          new_hoh_id: new_hoh_id,
        })
        .then(() => {
          // Reload the page to see updated HoH
          location.reload();
        })
        .catch(err => {
          reportError(err?.response?.data?.error ? err.response.data.error : err, false);
        });
    });
  };

  /**
   * Grabs a formatted string with the name of the patient who is being moved to a household.
   */
  getPatientName = () => {
    return `${this.props.patient?.last_name || ''}, ${this.props.patient?.first_name || ''} ${this.props.patient?.middle_name || ''}`;
  };

  /**
   * Handles a key press event on the search form control.
   * Checks for enter button press and prevents submisson event.
   * @param {Object} event
   */
  handleKeyPress(event) {
    if (event.which === 13) {
      event.preventDefault();
    }
  }

  createModal() {
    return (
      <Modal dialogClassName="modal-move-household" show centered onHide={this.toggleModal}>
        <Modal.Header>
          <Modal.Title>Move To Household</Modal.Title>
        </Modal.Header>
        <Modal.Body className="modal-move-household-body">
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label>
                  Please select the new monitoree that will respond for <b>{this.getPatientName()}</b>.
                </Form.Label>
                <p>
                  You may select from the provided existing Head of Households and monitorees who are self reporting.
                  {` ${this.getPatientName()}`} will be immediately moved into the selected monitoree&apos;s household.
                </p>
                <InputGroup size="md">
                  <InputGroup.Prepend>
                    <OverlayTrigger overlay={<Tooltip>Search by monitoree name, date of birth, state/local id, cdc id, or nndss/case id</Tooltip>}>
                      <InputGroup.Text className="rounded-0">
                        <i className="fas fa-search"></i>
                        <label htmlFor="search" className="ml-1 mb-0">
                          Search
                        </label>
                      </InputGroup.Text>
                    </OverlayTrigger>
                  </InputGroup.Prepend>
                  <Form.Control
                    id="search-input"
                    autoComplete="off"
                    size="md"
                    name="search"
                    aria-label="Search"
                    value={this.state.query.search}
                    onChange={this.handleSearchChange}
                    onKeyPress={this.handleKeyPress}
                  />
                </InputGroup>
              </Form.Group>
            </Row>
          </Form>
          <CustomTable
            columnData={this.state.table.colData}
            rowData={this.state.table.rowData}
            totalRows={this.state.table.totalRows}
            handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
            handleEntriesChange={this.handleEntriesChange}
            isSelectable={false}
            isEditable={false}
            isLoading={this.state.isLoading}
            page={this.state.query.page}
            handlePageUpdate={this.handlePageUpdate}
            entryOptions={this.state.entryOptions}
            entries={this.state.query.entries}
          />
        </Modal.Body>
        <Modal.Footer>
          <Button
            id="move-to-household-cancel-button"
            variant="secondary btn-square"
            aria-label="Cancel button for Move To Household modal"
            onClick={this.toggleModal}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button size="sm" className="my-2 mr-2" aria-label="Move To Household button" onClick={this.toggleModal}>
          <i className="fas fa-house-user"></i> Move To Household
        </Button>
        {this.state.showModal && this.createModal()}
      </React.Fragment>
    );
  }
}

MoveToHousehold.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default MoveToHousehold;
