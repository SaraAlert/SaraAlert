import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import AddAssessmentNote from '../../../components/assessment/steps/AddAssessmentNote.js'
import { mockPatient1 } from '../../mocks/mockPatients'
import { mockAssessment1 } from '../../mocks/mockAssessments'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient) {
    return shallow(<AddAssessmentNote patient={patient} assessment={mockAssessment1} authenticity_token={authyToken} />);
}

describe('AddAssessmentNote', () => {
  it('Properly renders "Add Report Note" button', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text().includes('Add Note')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-comment-medical')).toBeTruthy();
  });

  it('Clicking "Add Report Note" opens modal', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders report note modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual('Add Note To Report');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Please enter your note about the report (ID: ${mockAssessment1.id}) below.`);
    expect(wrapper.find(Modal.Body).find('#comment').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Properly renders report note modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual('Add Note To Report');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Please enter your note about the report (ID: ${mockAssessment1.id}) below.`);
    expect(wrapper.find(Modal.Body).find('#comment').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Adding text to the input updates state', () => {
    const wrapper = getWrapper(mockPatient1);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleChange');
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#comment').exists()).toBeTruthy();
    wrapper.find('#comment').simulate('change', { target: { id: 'reasoning', value: 'insert some text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert some text here');
  });

  it('Clicking the cancel button closes modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1);
    const AddAssessmentNoteSpy = jest.spyOn(wrapper.instance(), 'AddAssessmentNote');
    wrapper.find(Button).simulate('click');
    expect(AddAssessmentNoteSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(2).simulate('click');
    expect(AddAssessmentNoteSpy).toHaveBeenCalled();
  });
});
