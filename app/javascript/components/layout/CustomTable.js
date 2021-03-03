import React from 'react';
import { PropTypes } from 'prop-types';
import { Spinner, Table, Form, InputGroup } from 'react-bootstrap';
import ReactPaginate from 'react-paginate';
import ReactTooltip from 'react-tooltip';
import InfoTooltip from '../util/InfoTooltip';

class CustomTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tableQuery: {
        orderBy: props.orderBy,
        sortDirection: props.sortDirection,
      },
    };
  }

  componentDidUpdate(prevProps) {
    if (this.props.sortDirection !== prevProps.sortDirection || this.props.orderBy !== prevProps.orderBy) {
      this.setState(state => {
        const sortDirection = this.props.sortDirection;
        const orderBy = this.props.orderBy;
        const tableQuery = { ...state.tableQuery, sortDirection, orderBy };
        return { tableQuery };
      });
    }
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
    let selectedRows = this.props.selectAll ? [] : [...Array(this.props.rowData.length).keys()];
    selectedRows = selectedRows.filter(row => !this.props.disabledRows.includes(row));
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
   * Renders the select all checkbox in the header element
   * Checkbox is disabled if every entry in rowData is disabled
   */
  renderSelectAllCheckbox = () => {
    return (
      <th>
        <input
          type="checkbox"
          onChange={this.toggleSelectAll}
          disabled={this.props.disabledRows.length === this.props.rowData.length}
          checked={this.props.selectAll}
          aria-label="Table Select All Rows"></input>
      </th>
    );
  };

  /**
   * Renders the checkbox in the specified row in the table body
   * Checkbox is disabled if rowIndex is included in the disabledRows prop
   * Whether a row should be disabled is determined by the parent component
   *
   * @param {Object} rowData - Data for the row the checkbox is being rendered in.
   * @param {Number} rowIndex - Index of the row the checkbox is being rendered in.
   */
  renderRowCheckbox = (rowData, rowIndex) => {
    return (
      <td>
        <span data-for={`table-row-${rowIndex}-tooltip`} data-tip="">
          <input
            type="checkbox"
            disabled={this.props.disabledRows.includes(rowIndex)}
            aria-label={`Table Select${rowData.name ? ` Monitoree: ${rowData.name}` : ''}${this.props.currentUser ? ` User: ${this.props.currentUser}` : ''}`}
            checked={(this.props.selectAll && !this.props.disabledRows.includes(rowIndex)) || this.props.selectedRows.includes(rowIndex)}
            onChange={e => this.handleCheckboxChange(e, rowIndex)}></input>
        </span>
        {this.props.disabledRows.includes(rowIndex) && (
          <ReactTooltip id={`table-row-${rowIndex}-tooltip`} multiline={true} place="right" type="dark" effect="solid" className="tooltip-container">
            {this.props.disabledTooltipText}
          </ReactTooltip>
        )}
      </td>
    );
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
        <div
          className={
            this.props.getCustomTableClassName ? `table-responsive custom-table ${this.props.getCustomTableClassName()}` : 'table-responsive custom-table'
          }>
          <Table striped bordered hover size="sm" className="opaque-table">
            <thead>
              <tr>
                {this.props.isSelectable && this.props.checkboxColumnLocation === 'left' && this.renderSelectAllCheckbox()}
                {this.props.columnData.map(data => {
                  return this.renderTableHeader(data.field, data.label, data.isSortable, data.tooltip, data.icon, data.colWidth);
                })}
                {this.props.isEditable && <th>Edit</th>}
                {this.props.isSelectable && this.props.checkboxColumnLocation === 'right' && this.renderSelectAllCheckbox()}
              </tr>
            </thead>
            <tbody>
              {this.props.rowData?.map((rowData, rowIndex) => {
                return (
                  <tr key={rowIndex} id={rowData.id ? rowData.id : rowIndex} className={this.props.getRowClassName ? this.props.getRowClassName(rowData) : ''}>
                    {this.props.isSelectable && this.props.checkboxColumnLocation === 'left' && this.renderRowCheckbox(rowData, rowIndex)}
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
                        <div className="float-left edit-button" onClick={() => this.handleEditClick(rowIndex)} aria-label="Edit Row Button">
                          <i className="fas fa-edit"></i>
                        </div>
                      </td>
                    )}
                    {this.props.isSelectable && this.props.checkboxColumnLocation === 'right' && this.renderRowCheckbox(rowData, rowIndex)}
                  </tr>
                );
              })}
              {!this.props.rowData?.length && (
                <tr>
                  <td colSpan={this.props.columnData?.length + (this.props.isEditable ? 0 : 1) + (this.props.isSelectable ? 0 : 1)} className="text-center">
                    No data available in table.
                  </td>
                </tr>
              )}
            </tbody>
          </Table>
        </div>
        {this.props.showPagination && (
          <div id="pagination-container" className="row-container">
            <div className="left-container">
              <div className="left-box-1">
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
              </div>
              <div className="left-box-2">
                <span className="ml-0 ml-md-2 text-nowrap align-self-center">{`Displaying ${this.props.rowData.length} out of ${this.props.totalRows} rows.`}</span>
              </div>
            </div>
            <div className="right-container">
              {this.props.totalRows > 0 && (
                <div style={{ float: 'right' }}>
                  <ReactPaginate
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
                </div>
              )}
            </div>
          </div>
        )}
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
  disabledRows: PropTypes.array,
  disabledTooltipText: PropTypes.string,
  checkboxColumnLocation: PropTypes.string,
  showPagination: PropTypes.bool,
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
  currentUser: PropTypes.string,
  orderBy: PropTypes.string,
  sortDirection: PropTypes.string,
};

CustomTable.defaultProps = {
  handleEdit: () => {},
  handleTableUpdate: () => {},
  handleSelect: () => {},
  orderBy: '',
  sortDirection: '',
  disabledRows: [],
  showPagination: true,
  checkboxColumnLocation: 'right',
};

export default CustomTable;
