import React from 'react'
import { shallow } from 'enzyme';
import { Button, Dropdown, Modal, OverlayTrigger } from 'react-bootstrap';
import _ from 'lodash';
import AdvancedFilter from '../../../components/public_health/query/AdvancedFilter.js'
import { mockFilter1, mockSavedFilters } from '../../mocks/mockFilters'

const advancedFilterUpdateMock = jest.fn();
const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper() {
  return shallow(<AdvancedFilter workflow={'exposure'} advancedFilterUpdate={advancedFilterUpdateMock} updateStickySettings={true}
    authenticity_token={authyToken} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('AdvancedFilter', () => {
  it('Properly renders all Advanced Filter dropdown and button without saved filters', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(OverlayTrigger).exists()).toBeTruthy();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).find('i').hasClass('fa-microscope')).toBeTruthy();
    expect(wrapper.find(Button).text()).toEqual('Advanced Filter');
    expect(wrapper.find(Dropdown).exists()).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(1);
    expect(wrapper.find(Dropdown.Item).text()).toEqual('New filter');
    expect(wrapper.find(Dropdown.Item).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).text()).toEqual('Saved Filters');
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Properly renders all Advanced Filter dropdown and button without saved filters', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    expect(wrapper.find(OverlayTrigger).exists()).toBeTruthy();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).find('i').hasClass('fa-microscope')).toBeTruthy();
    expect(wrapper.find(Button).text()).toEqual('Advanced Filter');
    expect(wrapper.find(Dropdown).exists()).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(3);
    expect(wrapper.find(Dropdown.Item).at(0).text()).toEqual('New filter');
    expect(wrapper.find(Dropdown.Item).at(0).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).text()).toEqual('Saved Filters');
    mockSavedFilters.forEach(function(filter, index) {
      expect(wrapper.find(Dropdown.Item).at(index+1).text()).toEqual(filter.name);
    });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Clicking "Advanced Filter" button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Clicking "New Filter" dropdown option opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Dropdown.Item).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Renders all main modal components with no active filter set', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual('Advanced Filter: untitled');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-save').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-save').text()).toEqual('Save');
    expect(wrapper.find('#advanced-filter-save').find('i').hasClass('fa-save')).toBeTruthy();
    expect(wrapper.find('#advanced-filter-update').exists()).toBeFalsy();
    expect(wrapper.find('#advanced-filter-delete').exists()).toBeFalsy();
    expect(wrapper.find('#advanced-filter-reset').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-reset').text()).toEqual('Reset');
    expect(wrapper.find('#advanced-filter-apply').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-apply').text()).toEqual('Apply');
    expect(wrapper.find('.advanced-filter-statement').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find('.remove-filter-row').exists()).toBeTruthy();
    expect(wrapper.find('#add-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to the line lists in the exposure workflow until reset.');
    expect(wrapper.find(Modal.Footer).find('u').text()).toEqual('exposure');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(1);
    expect(wrapper.find(Modal.Footer).find(Button).text()).toEqual('Cancel');
  });

  // renders option dropdown

  it('Renders all main modal components with active filter set', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual(`Advanced Filter: ${mockFilter1.name}`);
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-save').exists()).toBeFalsy();
    expect(wrapper.find('#advanced-filter-update').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-update').text()).toEqual('Update');
    expect(wrapper.find('#advanced-filter-update').find('i').hasClass('fa-marker')).toBeTruthy();
    expect(wrapper.find('#advanced-filter-delete').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-delete').text()).toEqual('Delete');
    expect(wrapper.find('#advanced-filter-delete').find('i').hasClass('fa-trash')).toBeTruthy();
    expect(wrapper.find('#advanced-filter-reset').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-reset').text()).toEqual('Reset');
    expect(wrapper.find('#advanced-filter-apply').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-apply').text()).toEqual('Apply');
    expect(wrapper.find('.advanced-filter-statement').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find('.remove-filter-row').exists()).toBeTruthy();
    expect(wrapper.find('#add-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to the line lists in the exposure workflow until reset.');
    expect(wrapper.find(Modal.Footer).find('u').text()).toEqual('exposure');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(1);
    expect(wrapper.find(Modal.Footer).find(Button).text()).toEqual('Cancel');
  });

  // properly renders statements when active filter is set - click saved filter option
  // it('Renders all main modal components with no active filter set', () => {
  //   const wrapper = getWrapper();
  //   wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
  //   wrapper.find(Button).simulate('click');
  //   console.log(wrapper.debug())
  // });

  it('Clicking "+" button adds another filter statement row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, (i) => {
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i+1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
  });

  it('Clicking "+" button displays "AND" row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.and-row').length).toEqual(0);
    _.times(4, (i) => {
      wrapper.find('#add-filter-row').simulate('click');
      expect(wrapper.find('.and-row').length).toEqual(i+1);
      expect(wrapper.find('.and-row').at(i).text()).toEqual('AND');
    });
  });

  it('Adding five statements disables the "+" button', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, (i) => {
      expect(wrapper.find('#add-filter-row').prop('disabled')).toBeFalsy();
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i+1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('#add-filter-row').prop('disabled')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
  });

  it('Clicking "-" button removes filter statement row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, (i) => {
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
    expect(wrapper.find('.remove-filter-row').length).toEqual(5);
    expect(wrapper.find('.and-row').length).toEqual(4);
    _.times(5, (i) => {
      let random = _.random(1, wrapper.find('.remove-filter-row').length);
      wrapper.find('.remove-filter-row').at(random-1).simulate('click');
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(4-i);
    });
  });

  // renders each type of advanced filter
  // changing different dropdowns of each filter
  // updating state

  it('Clicking "Save" button opens Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('showFilterNameModal')).toBeFalsy();
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
  });

  it('Properly renders Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal.Header).text()).toEqual('Filter Name');
    expect(wrapper.find('#filter-name-input').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
    expect(wrapper.find('#filter-name-cancel').text()).toEqual('Cancel');
    expect(wrapper.find('#filter-name-save').text()).toEqual('Save');
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBeTruthy();
  });

  it('Adding text to Filter Name modal input enables "Save" button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual(null);
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBeFalsy();
    expect(wrapper.state('filterName')).toEqual('some filter name');
  });

  it('Clicking Filter Name modal "Cancel" button hides modal and shows Advanced Filter modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
  });

  it('Clicking Filter Name modal "Cancel" button resets modal and state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual('some filter name');
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('some filter name');
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('showFilterNameModal')).toBeFalsy();
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual(null);
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
  });

  // CLICKING CANCEL ON FILTER NAME MODAL: maintains advanced filter modal

  it('Clicking Filter Name modal "Save" button calls save method', () => {
    const wrapper = getWrapper();
    const saveSpy = jest.spyOn(wrapper.instance(), 'save');
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(saveSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(saveSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#filter-name-save').simulate('click');
    expect(saveSpy).toHaveBeenCalled();
  });

  it('Clicking Filter Name modal "Save" button hides modal and shows Advanced Filter modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    wrapper.find('#filter-name-save').simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
  });

  it('Clicking "Update" button calls update method', () => {
    const wrapper = getWrapper();
    const updateSpy = jest.spyOn(wrapper.instance(), 'update');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(updateSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-update').simulate('click');
    expect(updateSpy).toHaveBeenCalled();
  });

  it('Clicking "Delete" button calls delete method', () => {
    const wrapper = getWrapper();
    const deleteSpy = jest.spyOn(wrapper.instance(), 'delete');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(deleteSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-delete').simulate('click');
    expect(deleteSpy).toHaveBeenCalled();
  });

  it('Clicking "Reset" button calls reset method', () => {
    const wrapper = getWrapper();
    const resetSpy = jest.spyOn(wrapper.instance(), 'reset');
    wrapper.find(Button).simulate('click');
    expect(resetSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-reset').simulate('click');
    expect(resetSpy).toHaveBeenCalled();
  });

  it('Clicking "Apply" button calls props.advancedFilterUpdate', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(0);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalled();
  });

  // CHECK LAST APPLIED STATE HERE
  it('Clicking "Apply" button properly updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('applied')).toBeFalsy();
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('applied')).toBeTruthy();
  });

  it('Clicking "Clear current filter" dropdown option calls props.advancedFilterUpdate', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(0);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(1);
    console.log(wrapper.find(Dropdown.Item).at(1).debug())
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(2);
  });

  // CHECK UPDATING STATE HERE
  it('Clicking "Clear current filter" dropdown option properly updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(0);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(1);
    console.log(wrapper.find(Dropdown.Item).at(1).debug())
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(2);
  });

  it('Clicking "Cancel" button calls cancel method and hides modal', () => {
    const wrapper = getWrapper();
    const cancelSpy = jest.spyOn(wrapper.instance(), 'cancel');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(cancelSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-cancel').simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    expect(cancelSpy).toHaveBeenCalled();
  });

  // cancel clearing state - with saved, untitled, non-applied
  // check last applied state stuff
  // it('Clicking "Cancel" button hides modal and resets state', () => {
  //   const wrapper = getWrapper();
  //   wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
  //   wrapper.find(Button).simulate('click');
  //   expect(wrapper.state('show')).toBeTruthy();
  //   expect(wrapper.state('applied')).toBeFalsy();
  //   expect(wrapper.state('activeFilterOptions')).toEqual(mockFilter1.contents);
  //   expect(wrapper.state('activeFilter')).toEqual(mockFilter1);
  //   wrapper.find('#advanced-filter-cancel').simulate('click');
  //   expect(wrapper.state('show')).toBeFalsy();
  //   expect(wrapper.state('applied')).toBeFalsy();
  //   expect(wrapper.state('activeFilterOptions')).toEqual([ { filterOption: null } ]);
  //   expect(wrapper.state('activeFilter')).toEqual(null);
  // });

  // it('Hitting the escape key button calls cancel method and hides modal', () => {
  //   const wrapper = getWrapper();
  //   const cancelSpy = jest.spyOn(wrapper.instance(), 'cancel');
  //   wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
  //   wrapper.find(Button).simulate('click');
  //   expect(wrapper.find(Modal).exists()).toBeTruthy();
  //   expect(cancelSpy).toHaveBeenCalledTimes(0);
  //   wrapper.find('#advanced-filter-cancel').simulate('click');
  //   expect(wrapper.find(Modal).exists()).toBeFalsy();
  //   expect(cancelSpy).toHaveBeenCalled();
  // });

  // can you test local storage?
  // MAKE SURE ALL STATE IS SET CORRECTLY
});