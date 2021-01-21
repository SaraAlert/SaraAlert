import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import MoveToHousehold from '../../components/subject/MoveToHousehold.js'
import { mockPatient1 } from '../mocks/mockPatients'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient) {
    return shallow(<MoveToHousehold patient={patient} authenticity_token={authyToken} />);
}

function getPatientName(patient) {
  return `${patient.first_name} ${patient.middle_name} ${patient.last_name}`;
}

describe('MoveToHousehold', () => {
    it('Properly renders Move To Household button', () => {
        const wrapper = getWrapper(mockPatient1);
        expect(wrapper.find(Button).length).toEqual(1);
        expect(wrapper.find(Button).text().includes('Move To Household')).toBeTruthy();
        expect(wrapper.find('i').hasClass('fa-house-user')).toBeTruthy();
        expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
        expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    });

    it('Clicking the Move to Household button opens modal and modal renders correctly', () => {
      const wrapper = getWrapper(mockPatient1);
      const toggleModalSpy = jest.spyOn(wrapper.instance(), "toggleModal");
      const updateTableSpy = jest.spyOn(wrapper.instance(), "updateTable");
      // Necessary for the spy to be called on click
      wrapper.instance().forceUpdate();

      expect(toggleModalSpy).toHaveBeenCalledTimes(0);
      expect(updateTableSpy).toHaveBeenCalledTimes(0);
      expect(wrapper.state('showModal')).toBe(false);
      expect(wrapper.find(Modal).exists()).toBe(false);

      wrapper.find(Button).simulate('click');

      expect(toggleModalSpy).toHaveBeenCalledTimes(1);
      expect(updateTableSpy).toHaveBeenCalledTimes(1);
      expect(wrapper.state('showModal')).toBe(true);
      expect(wrapper.find(Modal).exists()).toBe(true);
      expect(wrapper.find(Modal).find(Form.Label).text()).toEqual(
        `Please select the new monitoree that will respond for ${getPatientName(mockPatient1)}.`
      )
      expect(wrapper.find(Modal).find(Form.Label).find('b').text()).toEqual(getPatientName(mockPatient1));
      expect(wrapper.find(Modal).find('p').text())
      .toEqual(
        'You may select from the provided existing Head of Households and monitorees who are self reporting.' + 
        `${getPatientName(mockPatient1)} will be immediately moved into the selected monitoree's household.`
      );
    });

    it('Clicking Cancel in Move to Household modal closes modal and does nothing else', () => {
      const wrapper = getWrapper(mockPatient1);
      const toggleModalSpy = jest.spyOn(wrapper.instance(), "toggleModal");
      const updateTableSpy = jest.spyOn(wrapper.instance(), "updateTable");

      // Necessary for the spy to be called on click
      wrapper.instance().forceUpdate();

      wrapper.find(Button).simulate('click');
      expect(wrapper.state('showModal')).toBe(true);
      expect(toggleModalSpy).toHaveBeenCalledTimes(1);
      expect(updateTableSpy).toHaveBeenCalledTimes(1);

      expect(wrapper.find('#move-to-household-cancel-button').exists()).toBe(true);
      wrapper.find('#move-to-household-cancel-button').simulate('click');
      expect(wrapper.state('showModal')).toBe(false);
      expect(toggleModalSpy).toHaveBeenCalledTimes(2);
      expect(updateTableSpy).toHaveBeenCalledTimes(1);
    });
});
