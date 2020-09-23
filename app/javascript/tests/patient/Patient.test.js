import React from 'react'
import { shallow } from 'enzyme';
import { Row } from 'react-bootstrap';
import Patient from '../../components/patient/Patient.js'
import ChangeHOH from '../../components/subject/ChangeHOH';
import MoveToHousehold from '../../components/subject/MoveToHousehold';
import RemoveFromHousehold from '../../components/subject/RemoveFromHousehold';
import { mockPatient1, mockPatient2, blankMockPatient } from '../mocks/mockPatients'

const hohTableHeaders = [ 'Name', 'Workflow', 'Monitoring Status', 'Continuous Exposure?' ]

function getWrapper(mockPatient, groupMembers) {
    const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
    const wrapper = shallow(<Patient details={mockPatient} groupMembers={groupMembers} goto={() => {}} hideBody={true}
        jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
    return wrapper;
}

describe('Patient', () => {
    it('Properly renders all main components', () => {
        const wrapper = getWrapper(mockPatient1, [ mockPatient2 ]);
        expect(wrapper.find('#jurisdiction-path').text()).toEqual('Assigned Jurisdiction: USA, State 1, County 2');
        expect(wrapper.find('#assigned-user').text()).toEqual('Assigned User: 21');
        expect(wrapper.find('#identification').exists()).toBeTruthy();
        expect(wrapper.find('#contact-information').exists()).toBeTruthy();
        expect(wrapper.find('#address').exists()).toBeTruthy();
        expect(wrapper.find('#arrival-information').exists()).toBeTruthy();
        expect(wrapper.find('#additional-planned-travel').exists()).toBeTruthy();
        expect(wrapper.find('#exposure-case-information').exists()).toBeTruthy();
    });

    it('Properly renders HoH section', () => {
        const wrapper = getWrapper(mockPatient1, [ mockPatient2, blankMockPatient ]);
        expect(wrapper.find('#head-of-household').exists()).toBeTruthy();
        expect(wrapper.find('#head-of-household').find(Row).at(1).text())
            .toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
        expect(wrapper.containsMatchingElement(<ChangeHOH />)).toBeTruthy();
        expect(wrapper.containsMatchingElement(<RemoveFromHousehold />)).toBeFalsy();
        expect(wrapper.containsMatchingElement(<MoveToHousehold />)).toBeFalsy();
        hohTableHeaders.forEach(function(header, index) {
            expect(wrapper.find('thead th').at(index).text()).toEqual(header);
        })
        expect(wrapper.find('tbody tr').length).toEqual(2);
    });

    it('Properly renders household member section', () => {
        const wrapper = getWrapper(mockPatient2, []);
        expect(wrapper.find('#household-member-not-hoh').exists()).toBeTruthy();
        expect(wrapper.find('#household-member-not-hoh').find(Row).first().text())
            .toEqual('The reporting responsibility for this monitoree is handled by another monitoree. Click here to view that monitoree.');
        expect(wrapper.find('#household-member-not-hoh a').prop('href')).toEqual('/patients/17');
        expect(wrapper.containsMatchingElement(<RemoveFromHousehold />)).toBeTruthy();
        expect(wrapper.containsMatchingElement(<MoveToHousehold />)).toBeFalsy();
        expect(wrapper.containsMatchingElement(<ChangeHOH />)).toBeFalsy();
    });

    it('Properly renders single member (not in household) section', () => {
        const wrapper = getWrapper(mockPatient1, []);
        expect(wrapper.find('#no-household').exists()).toBeTruthy();
        expect(wrapper.find('#no-household').find(Row).at(1).text()).toEqual('This monitoree is not a member of a household:');
        expect(wrapper.containsMatchingElement(<MoveToHousehold />)).toBeTruthy();
        expect(wrapper.containsMatchingElement(<ChangeHOH />)).toBeFalsy();
        expect(wrapper.containsMatchingElement(<RemoveFromHousehold />)).toBeFalsy();
    });

    it('Properly renders no details message', () => {
        const blankWrapper = getWrapper();
        expect(blankWrapper.text()).toEqual('No monitoree details to show.');
    });

    // test detail sections in more depth
    // arrival info section (arrival and dept)
    // case info section iso vs exp 

    // hide body shows different details
    // clicking change HoH shows modal
    // clicking remove from household shows modal
    // clicking move to household shows modal
    // test go to functionality
});
