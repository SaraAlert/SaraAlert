import React from 'react'
import { shallow } from 'enzyme';
import { Button, Collapse, Row } from 'react-bootstrap';
import Patient from '../../components/patient/Patient.js'
import ChangeHOH from '../../components/subject/ChangeHOH';
import MoveToHousehold from '../../components/subject/MoveToHousehold';
import RemoveFromHousehold from '../../components/subject/RemoveFromHousehold';
import { mockPatient1, mockPatient2, blankMockPatient } from '../mocks/mockPatients'

const goToMock = jest.fn();
const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const hohTableHeaders = [ 'Name', 'Workflow', 'Monitoring Status', 'Continuous Exposure?' ];
const identificationFields = [ 'DOB', 'Age', 'Language', 'State/Local ID', 'CDC ID', 'NNDSS ID', 'Birth Sex', 'Gender Identity', 'Sexual Orientation', 'Race', 'Ethnicity', 'Nationality' ];
const contactFields = [ 'Phone', 'Preferred Contact Time', 'Type', 'Email', 'Preferred Reporting Method' ];
const additionalTravelFields = [ 'Type', 'Place', 'Port Of Departure', 'End Date', 'Start Date' ];
const potentialExposureFields = [ 
    'CLOSE CONTACT WITH A KNOWN CASE',
    'MEMBER OF A COMMON EXPOSURE COHORT',
    'TRAVEL FROM AFFECTED COUNTRY OR AREA',
    'WAS IN HEALTH CARE FACILITY WITH KNOWN CASES',
    'LABORATORY PERSONNEL',
    'HEALTHCARE PERSONNEL',
    'CREW ON PASSENGER OR CARGO FLIGHT'
]

describe('Patient', () => {
    it('Properly renders all main components', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ mockPatient2 ]} goto={goToMock} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(wrapper.find('#jurisdiction-path').text()).toEqual('Assigned Jurisdiction: USA, State 1, County 2');
        expect(wrapper.find('#assigned-user').text()).toEqual('Assigned User: 21');
        expect(wrapper.find('#identification').exists()).toBeTruthy();
        expect(wrapper.find('#contact-information').exists()).toBeTruthy();
        expect(wrapper.find('#address').exists()).toBeTruthy();
        expect(wrapper.find('#arrival-information').exists()).toBeTruthy();
        expect(wrapper.find('#additional-planned-travel').exists()).toBeTruthy();
        expect(wrapper.find('#exposure-case-information').exists()).toBeTruthy();
    });

    it('Properly renders identification section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#identification');
        expect(section.find(Row).first().text()).toEqual('Identification: Minnie M Mouse');
        expect(section.find(Button).length).toEqual(0);
        identificationFields.forEach(function(field, index) {
            expect(section.find('.font-weight-normal').at(index).text()).toEqual(field+':');
        });
    });

    it('Properly renders contact information section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#contact-information');
        expect(section.find(Row).first().text()).toEqual('Contact Information');
        expect(section.find(Button).length).toEqual(0);
        contactFields.forEach(function(field, index) {
            expect(section.find('.font-weight-normal').at(index).text()).toEqual(field+':');
        });
    });

    it('Properly renders address section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#address');
        expect(section.find(Row).first().text()).toEqual('Address');
        expect(section.find(Button).length).toEqual(0);
        expect(section.find('.font-weight-light').at(0).text()).toEqual('1 Hartford Drive');
        expect(section.find('.font-weight-light').at(1).text()).toEqual('Springfield Connecticut Fairfield 00000-0000');
    });

    it('Properly renders arrival information section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#arrival-information');
        expect(section.find(Row).first().text()).toEqual('Arrival Information');
        expect(section.find(Button).length).toEqual(0);
        expect(section.find('h6').at(0).text()).toEqual('DEPARTED');
        expect(section.find('.font-weight-light').at(0).text()).toEqual('Cabo');
        expect(section.find('.font-weight-light').at(1).text()).toEqual('09/08/2020');
        expect(section.find('h6').at(1).text()).toEqual('ARRIVAL');
        expect(section.find('.font-weight-light').at(2).text()).toEqual('Orlando');
        expect(section.find('.font-weight-light').at(3).text()).toEqual('09/10/2020');
        expect(section.find('.font-weight-light').at(4).text()).toEqual('Spirit');
        expect(section.find('.font-weight-light').at(5).text()).toEqual('1515');
    });

    it('Properly renders additional planned travel section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#additional-planned-travel');
        expect(section.find(Row).first().text()).toEqual('Additional Planned Travel');
        expect(section.find(Button).length).toEqual(0);
        additionalTravelFields.forEach(function(field, index) {
            expect(section.find('.font-weight-normal').at(index).text()).toEqual(field+':');
        });
    });

    it('Properly renders case information section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#exposure-case-information');
        expect(section.find(Row).first().text()).toEqual('Case Information');
        expect(section.find(Button).length).toEqual(0);
        expect(section.find('.font-weight-light').at(0).text()).toEqual('Symptom Onset: 09/27/2020');
        expect(section.find('.font-weight-light').at(1).text()).toEqual('Case Status: Suspect');

    });

    it('Properly renders potential exposure information section', () => {
        const wrapper = shallow(<Patient details={mockPatient2} groupMembers={[ ]} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        const section = wrapper.find('#exposure-case-information');
        expect(section.find(Row).first().text()).toEqual('Potential Exposure Information');
        expect(section.find(Button).length).toEqual(0);
        expect(section.find('h6').text()).toEqual('LAST EXPOSURE');
        expect(section.find('.font-weight-light').at(0).text()).toEqual(' Mexico');
        expect(section.find('.font-weight-light').at(1).text()).toEqual('09/13/2020');
        potentialExposureFields.forEach(function(field, index) {
            expect(section.find('.text-danger').at(index).text().includes(field)).toBeTruthy();
        });
    });

    it('Properly renders HoH section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ mockPatient2, blankMockPatient ]} goto={goToMock} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(wrapper.find('#head-of-household').exists()).toBeTruthy();
        expect(wrapper.find('#head-of-household').find(Row).at(1).text())
            .toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
        expect(wrapper.containsMatchingElement(<ChangeHOH />)).toBeTruthy();
        expect(wrapper.containsMatchingElement(<RemoveFromHousehold />)).toBeFalsy();
        expect(wrapper.containsMatchingElement(<MoveToHousehold />)).toBeFalsy();
        hohTableHeaders.forEach(function(header, index) {
            expect(wrapper.find('thead th').at(index).text()).toEqual(header);
        });
        expect(wrapper.find('tbody tr').length).toEqual(2);
    });

    it('Properly renders household member section', () => {
        const wrapper = shallow(<Patient details={mockPatient2} groupMembers={[ ]} goto={goToMock} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(wrapper.find('#household-member-not-hoh').exists()).toBeTruthy();
        expect(wrapper.find('#household-member-not-hoh').find(Row).first().text())
            .toEqual('The reporting responsibility for this monitoree is handled by another monitoree. Click here to view that monitoree.');
        expect(wrapper.find('#household-member-not-hoh a').prop('href')).toEqual('/patients/17');
        expect(wrapper.containsMatchingElement(<RemoveFromHousehold />)).toBeTruthy();
        expect(wrapper.containsMatchingElement(<MoveToHousehold />)).toBeFalsy();
        expect(wrapper.containsMatchingElement(<ChangeHOH />)).toBeFalsy();
    });

    it('Properly renders single member (not in household) section', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ ]} goto={goToMock} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(wrapper.find('#no-household').exists()).toBeTruthy();
        expect(wrapper.find('#no-household').find(Row).at(1).text()).toEqual('This monitoree is not a member of a household:');
        expect(wrapper.containsMatchingElement(<MoveToHousehold />)).toBeTruthy();
        expect(wrapper.containsMatchingElement(<ChangeHOH />)).toBeFalsy();
        expect(wrapper.containsMatchingElement(<RemoveFromHousehold />)).toBeFalsy();
    });

    it('Properly renders no details message', () => {
        const blankWrapper = shallow(<Patient />);
        expect(blankWrapper.text()).toEqual('No monitoree details to show.');
    });

    it('Expands/collapses details with this.props.hideBody', () => {
        const collapsedWrapper = shallow(<Patient details={mockPatient1} groupMembers={[ mockPatient2 ]} goto={goToMock} hideBody={true}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(collapsedWrapper.find(Collapse).prop('in')).toBeFalsy();

        const expandedWrapper = shallow(<Patient details={mockPatient1} groupMembers={[ mockPatient2 ]} goto={goToMock} hideBody={false}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(expandedWrapper.find(Collapse).prop('in')).toBeTruthy();
    });

    it('Calls props goto method when the edit buttons are clicked', () => {
        const wrapper = shallow(<Patient details={mockPatient1} groupMembers={[ mockPatient2 ]} goto={goToMock} hideBody={false}
            jurisdictionPath="USA, State 1, County 2" authenticity_token={authyToken} />);
        expect(wrapper.find(Button).length).toEqual(6);
        expect(goToMock).toHaveBeenCalledTimes(0);
        wrapper.find(Button).forEach(function(btn, index) {
            btn.simulate('click');
            expect(goToMock).toHaveBeenCalledTimes(index+1);
        });
    });
});
