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
   */
  renderTableHeader = (field, label, sortable, tooltip, icon) => {
    return (
      <th
        key={field}
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
        <Table striped bordered hover size="sm">
          <thead>
            <tr>
              {this.props.columnData.map(data => {
                return this.renderTableHeader(data.field, data.label, data.isSortable, data.tooltip, data.icon);
              })}
              {this.props.isEditable && <th>Edit</th>}
              <th>
                <input type="checkbox" onChange={this.toggleSelectAll} checked={this.props.selectAll}></input>
              </th>
            </tr>
          </thead>
          <tbody>
            {this.props.rowData.map((data, row) => {
              return (
                <tr key={row} id={data.id ? data.id : row}>
                  {Object.values(this.props.columnData).map((col, index) => {
                    let value = data[col.field];
                    if (col.options) {
                      // If this column has value options, use the data value as a key to those options
                      value = col.options[data[col.field]];
                    } else if (col.filter) {
                      // If this column has a filter, apply the filter to the value
                      // Send along string of the ID and HoH bool if needed
                      value = col.filter(data[col.field], data.id.toString(), data.is_hoh);
                    }
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
                      checked={this.props.selectAll || this.props.selectedRows.includes(row)}
                      onChange={e => this.handleCheckboxChange(e, row)}></input>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
        {this.props.rowData.length === 0 && <div className="text-center">No data available in table.</div>}
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
                  <Form.Control as="select" size="md" name="entries" value={this.props.entries} onChange={this.props.handleEntriesChange}>
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
};

CustomTable.defaultProps = {
  handleEdit: () => {},
  handleTableUpdate: () => {},
  handleSelect: () => {},
};

export default CustomTable;
