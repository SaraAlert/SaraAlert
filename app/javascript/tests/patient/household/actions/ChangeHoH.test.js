import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import ChangeHoH from '../../../../components/patient/household/actions/ChangeHoH';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../../mocks/mockPatients';
import { formatNameAlt } from '../../../helpers';

const mockToken = 'testMockTokenString12345';
const dependents = [mockPatient2, mockPatient3, mockPatient4];

function getWrapper() {
  return shallow(<ChangeHoH patient={mockPatient1} dependents={dependents} authenticity_token={mockToken} />);
}

describe('ChangeHoH', () => {
  it('Properly renders Change HoH button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text()).toContain('Change Head of Household');
    expect(wrapper.find('i').hasClass('fa-house-user')).toBe(true);
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
  });

  it('Clicking the Change HoH button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders Change HoH modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Edit Head of Household');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Form.Label).at(0).text()).toEqual('Select The New Head Of Household');
    expect(wrapper.find(Modal.Body).find(Form.Label).at(1).text()).toEqual('Note: The selected monitoree will become the responder for the current monitoree and all others within the list');
    expect(wrapper.find('#hoh_selection').exists()).toBe(true);
    expect(wrapper.find('#hoh_selection').prop('defaultValue')).toEqual(-1);
    expect(wrapper.find('#hoh_selection').find('option').length).toEqual(dependents.length + 1);
    expect(wrapper.find('#hoh_selection').find('option').at(0).prop('value')).toEqual(-1);
    expect(wrapper.find('#hoh_selection').find('option').at(0).prop('disabled')).toBe(true);
    expect(wrapper.find('#hoh_selection').find('option').at(0).text()).toEqual('--');
    dependents.forEach((dependent, index) => {
      expect(
        wrapper
          .find('#hoh_selection')
          .find('option')
          .at(index + 1)
          .prop('value')
      ).toEqual(dependent.id);
      expect(
        wrapper
          .find('#hoh_selection')
          .find('option')
          .at(index + 1)
          .prop('disabled')
      ).toBeUndefined();
      expect(
        wrapper
          .find('#hoh_selection')
          .find('option')
          .at(index + 1)
          .text()
      ).toEqual(formatNameAlt(dependent));
    });
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Update');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
  });

  it('Changing HoH dropdown selection properly updates state', () => {
    const wrapper = getWrapper();
    let random = _.random(0, dependents.length - 1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('hoh_selection')).toBeNull();
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[`${random}`].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[`${random}`].id);
    random = _.random(0, dependents.length - 1);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[`${random}`].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[`${random}`].id);
    random = _.random(0, dependents.length - 1);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[`${random}`].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[`${random}`].id);
  });

  it('Selecting a dependent enables the update button', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
  });

  it('Clicking the update button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find(Button).simulate('click');
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

  it('Clicking the update button disables the button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(wrapper.state('loading')).toBe(true);
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[0].id);
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
    expect(wrapper.state('hoh_selection')).toBeNull();
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
  });
});
