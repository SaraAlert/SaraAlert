import React from 'react'
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import PauseNotifications from '../../components/subject/PauseNotifications.js'
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../mocks/mockPatients'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient) {
    return shallow(<PauseNotifications patient={patient} authenticity_token={authyToken} />);
}

describe('PauseNotifications', () => {
    it('Properly renders pause notifications button', () => {
        const wrapper = getWrapper(mockPatient1);
        expect(wrapper.find(Button).length).toEqual(1);
        expect(wrapper.find(Button).text().includes('Pause Notifications')).toBeTruthy();
        expect(wrapper.find('i').hasClass('fa-pause')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
        expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    });

    it('Disables the pause notifications button and renders tooltip if HH dependent', () => {
        const wrapper = getWrapper(mockPatient2);
        expect(wrapper.find(Button).text().includes('Pause Notifications')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
        expect(wrapper.find(ReactTooltip)).toBeTruthy();
        expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Notifications cannot be paused because the monitoree is within a Household, so the Head of Household will receive notifications instead. If notifications to the Head of Household should be paused, you may update this field on the Head of Household record.');
    });

    it('Disables the pause notifications button and renders tooltip if record is closed', () => {
        const wrapper = getWrapper(mockPatient3);
        expect(wrapper.find(Button).text().includes('Pause Notifications')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
        expect(wrapper.find(ReactTooltip)).toBeTruthy();
        expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Notifications cannot be paused for records on the Closed line list. You may update this field after changing Monitoring Status to "Actively Monitoring"`)
    });

    it('Clicking the pause notifications button calls handle submit function', () => {
        const wrapper = getWrapper(mockPatient1);
        const handleSubmitSpy = jest.spyOn(wrapper.instance(), "handleSubmit");

        expect(handleSubmitSpy).toHaveBeenCalledTimes(0);
        wrapper.find(Button).simulate('click');
        expect(handleSubmitSpy).toHaveBeenCalledTimes(1);
    });

    it('Properly renders resume notifications button', () => {
        const wrapper = getWrapper(mockPatient4);
        expect(wrapper.find(Button).length).toEqual(1);
        expect(wrapper.find(Button).text().includes('Resume Notifications')).toBeTruthy();
        expect(wrapper.find('i').hasClass('fa-play')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
        expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    });

    it('Disables the resume notifications button and renders tooltip if HH dependent', () => {
        let newPatient = mockPatient4;
        newPatient.responder_id = mockPatient4.id+1;
        const wrapper = getWrapper(newPatient);

        expect(wrapper.find(Button).text().includes('Resume Notifications')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
        expect(wrapper.find(ReactTooltip)).toBeTruthy();
        expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Notifications cannot be resumed because the monitoree is within a Household, so the Head of Household will receive notifications instead. If notifications to the Head of Household should be resumed, you may update this field on the Head of Household record.');
    });

    it('Disables the resume notifications button and renders tooltip if record is closed', () => {
        let newPatient = mockPatient4;
        newPatient.monitoring = false;
        const wrapper = getWrapper(newPatient);

        expect(wrapper.find(Button).text().includes('Resume Notifications')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
        expect(wrapper.find(ReactTooltip)).toBeTruthy();
        expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Notifications cannot be resumed for records on the Closed line list. You may update this field after changing Monitoring Status to "Actively Monitoring"`)
    });

    it('Clicking the resume notifications button calls handle submit function', () => {
        const wrapper = getWrapper(mockPatient4);
        const handleSubmitSpy = jest.spyOn(wrapper.instance(), "handleSubmit");

        expect(handleSubmitSpy).toHaveBeenCalledTimes(0);
        wrapper.find(Button).simulate('click');
        expect(handleSubmitSpy).toHaveBeenCalledTimes(1);
    });
});
