import React from 'react';
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import AddAssessmentNote from '../../../../components/patient/assessment/actions/AddAssessmentNote';
import { mockPatient1 } from '../../../mocks/mockPatients';
import { mockAssessment1 } from '../../../mocks/mockAssessments';

const mockToken = 'testMockTokenString12345';

function getWrapper(patient) {
  return shallow(<AddAssessmentNote patient={patient} assessment={mockAssessment1} authenticity_token={mockToken} />);
}

describe('AddAssessmentNote', () => {
  it('Properly renders "Add Report Note" button', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text()).toContain('Add Note');
    expect(wrapper.find('i').hasClass('fa-comment-medical')).toBe(true);
  });

  it('Clicking "Add Report Note" opens modal', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders report note modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).text()).toEqual('Add Note To Report');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Please enter your note about the report (ID: ${mockAssessment1.id}) below.`);
    expect(wrapper.find(Modal.Body).find('#comment').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Properly renders report note modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).text()).toEqual('Add Note To Report');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Please enter your note about the report (ID: ${mockAssessment1.id}) below.`);
    expect(wrapper.find(Modal.Body).find('#comment').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Adding text to the input updates state', () => {
    const wrapper = getWrapper(mockPatient1);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleChange');
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#comment').exists()).toBe(true);
    wrapper.find('#comment').simulate('change', { target: { id: 'reasoning', value: 'insert some text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert some text here');
  });

  it('Clicking the cancel button closes modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find(Button).simulate('click');
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(2).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
