import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import CloseRecords from '../../../components/public_health/bulk_actions/CloseRecords';
import { mockPatient1, mockPatient2, mockPatient6 } from '../../mocks/mockPatients';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';

const onCloseMock = jest.fn();
const mockToken = 'testMockTokenString12345';
const patientsArray = [mockPatient1, mockPatient2, mockPatient6];

function getWrapper() {
  return shallow(<CloseRecords authenticity_token={mockToken} patients={patientsArray} close={onCloseMock} monitoring_reasons={mockMonitoringReasons} />);
}

describe('CloseRecords', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('p').find('span').at(0).text()).toEqual('You are about to change the Monitoring Status of the selected records from "Actively Monitoring" to "Not Monitoring".');
    expect(wrapper.find('p').find('span').at(1).text()).toEqual(' These records will be moved to the closed line list and the reason for closure will be blank.');
    expect(wrapper.find(Form.Group).length).toEqual(3);
    expect(wrapper.find(Form.Group).at(0).find(Form.Label).text()).toEqual('Please select reason for status change:');
    expect(wrapper.find(Form.Control).length).toEqual(2);
    const monitoringReasonOptions = [''].concat(mockMonitoringReasons);
    wrapper
      .find(Form.Control)
      .at(0)
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(monitoringReasonOptions[Number(index)]);
      });
    expect(wrapper.find(Form.Group).at(1).find(Form.Label).text()).toEqual('Please include any additional details:');
    expect(wrapper.find('.character-limit-text').text()).toContain('characters remaining');
    expect(wrapper.find('#apply_to_household').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Changing monitoring reason dropdown updates state', () => {
    const wrapper = getWrapper();
    // initial modal state with monitoring reason empty
    expect(wrapper.state('monitoring_reason')).toEqual('');
    expect(wrapper.find('p').text()).toContain('These records will be moved to the closed line list and the reason for closure will be blank.');

    // test changing to each enabled monitoring option
    mockMonitoringReasons.forEach(value => {
      wrapper
        .find(Form.Control)
        .at(0)
        .simulate('change', { target: { id: 'monitoring_reason', value: value } });
      expect(wrapper.state('monitoring_reason')).toEqual(value);
      expect(wrapper.state('monitoring')).toEqual(false);
      expect(wrapper.find('p').text()).not.toContain('These records will be moved to the closed line list and the reason for closure will be blank.');
    });
  });

  it('Changing closure reason properly updates state and character limit label', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('.character-limit-text').text()).toEqual('2000 characters remaining');
    expect(wrapper.state('reasoning')).toEqual('');
    const mockReasoning = 'I Shall Call Him Squishy And He Shall Be Mine And He Shall Be My Squishy.';
    wrapper
      .find(Form.Group)
      .at(1)
      .find(Form.Control)
      .simulate('change', { target: { id: 'reasoning', value: mockReasoning } });
    expect(wrapper.state('reasoning')).toEqual(mockReasoning);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - mockReasoning.length} characters remaining`);
  });

  it('Properly toggles the Apply to Household option', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('apply_to_household')).toBe(false);
    wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true } });
    expect(wrapper.state('apply_to_household')).toBe(true);
    wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false } });
    expect(wrapper.state('apply_to_household')).toBe(false);
  });

  it('Properly calls the close method', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).at(0).text()).toContain('Cancel');
    expect(onCloseMock).not.toHaveBeenCalled();
    wrapper.find(Button).at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate(); // must forceUpdate to properly mount the spy

    expect(wrapper.find(Button).at(1).text()).toContain('Submit');
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
