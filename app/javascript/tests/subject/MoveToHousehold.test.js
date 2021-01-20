import React from 'react'
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import MoveToHousehold from '../../components/subject/MoveToHousehold.js'
import { mockPatient1 } from '../mocks/mockPatients'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient) {
    return shallow(<MoveToHousehold patient={patient} authenticity_token={authyToken} />);
}

describe('MoveToHousehold', () => {
    it('Properly renders Move To Household button', () => {
        const wrapper = getWrapper(mockPatient1);
        expect(wrapper.find(Button).length).toEqual(1);
        expect(wrapper.find(Button).text().includes('MoveToHousehld')).toBeTruthy();
        expect(wrapper.find('i').hasClass('fa-house-user')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
        expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    });

    it('Clicking the Move to Household button opens modal', () => {
      //TODO
    });

    it('Clicking Select in Move to Household modal makes a request with correct data', () => {
      //TODO
    });

    it('Clicking Cancel in Move to Household modal closes modal and does nothing else', () => {
      //TODO
    });
});
