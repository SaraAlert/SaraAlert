import React from 'react';
import { PropTypes } from 'prop-types';
import { Form } from 'react-bootstrap';
import moment from 'moment-timezone';
import _ from 'lodash';

import CustomTable from '../../layout/CustomTable';
import BadgeHOH from '../../util/BadgeHOH';

class ApplyToHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { field: 'name', label: 'Name', isSortable: true, tooltip: null, filter: this.formatPatientName },
          { field: 'date_of_birth', label: 'Date of Birth', isSortable: true, tooltip: null, filter: this.formatDate },
          { field: 'isolation', label: 'Workflow', isSortable: true, tooltip: null, filter: this.formatWorkflow },
          { field: 'monitoring', label: 'Monitoring Status', isSortable: true, tooltip: null, filter: this.formatMonitoring },
          { field: 'continuous_exposure', label: 'Continuous Exposure?', isSortable: true, tooltip: null, filter: this.formatContinuousExposure },
        ],
        rowData: props.household_members,
        selectedRows: [],
        disabledRows: this.getDisabledRows(props.household_members),
        selectAll: false,
      },
      applyToHousehold: false,
      selectedIds: [],
      disabledIds: this.getDisabledIds(props.household_members),
    };
  }

  handleChange = event => {
    let applyToHousehold = event.target.id === 'apply_to_household_yes';
    this.setState({ applyToHousehold }, () => {
      this.props.handleApplyHouseholdChange(applyToHousehold);
    });
  };

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

  getDisabledRows = householdMembers => {
    let disabledRows = [];
    householdMembers.forEach((member, index) => {
      if (!this.validJurisdiction(member)) {
        disabledRows.push(index);
      }
    });
    return disabledRows;
  };

  getDisabledIds = householdMembers => {
    let disabledIds = [];
    householdMembers.forEach(member => {
      if (!this.validJurisdiction(member)) {
        disabledIds.push(member.id);
      }
    });
    return disabledIds;
  };

  validJurisdiction = patient => {
    let isValid = true;
    const jurisdiction = this.props.jurisdiction_paths[patient.jurisdiction_id];
    if (_.isNil(jurisdiction)) {
      isValid = false;
    } else {
      const jurisdictionArray = jurisdiction.split(', ');
      this.props.current_user.jurisdiction_path.forEach((path, index) => {
        if (path !== jurisdictionArray[index]) {
          isValid = false;
        }
      });
    }
    return isValid;
  };

  handleTableSort = sort => {
    const orderBy = sort.orderBy;
    const direction = sort.sortDirection;
    let rowData = _.cloneDeep(this.state.table.rowData);
    if (orderBy === 'name') {
      rowData = this.sortByName(rowData, direction);
    } else if (orderBy === 'date_of_birth') {
      if (direction === 'asc') {
        rowData.sort((a, b) => {
          return moment(a.date_of_birth).format('YYYYMMDD') - moment(b.date_of_birth).format('YYYYMMDD');
        });
      } else {
        rowData.sort((a, b) => {
          return moment(b.date_of_birth).format('YYYYMMDD') - moment(a.date_of_birth).format('YYYYMMDD');
        });
      }
    } else {
      if ((orderBy !== 'monitoring' && direction === 'asc') || (orderBy === 'monitoring' && direction === 'desc')) {
        rowData.sort((a, b) => {
          return a[sort.orderBy] - b[sort.orderBy];
        });
      } else if ((orderBy !== 'monitoring' && direction === 'desc') || (orderBy === 'monitoring' && direction === 'asc')) {
        rowData.sort((a, b) => {
          return b[sort.orderBy] - a[sort.orderBy];
        });
      }
    }
    const selectedRows = this.updateSelectedRows(rowData);
    const disabledRows = this.updateDisabledRows(rowData);
    this.setState(state => {
      return {
        table: { ...state.table, rowData, selectedRows, disabledRows },
      };
    });
  };

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

  updateSelectedRows = rowData => {
    let selectedRows = [];
    rowData.forEach((row, index) => {
      if (this.state.selectedIds.includes(row.id)) {
        selectedRows.push(index);
      }
    });
    return selectedRows;
  };

  updateDisabledRows = rowData => {
    let disabledRows = [];
    rowData.forEach((row, index) => {
      if (this.state.disabledIds.includes(row.id)) {
        disabledRows.push(index);
      }
    });
    return disabledRows;
  };

  formatPatientName = data => {
    const rowData = data.rowData;
    const monitoreeName = `${rowData.last_name || ''}, ${rowData.first_name || ''} ${rowData.middle_name || ''}`;

    if (rowData.id === rowData.responder_id) {
      return (
        <div>
          <BadgeHOH patientId={rowData.id.toString()} customClass={'badge-hoh ml-1'} location={'right'} />
          {this.validJurisdiction(rowData) ? (
            <a href={`/patients/${rowData.id}`} rel="noreferrer" target="_blank">
              {monitoreeName}
            </a>
          ) : (
            <div>{monitoreeName}</div>
          )}
        </div>
      );
    }
    return this.validJurisdiction(rowData) ? (
      <a href={`/patients/${rowData.id}`} rel="noreferrer" target="_blank">
        {monitoreeName}
      </a>
    ) : (
      <div>{monitoreeName}</div>
    );
  };

  formatDate(data) {
    const date = data.value;
    return date ? moment(date, 'YYYY-MM-DD').format('MM/DD/YYYY') : '';
  }

  formatWorkflow = data => {
    return <React.Fragment>{data.value ? 'Isolation' : 'Exposure'}</React.Fragment>;
  };

  formatMonitoring = data => {
    return <React.Fragment>{data.value ? 'Actively Monitoring' : 'Not Monitoring'}</React.Fragment>;
  };

  formatContinuousExposure = data => {
    return <React.Fragment>{data.value ? 'Yes' : 'No'}</React.Fragment>;
  };

  render() {
    return (
      <React.Fragment>
        <p className="mb-2">Apply this change to:</p>
        <Form.Group>
          <Form.Check
            type="radio"
            name="apply_to_household"
            id="apply_to_household_no"
            label="This monitoree only"
            onChange={this.handleChange}
            checked={!this.state.applyToHousehold}
          />
          <Form.Check
            type="radio"
            name="apply_to_household"
            id="apply_to_household_yes"
            label="This monitoree and selected household members"
            onChange={this.handleChange}
            checked={this.state.applyToHousehold}
          />
        </Form.Group>
        {this.state.applyToHousehold && (
          <CustomTable
            columnData={this.state.table.colData}
            rowData={this.state.table.rowData}
            totalRows={this.state.table.totalRows}
            handleTableUpdate={this.handleTableSort}
            isSelectable={true}
            checkboxColumnLocation={'left'}
            selectedRows={this.state.table.selectedRows}
            selectAll={this.state.table.selectAll}
            handleSelect={this.handleSelect}
            disabledRows={this.state.table.disabledRows}
            disabledTooltipText={'You cannot update this record since it is not within your assigned jurisdiction'}
          />
        )}
      </React.Fragment>
    );
  }
}

ApplyToHousehold.propTypes = {
  household_members: PropTypes.array,
  handleApplyHouseholdChange: PropTypes.func,
  handleApplyHouseholdIdsChange: PropTypes.func,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
};

export default ApplyToHousehold;
