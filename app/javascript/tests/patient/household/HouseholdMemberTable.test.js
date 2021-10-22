import React from 'react';
import { shallow, mount } from 'enzyme';
import HouseholdMemberTable from '../../../components/patient/household/HouseholdMemberTable';
import CustomTable from '../../../components/layout/CustomTable';
import BadgeHoH from '../../../components/patient/icons/BadgeHoH';
import IconMinor from '../../../components/patient/icons/IconMinor';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5 } from '../../mocks/mockPatients';
import { formatNameAlt, formatDate, isMinor, sortByNameAscending, sortByNameDescending, sortByDateAscending, sortByDateDescending, sortByAscending, sortByDescending } from '../../helpers.js';

const householdMembers = [mockPatient1, mockPatient2, mockPatient3, mockPatient4];
const handleApplyHouseholdChangeMock = jest.fn();
const handleApplyHouseholdIdsChangeMock = jest.fn();

function getShallowWrapper(isSelectable) {
  return shallow(<HouseholdMemberTable household_members={householdMembers} isSelectable={isSelectable} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} workflow={'global'} />);
}

function getMountedWrapper(isSelectable) {
  return mount(<HouseholdMemberTable household_members={householdMembers} isSelectable={isSelectable} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} workflow={'global'} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('HouseholdMemberTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = getShallowWrapper(true);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
  });

  it('Properly renders household members table header', () => {
    const wrapper = getMountedWrapper(true);
    expect(wrapper.find('thead').exists()).toBe(true);
    expect(wrapper.find('th').length).toEqual(wrapper.state('table').colData.length + 1);
    expect(wrapper.find('th').at(0).find('input').exists()).toBe(true);
    expect(wrapper.find('th').at(0).find('input').prop('checked')).toBe(false);
    wrapper.state('table').colData.forEach((colData, index) => {
      expect(
        wrapper
          .find('th')
          .at(index + 1)
          .find('span')
          .text()
      ).toEqual(colData.label);
      if (colData.isSortable) {
        expect(
          wrapper
            .find('th')
            .at(index + 1)
            .find('.sort-header')
            .exists()
        ).toBe(true);
      } else {
        expect(
          wrapper
            .find('th')
            .at(index + 1)
            .find('.sort-header')
            .exists()
        ).toBe(false);
      }
    });
  });

  it('Properly renders household members table body', () => {
    const wrapper = getMountedWrapper(true);
    expect(wrapper.find('tbody').exists()).toBe(true);
    expect(wrapper.find('tbody').find('tr').length).toEqual(wrapper.state('table').rowData.length);
    wrapper.state('table').rowData.forEach((rowData, index) => {
      const row = wrapper.find('tbody').find('tr').at(index);
      expect(row.find('td').at(0).find('input').exists()).toBe(true);
      expect(row.find('td').at(0).find('input').prop('checked')).toBe(false);
      expect(row.find('td').at(1).find('a').exists()).toBe(true);
      expect(row.find('td').at(1).find('a').prop('href')).toEqual(`${window.BASE_PATH}/patients/${rowData.id}?nav=global`);
      expect(row.find('td').at(1).find('a').text()).toEqual(formatNameAlt(rowData));
      if (rowData.head_of_household) {
        expect(row.find('td').at(1).find(BadgeHoH).exists()).toBe(true);
      } else {
        expect(row.find('td').at(1).find(BadgeHoH).exists()).toBe(false);
      }
      expect(row.find('td').at(2).text()).toContain(formatDate(rowData[wrapper.state('table').colData[1].field]));
      if (isMinor(rowData.date_of_birth)) {
        expect(row.find('td').at(2).find(IconMinor).exists()).toBe(true);
      } else {
        expect(row.find('td').at(2).find(IconMinor).exists()).toBe(false);
      }
      expect(row.find('td').at(3).text()).toEqual(rowData[wrapper.state('table').colData[2].field] ? 'Isolation' : 'Exposure');
      expect(row.find('td').at(4).text()).toEqual(rowData[wrapper.state('table').colData[3].field] ? 'Actively Monitoring' : 'Not Monitoring');
      expect(row.find('td').at(5).text()).toEqual(rowData[wrapper.state('table').colData[4].field] ? 'Yes' : 'No');
    });
  });

  it('Hides pagingation controls of CustomTable', () => {
    const wrapper = getMountedWrapper(true);
    expect(wrapper.find('#pagination-container').exists()).toBe(false);
  });

  it('Clicking select all button updates checkbox values and state', () => {
    const wrapper = getMountedWrapper(true);
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual([]);
    expect(wrapper.state('selectedIds')).toEqual([]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBe(false);
    });
    wrapper.find('th').find('input').simulate('change');
    expect(wrapper.state('table').selectAll).toBe(true);
    expect(wrapper.state('table').selectedRows).toEqual([0, 1, 2, 3]);
    expect(wrapper.state('selectedIds')).toEqual([mockPatient1.id, mockPatient2.id, mockPatient3.id, mockPatient4.id]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBe(true);
    });
    wrapper.find('th').find('input').simulate('change');
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual([]);
    expect(wrapper.state('selectedIds')).toEqual([]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBe(false);
    });
  });

  it('Clicking individual row checkboxes updates checkbox values and state', () => {
    const wrapper = getMountedWrapper(true);
    let selectedRows = [];
    let selectedIds = [];
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual([]);
    expect(wrapper.state('selectedIds')).toEqual([]);
    wrapper.find('tr').forEach(row => {
      expect(row.find('input').prop('checked')).toBe(false);
    });
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, index) => {
        row.find('input').simulate('change', { target: { checked: true } });
        selectedRows.push(index);
        selectedIds.push(householdMembers[Number(index)].id);
        expect(wrapper.state('table').selectAll).toEqual(householdMembers.length - 1 === index);
        expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
        expect(wrapper.state('selectedIds')).toEqual(selectedIds);
        wrapper.find('tr').forEach((row, index) => {
          expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index - 1) || selectedRows.length === householdMembers.length);
        });
      });
    wrapper
      .find('tbody')
      .find('tr')
      .forEach(row => {
        row.find('input').simulate('change', { target: { checked: false } });
        selectedRows.shift();
        selectedIds.shift();
        expect(wrapper.state('table').selectAll).toBe(false);
        expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
        expect(wrapper.state('selectedIds')).toEqual(selectedIds);
        wrapper.find('tr').forEach((row, index) => {
          expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index - 1));
        });
      });
  });

  it('Clicking table headers calls handleTableSort method', () => {
    const wrapper = getMountedWrapper(true);
    const sortSpy = jest.spyOn(wrapper.instance(), 'handleTableSort');
    wrapper.instance().forceUpdate();
    expect(sortSpy).not.toHaveBeenCalled();
    wrapper.state('table').colData.forEach((colData, index) => {
      if (colData.isSortable) {
        wrapper
          .find('th')
          .at(index + 1)
          .simulate('click');
        expect(sortSpy).toHaveBeenCalledTimes(2 * (index + 1) - 1);
        expect(sortSpy).toHaveBeenCalledWith({ orderBy: colData.field, sortDirection: 'asc', page: 0 });
        wrapper
          .find('th')
          .at(index + 1)
          .simulate('click');
        expect(sortSpy).toHaveBeenCalledTimes(2 * (index + 1));
        expect(sortSpy).toHaveBeenCalledWith({ orderBy: colData.field, sortDirection: 'desc', page: 0 });
      }
    });
  });

  it('Properly sorts table by name', () => {
    const wrapper = getMountedWrapper(true);
    wrapper.find('th').at(1).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByNameAscending(householdMembers));
    wrapper.find('th').at(1).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByNameDescending(householdMembers));
  });

  it('Properly sorts table by DOB', () => {
    const wrapper = getMountedWrapper(true);
    wrapper.find('th').at(2).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDateAscending(householdMembers, 'date_of_birth'));
    wrapper.find('th').at(2).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDateDescending(householdMembers, 'date_of_birth'));
  });

  it('Properly sorts table by workflow', () => {
    const wrapper = getMountedWrapper(true);
    wrapper.find('th').at(3).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByAscending(householdMembers, 'isolation'));
    wrapper.find('th').at(3).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDescending(householdMembers, 'isolation'));
  });

  it('Properly sorts table by monitoring status', () => {
    const wrapper = getMountedWrapper(true);
    wrapper.find('th').at(4).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDescending(householdMembers, 'monitoring'));
    wrapper.find('th').at(4).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByAscending(householdMembers, 'monitoring'));
  });

  it('Properly sorts table by continuous exposure', () => {
    const wrapper = getMountedWrapper(true);
    wrapper.find('th').at(5).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByAscending(householdMembers, 'continuous_exposure'));
    wrapper.find('th').at(5).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortByDescending(householdMembers, 'continuous_exposure'));
  });

  it('Sorting household members table maintains selected and disabled rows', () => {
    householdMembers.push(mockPatient5);
    let selectedRows = [0, 2];
    let selectedIds = [householdMembers[0].id, householdMembers[2].id];
    const wrapper = mount(<HouseholdMemberTable household_members={householdMembers} isSelectable={true} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} workflow={'global'} />);

    // initial load
    selectedRows.forEach(rowId => {
      wrapper
        .find('tbody')
        .find('tr')
        .at(rowId)
        .find('input')
        .simulate('change', { target: { checked: true } });
    });
    expect(wrapper.state('table').rowData).toEqual(householdMembers);
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.find('thead').find('input').prop('checked')).toBe(false);
    expect(wrapper.find('thead').find('input').prop('disabled')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, index) => {
        expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
        expect(row.find('td').at(1).find('a').text()).toEqual(formatNameAlt(householdMembers[Number(index)]));
      });

    // sort by name, asc
    let sortedHouseholdMembers = sortByNameAscending(householdMembers);
    selectedRows = [2, 4];
    wrapper.find('th').at(1).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.find('thead').find('input').prop('checked')).toBe(false);
    expect(wrapper.find('thead').find('input').prop('disabled')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, index) => {
        expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
        expect(row.find('td').at(1).find('a').text()).toEqual(formatNameAlt(sortedHouseholdMembers[Number(index)]));
      });

    // sort by DOB, desc
    sortedHouseholdMembers = sortByDateDescending(sortedHouseholdMembers, 'date_of_birth');
    selectedRows = [2, 3];
    wrapper.find('th').at(2).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.find('thead').find('input').prop('checked')).toBe(false);
    expect(wrapper.find('thead').find('input').prop('disabled')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, index) => {
        expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
        expect(row.find('td').at(1).find('a').text()).toEqual(formatNameAlt(sortedHouseholdMembers[Number(index)]));
      });

    // sort by workflow, asc
    sortedHouseholdMembers = sortByAscending(sortedHouseholdMembers, 'isolation');
    selectedRows = [1, 4];
    wrapper.find('th').at(3).simulate('click');
    expect(wrapper.state('table').rowData).toEqual(sortedHouseholdMembers);
    expect(wrapper.state('table').selectAll).toBe(false);
    expect(wrapper.state('table').selectedRows).toEqual(selectedRows);
    expect(wrapper.state('selectedIds')).toEqual(selectedIds);
    expect(wrapper.find('thead').find('input').prop('checked')).toBe(false);
    expect(wrapper.find('thead').find('input').prop('disabled')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, index) => {
        expect(row.find('input').prop('checked')).toEqual(selectedRows.includes(index));
        expect(row.find('td').at(1).find('a').text()).toEqual(formatNameAlt(sortedHouseholdMembers[Number(index)]));
      });
  });

  it('Hides checkboxes when props.isSelectable is false', () => {
    const wrapper = getMountedWrapper(false);
    expect(wrapper.find('thead').find('input').exists()).toBe(false);
    expect(wrapper.find('tbody').find('input').exists()).toBe(false);
  });
});
