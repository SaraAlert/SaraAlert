import React from 'react';
import { PropTypes } from 'prop-types';
import moment from 'moment-timezone';
import _ from 'lodash';
import { formatNameAlt, formatDateOfBirthTableCell } from '../../../utils/Patient';

import { patientHref } from '../../../utils/Navigation';
import BadgeHoH from '../icons/BadgeHoH';
import CustomTable from '../../layout/CustomTable';

class HouseholdMemberTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { field: 'name', label: 'Name', isSortable: true, tooltip: null, filter: this.formatPatientName },
          { field: 'date_of_birth', label: 'Date of Birth', isSortable: true, tooltip: null, filter: this.formatDOB },
          { field: 'isolation', label: 'Workflow', isSortable: true, tooltip: null, options: { true: 'Isolation', false: 'Exposure' } },
          {
            field: 'monitoring',
            label: 'Monitoring Status',
            isSortable: true,
            tooltip: null,
            options: { true: 'Actively Monitoring', false: 'Not Monitoring' },
          },
        ],
        rowData: props.household_members,
        selectedRows: [],
        disabledRows: this.getDisabledRows(props.household_members),
        selectAll: false,
      },
      selectedIds: [],
      disabledIds: this.getDisabledIds(props.household_members),
    };
    if (props.continuous_exposure_enabled) {
      const obj = { field: 'continuous_exposure', label: 'Continuous Exposure?', isSortable: true, tooltip: null, options: { true: 'Yes', false: 'No' } };
      this.state.table.colData.push(obj);
    }
  }

  /**
   * Callback called when child Table component detects a selection change.
   * Updates the selected rows and enables/disables actions accordingly.
   * @param {Number[]} selectedRows - Array of selected row indices.
   */
  handleSelect = selectedRows => {
    const enabledRows = this.state.table.rowData.filter(row => this.validJurisdiction(row));
    const selectAll = selectedRows.length >= enabledRows.length;
    this.setState(
      state => {
        return {
          table: { ...state.table, selectedRows, selectAll },
        };
      },
      () => {
        this.updateSelectedIds();
      }
    );
  };

  /**
   * Callback called when child Table component detects a sort change.
   * @param {Object} sort - Object containing sort field and direction
   */
  handleTableSort = sort => {
    const orderBy = sort.orderBy;
    let direction = sort.sortDirection;
    let rowData = _.cloneDeep(this.state.table.rowData);
    switch (orderBy) {
      case 'name':
        rowData = this.sortByName(rowData, direction);
        break;
      case 'date_of_birth':
        rowData = this.sortByDOB(rowData, direction);
        break;
      case 'monitoring':
        // flop the order by to account for the boolean words to be alphabetical
        direction = direction === 'asc' ? 'desc' : 'asc';
        rowData = this.sortByBooleanField(rowData, orderBy, direction);
        break;
      default:
        rowData = this.sortByBooleanField(rowData, orderBy, direction);
    }

    const selectedRows = this.updateSelectedRows(rowData);
    const disabledRows = this.updateDisabledRows(rowData);
    this.setState(state => {
      return {
        table: { ...state.table, rowData, selectedRows, disabledRows },
      };
    });
  };

  /**
   * Sorts array of monitorees by name (first name, then last name)
   * @param {Object[]} patients - array of patient objects
   * @param {String} direction - direction in which to sort
   */
  sortByName = (patients, direction) => {
    if (direction === 'asc') {
      patients
        .sort((a, b) => {
          return a.first_name.localeCompare(b.first_name);
        })
        .sort((a, b) => {
          return a.last_name.localeCompare(b.last_name);
        });
    } else if (direction === 'desc') {
      patients
        .sort((a, b) => {
          return b.first_name.localeCompare(a.first_name);
        })
        .sort((a, b) => {
          return b.last_name.localeCompare(a.last_name);
        });
    }
    return patients;
  };

  /**
   * Sorts array of monitorees by date of birth
   * @param {Object[]} patients - array of patient objects
   * @param {String} direction - direction in which to sort
   */
  sortByDOB = (patients, direction) => {
    if (direction === 'asc') {
      patients.sort((a, b) => {
        return moment(a.date_of_birth).format('YYYYMMDD') - moment(b.date_of_birth).format('YYYYMMDD');
      });
    } else {
      patients.sort((a, b) => {
        return moment(b.date_of_birth).format('YYYYMMDD') - moment(a.date_of_birth).format('YYYYMMDD');
      });
    }
    return patients;
  };

  /**
   * Sorts array of monitorees by a specified boolean field on the patient
   * @param {Object[]} patients - array of patient objects
   * @param {String} field - field in which to sort by
   * @param {String} direction - direction in which to sort
   */
  sortByBooleanField = (patients, field, direction) => {
    if (direction === 'asc') {
      patients.sort((a, b) => {
        // string conversion necessary to avoid eslint Generic Object Injection Sink warning
        return a[`${field}`] - b[`${field}`];
      });
    } else {
      patients.sort((a, b) => {
        // string conversion necessary to avoid eslint Generic Object Injection Sink warning
        return b[`${field}`] - a[`${field}`];
      });
    }
    return patients;
  };

  /**
   * Called when child table detects a change in selection and the selectedRows change
   * Updates the array of monitoree selectedIds and sends them to parent component
   */
  updateSelectedIds = () => {
    let selectedIds = [];
    this.state.table.rowData.forEach((row, index) => {
      if (this.state.table.selectedRows.includes(index)) {
        selectedIds.push(row.id);
      }
    });
    this.setState({ selectedIds }, () => {
      this.props.handleApplyHouseholdIdsChange(selectedIds);
    });
  };

  /**
   * Called when child table detects a change in sort and persists the selectedRows
   * Updates the array of selectedRows based on the array of selectedIds
   * @param {Object[]} rowData - array of patient objects
   */
  updateSelectedRows = rowData => {
    let selectedRows = [];
    rowData.forEach((row, index) => {
      if (this.state.selectedIds.includes(row.id)) {
        selectedRows.push(index);
      }
    });
    return selectedRows;
  };

  /**
   * Called when child table detects a change in sort and persists the disabledRows
   * Updates the array of disabledRows based on the array of disabledIds
   * @param {Object[]} rowData - array of patient objects
   */
  updateDisabledRows = rowData => {
    let disabledRows = [];
    rowData.forEach((row, index) => {
      if (this.state.disabledIds.includes(row.id)) {
        disabledRows.push(index);
      }
    });
    return disabledRows;
  };

  /**
   * Generates list of initial disabledRows based on if jurisdiction is valid
   * @param {Object[]} householdMembers - array of patient objects
   */
  getDisabledRows = householdMembers => {
    let disabledRows = [];
    householdMembers.forEach((member, index) => {
      if (!this.validJurisdiction(member)) {
        disabledRows.push(index);
      }
    });
    return disabledRows;
  };

  /**
   * Generates list of initial disabledIds based on if jurisdiction is valid
   * @param {Object[]} householdMembers - array of patient objects
   */
  getDisabledIds = householdMembers => {
    let disabledIds = [];
    householdMembers.forEach(member => {
      if (!this.validJurisdiction(member)) {
        disabledIds.push(member.id);
      }
    });
    return disabledIds;
  };

  /**
   * Returns boolean if patient jurisdiction falls within current user's domain
   * @param {Object} patient - patient object
   */
  validJurisdiction = patient => {
    let isValid = true;
    const jurisdiction = this.props.jurisdiction_paths[patient.jurisdiction_id];
    if (_.isNil(jurisdiction)) {
      isValid = false;
    } else {
      const jurisdictionArray = jurisdiction.split(', ');
      this.props.current_user.jurisdiction_path.forEach((path, index) => {
        if (path !== jurisdictionArray[parseInt(index)]) {
          isValid = false;
        }
      });
    }
    return isValid;
  };

  /**
   * Formats monitoree name into consistent format.
   * Creates a link (if jurisdication is valid) and renders HoH badge for monitoree name in table.
   * @param {Object} data - provided by CustomTable about each cell in the column this filter is called in.
   */
  formatPatientName = data => {
    const rowData = data.rowData;
    const monitoreeName = formatNameAlt(rowData);

    return (
      <React.Fragment>
        {/* Visually, this Badge is floated to the right. Semantically you would expect it to come after the anchor below */}
        {/* However, following user feedback, it is easier to hear "Head of Household" before the monitoree's name (if applicable) */}
        {rowData.head_of_household && <BadgeHoH patientId={rowData.id.toString()} customClass={'float-right ml-1'} location={'right'} />}
        <a
          id={rowData.head_of_household ? 'dependent-hoh-link' : null}
          href={patientHref(rowData.id, this.props.workflow)}
          target={this.props.isSelectable ? '_blank' : '_self'}
          rel="noreferrer">
          {monitoreeName}
        </a>
      </React.Fragment>
    );
  };

  formatDOB = data => {
    return formatDateOfBirthTableCell(data.rowData.date_of_birth, data.rowData.id);
  };

  /**
   * Formats aria label for each table row checkbox.
   * @param {Object} rowData - provided by CustomTable about the current row.
   */
  getRowCheckboxAriaLabel(rowData) {
    return `Monitoree ${formatNameAlt(rowData)}`;
  }

  render() {
    return (
      <CustomTable
        title="Household Members"
        dataType="household-members"
        columnData={this.state.table.colData}
        rowData={this.state.table.rowData}
        totalRows={this.state.table.totalRows}
        handleTableUpdate={this.handleTableSort}
        handleSelect={this.handleSelect}
        getRowCheckboxAriaLabel={this.getRowCheckboxAriaLabel}
        isSelectable={this.props.isSelectable}
        showPagination={false}
        checkboxColumnLocation={'left'}
        selectedRows={this.state.table.selectedRows}
        selectAll={this.state.table.selectAll}
        disabledRows={this.state.table.disabledRows}
        disabledTooltipText={'You cannot update this record since it is not within your assigned jurisdiction'}
      />
    );
  }
}

HouseholdMemberTable.propTypes = {
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  isSelectable: PropTypes.bool,
  handleApplyHouseholdChange: PropTypes.func,
  handleApplyHouseholdIdsChange: PropTypes.func,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default HouseholdMemberTable;
