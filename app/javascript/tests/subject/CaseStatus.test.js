import React from 'react'
import { shallow } from 'enzyme';
import { Form } from 'react-bootstrap';
import CaseStatus from '../../components/subject/CaseStatus.js'
import InfoTooltip from '../../components/util/InfoTooltip';
import { mockPatient1 } from '../mocks/mockPatients'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const caseStatusValues = [ '', 'Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case' ];

function getWrapper(patient, hasGroupMembers) {
    return shallow(<CaseStatus patient={patient} hasGroupMembers={hasGroupMembers} authenticity_token={authyToken} />);
}

describe('CaseStatus', () => {
    it('Properly renders all main components', () => {
        const wrapper = getWrapper(mockPatient1, false);
        expect(wrapper.find(Form.Label).text().includes('CASE STATUS')).toBeTruthy();
        expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
        expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('caseStatus');
        expect(wrapper.find(Form.Control).exists()).toBeTruthy();
        expect(wrapper.find('option').length).toEqual(6);
        caseStatusValues.forEach(function(value, index) {
            expect(wrapper.find('option').at(index).text()).toEqual(value);
        });
    });

});
