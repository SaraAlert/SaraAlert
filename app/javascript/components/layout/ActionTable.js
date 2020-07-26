import React from 'react';
import { PropTypes } from 'prop-types';
import { Spinner, Table, Form, InputGroup, Row, Col } from 'react-bootstrap';
import ReactPaginate from 'react-paginate';
import InfoTooltip from '../util/InfoTooltip';

class ActionTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectAll: false,
      // TODO: make these props?
      pagination: {
        entries: 25,
        entryOptions: [10, 15, 25, 50, 100],
      },
      tableQuery: {
        orderBy: '',
        sortDirection: '',
      },
    };
  }

  /**
   * Called when the number of entries to be shown on a page changes.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Change event on entries input.
   */
  handleNumEntriesChange = event => {
    // Store event target value in string before calling async method (otherwise event will be nullified by the time it's called).
    const value = event.target.value;
    this.setState(
      prevState => {
        const pagination = { ...prevState.pagination, entries: value };
        return { pagination };
      },
      () => {
        this.props.handleTableUpdate({ ...this.state.tableQuery, entries: this.state.pagination.entries });
      }
    );
  };

  /**
   * Called when a sorting button is clicked in a column header.
   * Toggles sort direction and updates the table based on the clicked column field.
   * @param {*} field
   */
  handleSortClick = field => {
    this.setState(prevState => {
      const sortDirection = prevState.tableQuery.sortDirection === 'asc' ? 'desc' : 'asc';
      const tableQuery = { ...prevState.tableQuery, sortDirection, orderBy: field };
      return { tableQuery };
    });
    this.props.handleTableUpdate({ ...this.state.tableQuery });
  };

  /**
   * Called when a checkbox on a given row is clicked (checked/unchecked).
   * @param {Event} e - Checkbox change event.
   * @param {Number} row - Row that was clicked.
   */
  handleCheckboxChange = (e, row) => {
    const checked = e.target.checked;

    // If row is selected and wasn't previously, add it to the selected rows.
    if (checked && !this.props.selectedRows.includes(row)) {
      const selectedRows = [...this.props.selectedRows, row];
      this.props.handleSelect(selectedRows);

      // Update select all if all displayed rows are checked.
      if (selectedRows >= this.state.pagination.entries) {
        this.setState({ selectAll: true });
      }
    } else {
      // Otherwise if it was unchecked, remove it from the selected rows and toggle off select all if applicable.
      const selectedRows = [...this.props.selectedRows];
      const index = selectedRows.indexOf(row);
      selectedRows.splice(index, 1);
      this.props.handleSelect(selectedRows);

      // Update select all if not all displayed rows are checked.
      this.setState({ selectAll: false });
    }
  };

  /**
   * Called when the checkbox in the table header is clicked and either selects all rows
   * or deselects all rows based on the current state.
   */
  toggleSelectAll = () => {
    this.setState(
      state => {
        return {
          selectAll: !state.selectAll,
        };
      },
      () => {
        // Call handler for when a row is checked/unchecked.
        const selectedRows = this.state.selectAll ? [...Array(this.props.rowData.length).keys()] : [];
        this.props.handleSelect(selectedRows);
      }
    );
  };

  /**
   * Called when the edit button a row is clicked. Calls passed in handler (if any).
   * @param {Number} row - Row that the edit button was clicked on.
   */
  handleEditClick = row => {
    if (this.props.isEditable && this.props.handleEdit) {
      this.props.handleEdit(row);
    } else if (this.props.isEditable) {
      console.log('Please provide a handler function in component props for editing.');
    }
  };

  /**
   * Renders the header element of the table for a given field with
   * optional sorting functionality and a toolip.
   *
   * @param {String} field - Field in the data this column corresponds to.
   * @param {String} label - Display label for the column.
   * @param {Boolean} sortable - True if this column should be sortable and false otherwise.
   * @param {String} tooltip - Text for the tooltip (if any).
   */
  renderTableHeader = (field, label, sortable, tooltip) => {
    return (
      <th
        key={field}
        onClick={() => {
          if (sortable) {
            this.handleSortClick(field);
          }
        }}
        className={sortable ? 'pr-3' : ''}
        style={{ cursor: sortable ? 'pointer' : 'default' }}>
        {sortable && (
          <React.Fragment>
            {/* // TODO: move inline styling out */}
            <div style={{ position: 'relative' }}>
              <i className="fas fa-sort float-right my-1" style={{ color: '#b8b8b8', position: 'absolute', right: '-12px' }}></i>
              {this.state.tableQuery.orderBy === field && this.state.tableQuery.sortDirection === 'asc' && (
                <span>
                  <i className="fas fa-sort-up float-right my-1" style={{ position: 'absolute', right: '-12px' }}></i>
                </span>
              )}
              {this.state.tableQuery.orderBy === field && this.state.tableQuery.sortDirection === 'desc' && (
                <span>
                  <i className="fas fa-sort-down float-right my-1" style={{ position: 'absolute', right: '-12px' }}></i>
                </span>
              )}
            </div>
          </React.Fragment>
        )}
        <span>{label}</span>
        {tooltip && <InfoTooltip tooltipTextKey={tooltip} location="right"></InfoTooltip>}
      </th>
    );
  };

  render() {
    return (
      <React.Fragment>
        {this.props.isLoading && (
          <div className="text-center" style={{ height: '0' }}>
            <Spinner variant="secondary" animation="border" size="lg" />
          </div>
        )}
        <Table striped bordered hover size="sm" className="m-2">
          <thead>
            <tr>
              {this.props.columnData.map(data => {
                return this.renderTableHeader(data.field, data.label, data.isSortable, data.tooltip);
              })}
              {this.props.isEditable && <th>Edit</th>}
              <th>
                <input
                  type="checkbox"
                  onChange={this.toggleSelectAll}
                  checked={this.state.selectAll || this.props.selectedRows.length >= this.state.pagination.entries}></input>
              </th>
            </tr>
          </thead>
          <tbody>
            {this.props.rowData.length === 0 && (
              <tr className="odd">
                <td className="text-center">No data available in table.</td>
              </tr>
            )}
            {this.props.rowData.map((data, row) => {
              return (
                <tr key={data.id}>
                  {Object.values(this.props.columnData).map((col, index) => {
                    // If this column has value options, use the data value as a key to those options
                    const value = col.options ? col.options[data[col.field]] : data[col.field];
                    return <td key={index}>{value}</td>;
                  })}
                  {this.props.isEditable && (
                    <td>
                      <div className="float-left edit-button" onClick={() => this.handleEditClick(row)}>
                        <i className="fas fa-edit"></i>
                      </div>
                    </td>
                  )}
                  <td>
                    <input
                      type="checkbox"
                      checked={this.state.selectAll || this.props.selectedRows.includes(row)}
                      onChange={e => this.handleCheckboxChange(e, row)}></input>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
        <div className="d-flex justify-content-between">
          <Form inline className="align-middle">
            <Row>
              <Col>
                <InputGroup>
                  <InputGroup.Prepend>
                    <InputGroup.Text className="rounded-0">
                      <i className="fas fa-list"></i>
                      <span className="ml-1">Show</span>
                    </InputGroup.Text>
                  </InputGroup.Prepend>
                  <Form.Control as="select" size="md" name="entries" value={this.state.pagination.entries} onChange={this.handleNumEntriesChange}>
                    {this.state.pagination.entryOptions.map(num => {
                      return (
                        <option key={num} value={num}>
                          {num}
                        </option>
                      );
                    })}
                  </Form.Control>
                </InputGroup>
              </Col>
              <Col>
                <span className="ml-2 text-nowrap">{`Displaying ${this.props.rowData.length} out of ${this.props.totalRows} rows.`}</span>
              </Col>
            </Row>
          </Form>
          <ReactPaginate
            className=""
            pageCount={Math.ceil(this.props.totalRows / this.state.pagination.entries)}
            pageRangeDisplayed={4}
            marginPagesDisplayed={1}
            initialPage={this.props.page}
            onPageChange={this.props.handlePageUpdate}
            previousLabel="Previous"
            nextLabel="Next"
            breakLabel="..."
            containerClassName="pagination mb-0"
            activeClassName="active"
            disabledClassName="disabled"
            pageClassName="paginate_button page-item"
            previousClassName="paginate_button page-item"
            nextClassName="paginate_button page-item"
            breakClassName="paginate_button page-item"
            pageLinkClassName="page-link text-primary"
            previousLinkClassName={this.props.page === 0 ? 'page-link' : 'page-link text-primary'}
            nextLinkClassName={this.props.page === Math.ceil(this.props.totalRows / this.state.pagination.entries) - 1 ? 'page-link' : 'page-link text-primary'}
            activeLinkClassName="page-link text-light"
            breakLinkClassName="page-link text-primary"
          />
        </div>
      </React.Fragment>
    );
  }
}

ActionTable.propTypes = {
  columnData: PropTypes.array,
  rowData: PropTypes.array,
  totalRows: PropTypes.number,
  isEditable: PropTypes.bool,
  handleEdit: PropTypes.func,
  handleTableUpdate: PropTypes.func,
  handleSelect: PropTypes.func,
  handlePageUpdate: PropTypes.func,
  actions: PropTypes.object,
  isLoading: PropTypes.bool,
  page: PropTypes.number,
  selectedRows: PropTypes.array,
};

ActionTable.defaultProps = {
  handleEdit: () => {},
  handleTableUpdate: () => {},
  handleSelect: () => {},
};

export default ActionTable;
