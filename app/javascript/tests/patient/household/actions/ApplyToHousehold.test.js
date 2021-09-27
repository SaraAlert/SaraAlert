import React from 'react';
import { shallow } from 'enzyme';
import { Form } from 'react-bootstrap';
import ApplyToHousehold from '../../../../components/patient/household/actions/ApplyToHousehold';
import HouseholdMemberTable from '../../../../components/patient/household/HouseholdMemberTable';
import { mockUser1 } from '../../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../../mocks/mockPatients';

const householdMembers = [mockPatient1, mockPatient2, mockPatient3, mockPatient4];
const handleApplyHouseholdChangeMock = jest.fn();
const handleApplyHouseholdIdsChangeMock = jest.fn();

function getWrapper() {
  return shallow(<ApplyToHousehold household_members={householdMembers} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} handleApplyHouseholdChange={handleApplyHouseholdChangeMock} handleApplyHouseholdIdsChange={handleApplyHouseholdIdsChangeMock} workflow={'global'} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('ApplyToHousehold', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('p').text()).toEqual('Apply this change to:');
    expect(wrapper.find(Form.Group).exists()).toBe(true);
    expect(wrapper.find(Form.Check).length).toEqual(2);
    expect(wrapper.find('#apply_to_household_no').prop('label')).toEqual('This monitoree only');
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').prop('label')).toEqual('This monitoree and selected household members');
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBe(false);
    expect(wrapper.find(HouseholdMemberTable).exists()).toBe(false);
  });

  it('Clicking "Apply to Household" radio button shows table of household members', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(HouseholdMemberTable).exists()).toBe(false);
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(HouseholdMemberTable).exists()).toBe(true);
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(HouseholdMemberTable).exists()).toBe(false);
  });

  it('Clicking radio buttons updates state and calls handleApplyHouseholdChange prop', () => {
    const wrapper = getWrapper();
    expect(handleApplyHouseholdChangeMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('applyToHousehold')).toBe(false);
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBe(false);
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(handleApplyHouseholdChangeMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('applyToHousehold')).toBe(true);
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBe(false);
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBe(true);
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(handleApplyHouseholdChangeMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('applyToHousehold')).toBe(false);
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBe(false);
  });
});
