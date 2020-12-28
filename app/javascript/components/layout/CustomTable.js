import React from 'react';
import { PropTypes } from 'prop-types';
import { Spinner, Table, Form, InputGroup, Row, Col } from 'react-bootstrap';
import ReactPaginate from 'react-paginate';
import InfoTooltip from '../util/InfoTooltip';

class CustomTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tableQuery: {
        orderBy: '',
        sortDirection: '',
      },
    };
  }

  /**
   * Called when a sorting button is clicked in a column header.
   * Toggles sort direction and updates the table based on the clicked column field.
   * @param {String} field - Field that is being sorted on.
   */
  handleSortClick = field => {
    this.setState(
      state => {
        const sortDirection = state.tableQuery.sortDirection === 'asc' ? 'desc' : 'asc';
        const tableQuery = { ...state.tableQuery, sortDirection, orderBy: field, page: 0 };
        return { tableQuery };
      },
      () => {
        this.props.handleTableUpdate({ ...this.state.tableQuery });
      }
    );
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

      // Call parent handler
      this.props.handleSelect(selectedRows);
    } else {
      // Otherwise if it was unchecked, remove it from the selected rows and toggle off select all if applicable.
      const selectedRows = [...this.props.selectedRows];
      const index = selectedRows.indexOf(row);
      selectedRows.splice(index, 1);

      // Call parent handler
      this.props.handleSelect(selectedRows);
    }
  };

  /**
   * Called when the checkbox in the table header is clicked and either selects all rows
   * or deselects all rows based on the current selectAll value.
   */
  toggleSelectAll = () => {
    const selectedRows = this.props.selectAll ? [] : [...Array(this.props.rowData.length).keys()];
    // Call parent handler
    this.props.handleSelect(selectedRows);
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
   * @param {String} icon - Icon class for the header (if any)
   * @param {String} colWidth - Width of the column (if any)
   */
  renderTableHeader = (field, label, sortable, tooltip, icon, colWidth) => {
    return (
      <th
        key={field}
        width={colWidth}
        onClick={() => {
          if (sortable) {
            this.handleSortClick(field);
          }
        }}
        className={sortable ? 'pr-3 pointer-cursor' : ''}>
        {sortable && (
          <React.Fragment>
            <div className="sort-header">
              <i className="fas fa-sort float-right my-1 sort-header__button--default"></i>
              {this.state.tableQuery.orderBy === field && this.state.tableQuery.sortDirection === 'asc' && (
                <span>
                  <i className="fas fa-sort-up float-right my-1 sort-header__button--selected"></i>
                </span>
              )}
              {this.state.tableQuery.orderBy === field && this.state.tableQuery.sortDirection === 'desc' && (
                <span>
                  <i className="fas fa-sort-down float-right my-1 sort-header__button--selected"></i>
                </span>
              )}
            </div>
          </React.Fragment>
        )}
        <span>{label}</span>
        {icon && (
          <div className="text-center ml-0">
            <i className={`fa-fw ${icon}`}></i>
          </div>
        )}
        {tooltip && <InfoTooltip tooltipTextKey={tooltip} location="right"></InfoTooltip>}
      </th>
    );
  };

  render() {
    return (
      <React.Fragment>
        {this.props.isLoading && (
          <div className="text-center" style={{ height: '0', top: '30%' }}>
            <Spinner variant="secondary" animation="border" size="lg" />
          </div>
        )}
        <div className={this.props.getCustomTableClassName ? `table-responsive ${this.props.getCustomTableClassName()}` : 'table-responsive'}>
          <Table striped bordered hover size="sm">
            <thead>
              <tr>
                {this.props.columnData.map(data => {
                  return this.renderTableHeader(data.field, data.label, data.isSortable, data.tooltip, data.icon, data.colWidth);
                })}
                {this.props.isEditable && <th>Edit</th>}
                {this.props.isSelectable && (
                  <th>
                    <input type="checkbox" onChange={this.toggleSelectAll} checked={this.props.selectAll}></input>
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {this.props.rowData?.map((rowData, rowIndex) => {
                return (
                  <tr key={rowIndex} id={rowData.id ? rowData.id : rowIndex} className={this.props.getRowClassName ? this.props.getRowClassName(rowData) : ''}>
                    {Object.values(this.props.columnData).map((colData, colIndex) => {
                      let value = rowData[colData.field];
                      if (colData.options) {
                        // If this column has value options, use the data value as a key to those options
                        value = colData.options[rowData[colData.field]];
                      } else if (colData.filter) {
                        // If this column has a filter function to be applied, send along data for filter to use as it wishes
                        const filterData = { value: value, rowData: rowData, colData: colData, rowIndex: rowIndex, colIndex: colIndex };
                        value = colData.filter(filterData);
                      }
                      return (
                        <td key={colIndex} className={colData.className ? colData.className : ''}>
                          {colData.onClick && <span onClick={() => (colData.onClick(rowData.id.toString()) ? colData.onClick : null)}>{value}</span>}
                          {!colData.onClick && value}
                        </td>
                      );
                    })}
                    {this.props.isEditable && (
                      <td>
                        <div className="float-left edit-button" onClick={() => this.handleEditClick(rowIndex)}>
                          <i className="fas fa-edit"></i>
                        </div>
                      </td>
                    )}
                    {this.props.isSelectable && (
                      <td>
                        <input
                          type="checkbox"
                          aria-label="Table Select Monitoree Row"
                          checked={this.props.selectAll || this.props.selectedRows.includes(rowIndex)}
                          onChange={e => this.handleCheckboxChange(e, rowIndex)}></input>
                      </td>
                    )}
                  </tr>
                );
              })}
              {!this.props.rowData?.length && (
                <tr>
                  <td colSpan={this.props.columnData?.length} className="text-center">
                    No data available in table.
                  </td>
                </tr>
              )}
            </tbody>
          </Table>
        </div>
        <div className="d-flex justify-content-between">
          <Form inline className="align-middle">
            <Row className="fixed-row-size">
              <Col>
                <InputGroup>
                  <InputGroup.Prepend>
                    <InputGroup.Text className="rounded-0">
                      <i className="fas fa-list"></i>
                      <span className="ml-1">Show</span>
                    </InputGroup.Text>
                  </InputGroup.Prepend>
                  <Form.Control
                    as="select"
                    size="md"
                    name="entries"
                    value={this.props.entries}
                    onChange={this.props.handleEntriesChange}
                    aria-label="Adjust number of records">
                    {this.props.entryOptions.map(num => {
                      return (
                        <option key={num} value={num}>
                          {num}
                        </option>
                      );
                    })}
                  </Form.Control>
                </InputGroup>
              </Col>
              <span className="ml-2 text-nowrap align-self-center">{`Displaying ${this.props.rowData.length} out of ${this.props.totalRows} rows.`}</span>
            </Row>
          </Form>
          {this.props.totalRows > 0 && (
            <ReactPaginate
              className=""
              disableInitialCallback={true}
              pageCount={Math.ceil(this.props.totalRows / this.props.entries)}
              pageRangeDisplayed={4}
              marginPagesDisplayed={1}
              initialPage={this.props.page}
              forcePage={this.props.page}
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
              nextLinkClassName={this.props.page === Math.ceil(this.props.totalRows / this.props.entries) - 1 ? 'page-link' : 'page-link text-primary'}
              activeLinkClassName="page-link text-light"
              breakLinkClassName="page-link text-primary"
            />
          )}
        </div>
      </React.Fragment>
    );
  }
}

CustomTable.propTypes = {
  columnData: PropTypes.array,
  rowData: PropTypes.array,
  totalRows: PropTypes.number,
  selectedRows: PropTypes.array,
  selectAll: PropTypes.bool,
  isEditable: PropTypes.bool,
  isSelectable: PropTypes.bool,
  handleEdit: PropTypes.func,
  handleTableUpdate: PropTypes.func,
  handleSelect: PropTypes.func,
  handlePageUpdate: PropTypes.func,
  handleEntriesChange: PropTypes.func,
  actions: PropTypes.object,
  isLoading: PropTypes.bool,
  page: PropTypes.number,
  entries: PropTypes.number,
  entryOptions: PropTypes.array,
  getRowClassName: PropTypes.func,
  getCustomTableClassName: PropTypes.func,
};

CustomTable.defaultProps = {
  handleEdit: () => {},
  handleTableUpdate: () => {},
  handleSelect: () => {},
};

export default CustomTable;
