import React from 'react'
import { shallow } from 'enzyme';
import PatientPage from '../../components/patient/PatientPage.js'
import Patient from '../../components/patient/Patient.js'
import { mockUser1 } from '../mocks/mockUsers'
import { mockPatient1, mockPatient2 } from '../mocks/mockPatients'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const groupMembers = [ mockPatient2 ]

describe('PatientPage properly renders', () => {
    let wrapper = shallow(<PatientPage patient_id="EX-771721" patient={mockPatient1} current_user={mockUser1} group_members={groupMembers} hideBody={true}
        jurisdictionPath="USA, State 1, County 2" dashboardUrl="/public_health" authenticity_token={authyToken} />);

    it('card header', () => {
        expect(wrapper.find('#patient-info-header').exists()).toBeTruthy();
    });

    it('card header title', () => {
        expect(wrapper.find('#patient-info-header').text()).toEqual('Monitoree Details  (edit details)');
    });

    it('edit details href', () => {
        expect(wrapper.find('#patient-info-header a').prop('href')).toEqual('undefined/patients/17/edit');
    });

    it('expand hamburger menu', () => {
        expect(wrapper.find('.collapse-hover .fa-bars').exists()).toBeTruthy();
    });

    it('child component Patient', () => {
        expect(wrapper.containsMatchingElement(<Patient />)).toBeTruthy();
    });
});

// this block gets run with the above block, just has a different wrapper
describe('PatientPage properly renders', () => {
    let wrapper = shallow(<PatientPage patient_id="EX-771721" patient={mockPatient2} current_user={mockUser1} group_members={groupMembers} hideBody={true}
        jurisdictionPath="USA, State 1, County 2" dashboardUrl="/public_health" authenticity_token={authyToken} />);
    
    it('card header title with user defined id', () => {
        expect(wrapper.find('#patient-info-header').text()).toEqual('Monitoree Details (ID: 00000-1) (edit details)');
    });
});

describe('clicking card header', () => {
    let wrapper = shallow(<PatientPage patient_id="EX-771721" patient={mockPatient1} current_user={mockUser1} group_members={groupMembers} hideBody={true}
        jurisdictionPath="USA, State 1, County 2" dashboardUrl="/public_health" authenticity_token={authyToken} />);
    
    it('updates this.state.hideBody to false', () => {
        wrapper.find('#patient-info-header').simulate('click');
        expect(wrapper.state('hideBody')).toBeFalsy();
    });

    it('updates this.state.hideBody to true', () => {
        wrapper.find('#patient-info-header').simulate('click');
        expect(wrapper.state('hideBody')).toBeTruthy();
    });
});
