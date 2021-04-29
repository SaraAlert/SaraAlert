import React from 'react';
import { shallow } from 'enzyme';
import { Row, Table } from 'react-bootstrap';
import HeadOfHousehold from '../../../components/patient/household/HeadOfHousehold';
import ChangeHoH from '../../../components/patient/household/actions/ChangeHoH';
import EnrollHouseholdMember from '../../../components/patient/household/actions/EnrollHouseholdMember';
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients';

const tableHeaders = [ 'Name', 'Workflow', 'Monitoring Status', 'Continuous Exposure?' ];
const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

describe('HeadOfHousehold', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<HeadOfHousehold patient={mockPatient1} dependents={[ mockPatient2 ]} can_add_group={true} authenticity_token={authyToken} />);
    const wrapper2 = shallow(<HeadOfHousehold patient={mockPatient1} dependents={[ mockPatient2 ]} can_add_group={false} authenticity_token={authyToken} />);
    
    // if user can add group
    expect(wrapper.find(Row).length).toEqual(3);
    expect(wrapper.find(Row).at(0).text()).toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
    expect(wrapper.find(Table).exists).toBeTruthy();
    tableHeaders.forEach((header, index) => {
      expect(wrapper.find('thead th').at(index).text()).toEqual(header);
    });
    expect(wrapper.find('tbody tr').length).toEqual(1);
    expect(wrapper.find(ChangeHoH).exists()).toBeTruthy();
    expect(wrapper.find(EnrollHouseholdMember).exists()).toBeTruthy();
    expect(wrapper.find(EnrollHouseholdMember).prop('isHoh')).toBeTruthy();

    // if user can't add group
    expect(wrapper2.find(Row).length).toEqual(3);
    expect(wrapper2.find(Row).at(0).text()).toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
    expect(wrapper2.find(Table).exists).toBeTruthy();
    tableHeaders.forEach((header, index) => {
      expect(wrapper2.find('thead th').at(index).text()).toEqual(header);
    });
    expect(wrapper2.find('tbody tr').length).toEqual(1);
    expect(wrapper2.find(ChangeHoH).exists()).toBeTruthy();
    expect(wrapper2.find(EnrollHouseholdMember).exists()).toBeFalsy();
  });
});