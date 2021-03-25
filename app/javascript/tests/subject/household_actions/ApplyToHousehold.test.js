import React from 'react';
import { shallow, mount } from 'enzyme';
import { Form } from 'react-bootstrap';
import _ from 'lodash';
import ApplyToHousehold from '../../../components/subject/household_actions/ApplyToHousehold.js';
import CustomTable from '../../../components/layout/CustomTable';
import BadgeHOH from '../../../components/util/BadgeHOH';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5 } from '../../mocks/mockPatients';
import { nameFormatterAlt, formatDate, sortByNameAscending, sortByNameDescending, sortByDateAscending, sortByDateDescending, sortByAscending, sortByDescending } from '../../util.js';

const householdMembers = [ mockPatient1, mockPatient2, mockPatient3, mockPatient4 ];
const handleApplyHouseholdChangeMock = jest.fn();
const handleApplyHouseholdIdsChangeMock = jest.fn();

function getWrapper() {
  return shallow(<ApplyToHousehold household_members={householdMembers} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths}
    handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} />);
}

function getMountedWrapper() {
  return mount(<ApplyToHousehold household_members={householdMembers} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths}
    handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} />);
}

beforeEach(() => {
  window.BASE_PATH = ""
})

afterEach(() => {
  jest.clearAllMocks();
});

describe('ApplyToHousehold', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('p').text()).toEqual('Apply this change to:');
    expect(wrapper.find(Form.Group).exists()).toBeTruthy();
    expect(wrapper.find(Form.Check).length).toEqual(2);
    expect(wrapper.find('#apply_to_household_no').prop('label')).toEqual('This monitoree only');
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('label')).toEqual('This monitoree and selected household members');
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
  });

  it('Clicking "Apply to Household" radio button shows table of household members', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
  });

  it('Clicking radio buttons updates state and calls handleApplyHouseholdChange prop', () => {
    const wrapper = getWrapper();
    expect(handleApplyHouseholdChangeMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('applyToHousehold')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(handleApplyHouseholdChangeMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('applyToHousehold')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeTruthy();
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(handleApplyHouseholdChangeMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('applyToHousehold')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
  });

  it('Properly renders household members table header', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find('thead').exists()).toBeTruthy();
    expect(wrapper.find('th').length).toEqual(wrapper.state('table').colData.length + 1);
    expect(wrapper.find('th').at(0).find('input').exists).toBeTruthy();
    expect(wrapper.find('th').at(0).find('input').prop('checked')).toBeFalsy();
    wrapper.state('table').colData.forEach((colData, index) => {
      expect(wrapper.find('th').at(index+1).find('span').text()).toEqual(colData.label);
      if (colData.isSortable) {
        expect(wrapper.find('th').at(index+1).find('.sort-header').exists()).toBeTruthy();
      } else {
        expect(wrapper.find('th').at(index+1).find('.sort-header').exists()).toBeFalsy();
      }
    });
  });

  it('Properly renders household members table body', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find('tbody').exists()).toBeTruthy();
    expect(wrapper.find('tbody').find('tr').length).toEqual(wrapper.state('table').rowData.length);
    wrapper.state('table').rowData.forEach((rowData, index) => {
      const row = wrapper.find('tbody').find('tr').at(index);
      expect(row.find('td').at(0).find('input').exists).toBeTruthy();
      expect(row.find('td').at(0).find('input').prop('checked')).toBeFalsy();
      expect(row.find('td').at(1).find('a').exists()).toBeTruthy();
      expect(row.find('td').at(1).find('a').prop('href')).toEqual(`${window.BASE_PATH}/patients/${rowData.id}`);
      expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(rowData));
      if (rowData.id === rowData.responder_id) {
        expect(row.find('td').at(1).find(BadgeHOH).exists()).toBeTruthy();
      } else {
        expect(row.find('td').at(1).find(BadgeHOH).exists()).toBeFalsy();
      }
      expect(row.find('td').at(2).text()).toEqual(formatDate(rowData[wrapper.state('table').colData[1].field]));
      expect(row.find('td').at(3).text()).toEqual(rowData[wrapper.state('table').colData[2].field] ? 'Isolation' : 'Exposure');
      expect(row.find('td').at(4).text()).toEqual(rowData[wrapper.state('table').colData[3].field] ? 'Actively Monitoring' : 'Not Monitoring');
      expect(row.find('td').at(5).text()).toEqual(rowData[wrapper.state('table').colData[4].field] ? 'Yes' : 'No');
    });
  });

  it('Hides pagingation controls of CustomTable', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find('#pagination-container').exists()).toBeFalsy();
  });

  it('Clicking select all button updates checkbox values and state', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual([ ]);
    expect(wrapper.state('selectedIds')).toEqual([ ]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBeFalsy();
    });
    wrapper.find('th').find('input').simulate('change');
    expect(wrapper.state('table').selectAll).toBeTruthy();
    expect(wrapper.state('table').selectedRows).toEqual([ 0, 1, 2, 3 ]);
    expect(wrapper.state('selectedIds')).toEqual([ mockPatient1.id, mockPatient2.id, mockPatient3.id, mockPatient4.id ]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBeTruthy();
    });
    wrapper.find('th').find('input').simulate('change');
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual([ ]);
    expect(wrapper.state('selectedIds')).toEqual([ ]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBeFalsy();
    });
  });

  it('Clicking individual row checkboxes updates checkbox values and state', () => {
    const wrapper = getMountedWrapper();
    let selectedRows = [];
    let selectedIds = [];
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual([ ]);
    expect(wrapper.state('selectedIds')).toEqual([ ]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBeFalsy();
    });
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      row.find('input').simulate('change', { target: { checked: true } });
      selectedRows.push(index);
      selectedIds.push(householdMembers[index].id);
      expect(wrapper.state('table').selectAll).toEqual(householdMembers.length - 1 === index);
      expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
      expect(wrapper.state('selectedIds')).toEqual(selectedIds);
      wrapper.find('tr').forEach((row, index) => {
        expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index-1) || selectedRows.length === householdMembers.length);
      });
    });
    wrapper.find('tbody').find('tr').forEach(row => {
      row.find('input').simulate('change', { target: { checked: false } });
      selectedRows.shift();
      selectedIds.shift();
      expect(wrapper.state('table').selectAll).toBeFalsy();
      expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
      expect(wrapper.state('selectedIds')).toEqual(selectedIds);
      wrapper.find('tr').forEach((row, index) => {
        expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index-1));
      });
    });
  });

  it('Clicking table headers calls handleTableSort method', () => {
    const wrapper = getMountedWrapper();
    const sortSpy = jest.spyOn(wrapper.instance(), 'handleTableSort');
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(sortSpy).toHaveBeenCalledTimes(0);
    wrapper.state('table').colData.forEach((colData, index) => {
      if (colData.isSortable) {
        wrapper.find('th').at(index+1).simulate('click');
        expect(sortSpy).toHaveBeenCalledTimes(2*(index+1)-1);
        expect(sortSpy).toHaveBeenCalledWith({ orderBy: colData.field, sortDirection: 'asc', page: 0 });
        wrapper.find('th').at(index+1).simulate('click');
        expect(sortSpy).toHaveBeenCalledTimes(2*(index+1));
        expect(sortSpy).toHaveBeenCalledWith({ orderBy: colData.field, sortDirection: 'desc', page: 0 });
      }
    });
  });

  it('Properly sorts table by name', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('th').at(1).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByNameAscending(householdMembers));
    wrapper.find('th').at(1).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByNameDescending(householdMembers));
  });

  it('Properly sorts table by DOB', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('th').at(2).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDateAscending(householdMembers, 'date_of_birth'));
    wrapper.find('th').at(2).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDateDescending(householdMembers, 'date_of_birth'));
  });

  it('Properly sorts table by workflow', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('th').at(3).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByAscending(householdMembers, 'isolation'));
    wrapper.find('th').at(3).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDescending(householdMembers, 'isolation'));
  });

  it('Properly sorts table by monitoring status', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('th').at(4).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDescending(householdMembers, 'monitoring'));
    wrapper.find('th').at(4).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByAscending(householdMembers, 'monitoring'));
  });

  it('Properly sorts table by continuous exposure', () => {
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('th').at(5).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByAscending(householdMembers, 'continuous_exposure'));
    wrapper.find('th').at(5).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDescending(householdMembers, 'continuous_exposure'));
  });

  it('Maintains table state (sort and selected monitorees) when toggling radio buttons', () => {
    let sortedHouseholdMembers = sortByDateDescending(householdMembers, 'date_of_birth');
    let random = _.random(0, householdMembers.length - 1);
    let selectedRows = [ random ];
    let selectedIds = [ sortedHouseholdMembers[random].id ];

    // setup and checking intial table state
    const wrapper = getMountedWrapper();
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('th').at(2).simulate('click');
    wrapper.find('th').at(2).simulate('click');
    wrapper.find('tbody').find('tr').at(random).find('input').simulate('change', { target: { checked: true } });
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.find('thead').find('input').prop('checked')).toBeFalsy();
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
      expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
    });

    // toggle apply to household and check that the table state is the same
    wrapper.find('#apply_to_household_no').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
      expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
    });
  });

  it('Sorting household members table maintains selected and disabled rows', () => {
    householdMembers.push(mockPatient5);
    let selectedRows = [ 0 , 2 ];
    let selectedIds = [ householdMembers[0].id, householdMembers[2].id ];
    let disabledRows = [ 4 ];
    let disabledIds = [ householdMembers[4].id ];
    const wrapper = mount(<ApplyToHousehold household_members={householdMembers} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths}
      handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} />);

    // initial load
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    selectedRows.forEach(rowId => {
      wrapper.find('tbody').find('tr').at(rowId).find('input').simulate('change', { target: { checked: true } });
    });
    expect(wrapper.state('table').rowData).toEqual(householdMembers);
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.state('table').disabledRows).toEqual(disabledRows);
    expect(wrapper.state('disabledIds')).toEqual(disabledIds)
    expect(wrapper.find('thead').find('input').prop('checked')).toBeFalsy();
    expect(wrapper.find('thead').find('input').prop('disabled')).toBeFalsy();
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
      expect(row.find('input').prop('disabled')).toEqual(disabledRows.includes(index));
      if (disabledRows.includes(index)) {
        expect(row.find('td').at(1).find('div').text()).toEqual(nameFormatterAlt(householdMembers[index]));
      } else {
        expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(householdMembers[index]));
      }
    });

    // sort by name, asc
    let sortedHouseholdMembers = sortByNameAscending(householdMembers);
    selectedRows = [ 1, 4 ];
    disabledRows = [ 0 ];
    wrapper.find('th').at(1).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.state('table').disabledRows).toEqual(disabledRows);
    expect(wrapper.state('disabledIds')).toEqual(disabledIds)
    expect(wrapper.find('thead').find('input').prop('checked')).toBeFalsy();
    expect(wrapper.find('thead').find('input').prop('disabled')).toBeFalsy();
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
      expect(row.find('input').prop('disabled')).toEqual(disabledRows.includes(index));
      if (disabledRows.includes(index)) {
        expect(row.find('td').at(1).find('div').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
      } else {
        expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
      }
    });

    // sort by DOB, desc
    sortedHouseholdMembers = sortByDateDescending(sortedHouseholdMembers, 'date_of_birth');
    selectedRows = [ 0, 2 ];
    disabledRows = [ 4 ];
    wrapper.find('th').at(2).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.state('table').disabledRows).toEqual(disabledRows);
    expect(wrapper.state('disabledIds')).toEqual(disabledIds)
    expect(wrapper.find('thead').find('input').prop('checked')).toBeFalsy();
    expect(wrapper.find('thead').find('input').prop('disabled')).toBeFalsy();
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
      expect(row.find('input').prop('disabled')).toEqual(disabledRows.includes(index));
      if (disabledRows.includes(index)) {
        expect(row.find('td').at(1).find('div').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
      } else {
        expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
      }
    });

    // sort by workflow, asc
    sortedHouseholdMembers = sortByAscending(sortedHouseholdMembers, 'isolation');
    selectedRows = [ 3, 4 ];
    disabledRows = [ 2 ];
    wrapper.find('th').at(3).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBeFalsy();
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.state('table').disabledRows).toEqual(disabledRows);
    expect(wrapper.state('disabledIds')).toEqual(disabledIds)
    expect(wrapper.find('thead').find('input').prop('checked')).toBeFalsy();
    expect(wrapper.find('thead').find('input').prop('disabled')).toBeFalsy();
    wrapper.find('tbody').find('tr').forEach((row, index) => {
      expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
      expect(row.find('input').prop('disabled')).toEqual(disabledRows.includes(index));
      if (disabledRows.includes(index)) {
        expect(row.find('td').at(1).find('div').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
      } else {
        expect(row.find('td').at(1).find('a').text()).toEqual(nameFormatterAlt(sortedHouseholdMembers[index]));
      }
    });
  });
});