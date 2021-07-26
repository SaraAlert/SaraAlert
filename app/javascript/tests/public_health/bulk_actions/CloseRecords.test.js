import React from 'react';
import { shallow } from 'enzyme';
import CloseRecords from '../../../components/public_health/bulk_actions/CloseRecords';
import { mockPatient1, mockPatient2, mockPatient6 } from '../../mocks/mockPatients';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';

const onCloseMock = jest.fn();
const mockToken = 'testMockTokenString12345';

function getWrapper(patientsArray) {
  let wrapper = shallow(<CloseRecords authenticity_token={mockToken} patients={patientsArray} close={onCloseMock} monitoring_reasons={mockMonitoringReasons} />);
  return wrapper;
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('CloseRecords', () => {
  it('Sets intial state after mount correctly', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient6]);
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.state('monitoring')).toBeFalsy();
    expect(wrapper.state('monitoring_reason')).toEqual('');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Properly renders all main components', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient6]);
    expect(wrapper.find('p').find('span').at(0).text()).toEqual('You are about to change the Monitoring Status of the selected records from "Actively Monitoring" to "Not Monitoring".');
    expect(wrapper.find('p').find('span').at(1).text()).toEqual(' These records will be moved to the closed line list and the reason for closure will be blank.');
    expect(wrapper.find('FormGroup').length).toEqual(3);
    expect(wrapper.find('FormGroup').at(0).find('FormLabel').text()).toEqual('Please select reason for status change:');
    expect(wrapper.find('#monitoring_reason').exists()).toBeTruthy();
    const monitoringReasonOptions = [''].concat(mockMonitoringReasons);
    wrapper
      .find('#monitoring_reason')
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(monitoringReasonOptions[Number(index)]);
      });
    expect(wrapper.find('FormGroup').at(1).find('FormLabel').length).toEqual(2);
    expect(wrapper.find('FormGroup').at(1).find('FormLabel').at(0).text()).toEqual('Please include any additional details:');
    expect(wrapper.find('FormGroup').at(1).find('FormLabel').at(1).text()).toContain('characters remaining');
    expect(wrapper.find('#apply_to_household').exists()).toBeTruthy();
    expect(wrapper.find('ModalFooter').find('Button').at(0).text()).toEqual('Cancel');
    expect(wrapper.find('ModalFooter').find('Button').at(1).text()).toEqual('Submit');
  });

  it('Changing monitoring reason dropdown updates state', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient6]);

    // initial modal state with monitoring reason empty
    expect(wrapper.state('monitoring_reason')).toEqual('');
    expect(wrapper.find('p').find('span').at(1).exists()).toBeTruthy();

    // test changing to each enabled monitoring option
    mockMonitoringReasons.forEach(value => {
      wrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: value } });
      expect(wrapper.state('monitoring_reason')).toEqual(value);
      expect(wrapper.state('monitoring')).toEqual(false);
      expect(wrapper.find('p').find('span').at(1).exists()).toBeFalsy();
    });
  });

  it('Properly toggles the Apply to Household option', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient6]);
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    wrapper.find('FormCheck').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    wrapper.find('FormCheck').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
    expect(wrapper.state('apply_to_household')).toBeFalsy();
  });

  it('Properly calls the close method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient6]);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(onCloseMock).toHaveBeenCalledTimes(0);
    wrapper.find('Button').at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient6]);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate(); // must forceUpdate to properly mount the spy

    expect(wrapper.find('Button').at(1).text()).toContain('Submit');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find('Button').at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
