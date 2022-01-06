import React from 'react';
import { expect } from '@jest/globals';
import { shallow, mount } from 'enzyme';
import { Button, Card, Dropdown, InputGroup } from 'react-bootstrap';
import _ from 'lodash';

import LaboratoryTable from '../../../components/patient/laboratory/LaboratoryTable';
import LaboratoryModal from '../../../components/patient/laboratory/LaboratoryModal';
import CustomTable from '../../../components/layout/CustomTable';
import DeleteDialog from '../../../components/util/DeleteDialog';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockLaboratory1, mockLaboratory2, mockLaboratory3 } from '../../mocks/mockLaboratories';
import { mockPatient1 } from '../../mocks/mockPatients';
import { mockUser1 } from '../../mocks/mockUsers';
import { formatDate } from '../../helpers';

const AUTHY_TOKEN = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const MOCK_LABS = [mockLaboratory1, mockLaboratory2, mockLaboratory3];

function getShallowWrapper(additionalProps) {
  return shallow(<LaboratoryTable patient={mockPatient1} current_user={mockUser1} authenticity_token={AUTHY_TOKEN} num_pos_labs={1} {...additionalProps} />);
}

function getMountedWrapper(labs, additionalProps) {
  let wrapper = mount(<LaboratoryTable patient={mockPatient1} current_user={mockUser1} authenticity_token={AUTHY_TOKEN} num_pos_labs={1} {...additionalProps} />);

  // The Table Data is loaded asynchronously, so we have to mock it
  wrapper.setState({ table: { ...wrapper.state('table'), rowData: labs || [] } });
  return wrapper;
}

describe('LaboratoryTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = getShallowWrapper();
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toContain('Lab Results');
    expect(wrapper.find(Card.Header).find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(Card.Header).find(InfoTooltip).prop('tooltipTextKey')).toEqual('labResults');
    expect(wrapper.find(Button).at(0).text()).toContain('Add New Lab Result');
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
    expect(wrapper.find(LaboratoryModal).exists()).toBe(false);
    expect(wrapper.find(DeleteDialog).exists()).toBe(false);
  });

  it('Clicking the "Add New Laboratory" button opens the Laboratory Modal', () => {
    const wrapper = getShallowWrapper();
    expect(wrapper.find(LaboratoryModal).exists()).toBe(false);
    expect(wrapper.find(Button).at(0).text()).toContain('Add New Lab Result');
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(LaboratoryModal).exists()).toBe(true);
  });

  it('Inputting search texts calls the handleSearchChange function', () => {
    const wrapper = getShallowWrapper();
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'handleSearchChange');
    const updateTableSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    wrapper.instance().forceUpdate();
    expect(handleSearchChangeSpy).not.toHaveBeenCalled();
    expect(updateTableSpy).not.toHaveBeenCalled();

    let query = wrapper.state('query');
    let searchText = 'some text';
    query.search = searchText;
    wrapper.find('#laboratories-search-input').simulate('change', { target: { id: 'laboratories-search-input', value: searchText } });
    expect(handleSearchChangeSpy).toHaveBeenCalledWith({ target: { id: 'laboratories-search-input', value: searchText } });
    expect(updateTableSpy).toHaveBeenCalledWith(query);
    expect(wrapper.state('query')).toEqual(query);
  });

  it('Inputting search texts calls the handleSearchChange function', () => {
    const wrapper = getShallowWrapper();
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'handleSearchChange');
    const updateTableSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    wrapper.instance().forceUpdate();
    expect(handleSearchChangeSpy).not.toHaveBeenCalled();
    expect(updateTableSpy).not.toHaveBeenCalled();

    let query = wrapper.state('query');
    let searchText = 'some text';
    query.search = searchText;
    wrapper.find('#laboratories-search-input').simulate('change', { target: { id: 'laboratories-search-input', value: searchText } });
    expect(handleSearchChangeSpy).toHaveBeenCalledWith({ target: { id: 'laboratories-search-input', value: searchText } });
    expect(updateTableSpy).toHaveBeenCalledWith(query);
    expect(wrapper.state('query')).toEqual(query);
  });

  it('Properly renders an empty table when a monitoree has zero labs', () => {
    const wrapper = getMountedWrapper([]);
    expect(wrapper.find('table').find('tbody').find('tr').length).toEqual(1);
    expect(wrapper.find('table').find('tbody').text()).toEqual('No data available in table.');
  });

  it('Properly renders the table with data when a monitoree has at least one lab', () => {
    const wrapper = getMountedWrapper(MOCK_LABS);
    expect(wrapper.find('table').find('tbody').find('tr').length).toEqual(MOCK_LABS.length);
    MOCK_LABS.forEach((lab, labIndex) => {
      let row = wrapper.find('table').find('tbody').find('tr').at(labIndex);
      expect(row.find('td').at(1).text()).toEqual(String(lab.id));
      expect(row.find('td').at(2).text()).toEqual(lab.lab_type || '');
      expect(row.find('td').at(3).text()).toEqual(formatDate(lab.specimen_collection));
      expect(row.find('td').at(4).text()).toEqual(formatDate(lab.report));
      expect(row.find('td').at(5).text()).toEqual(lab.result || '');
    });
  });

  it('Properly renders row action dropdown', () => {
    const wrapper = getMountedWrapper(MOCK_LABS);
    _.times(MOCK_LABS.length, index => {
      wrapper.find(Dropdown).at(index).find(Dropdown.Toggle).simulate('click');
      expect(wrapper.find(Dropdown).at(index).find(Dropdown.Item).length).toEqual(2);
      expect(wrapper.find(Dropdown).at(index).find(Dropdown.Item).first().text()).toEqual('Edit');
      expect(wrapper.find(Dropdown).at(index).find(Dropdown.Item).last().text()).toEqual('Delete');
    });
  });

  it('Clicking the edit dropdown option toggles the Laboratory Modal', () => {
    const wrapper = getMountedWrapper(MOCK_LABS);
    const toggleEditModalSpy = jest.spyOn(wrapper.instance(), 'toggleEditModal');
    wrapper.instance().forceUpdate();
    expect(toggleEditModalSpy).not.toHaveBeenCalled();
    expect(wrapper.find(LaboratoryModal).exists()).toBe(false);
    expect(wrapper.state('showEditModal')).toBe(false);

    _.times(MOCK_LABS.length, index => {
      // open modal
      wrapper.find(Dropdown).at(index).find(Dropdown.Toggle).simulate('click');
      wrapper.find(Dropdown).at(index).find(Dropdown.Item).first().simulate('click');
      expect(toggleEditModalSpy).toHaveBeenCalledTimes(2 * index + 1);
      expect(toggleEditModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(LaboratoryModal).exists()).toBe(true);
      expect(wrapper.state('showEditModal')).toBe(true);

      // close modal
      wrapper.find(LaboratoryModal).find(Button).first().simulate('click');
      expect(toggleEditModalSpy).toHaveBeenCalledTimes(2 * (index + 1));
      expect(toggleEditModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(LaboratoryModal).exists()).toBe(false);
      expect(wrapper.state('showEditModal')).toBe(false);
    });
  });

  it('Clicking the delete dropdown option toggles the Delete Dialog', () => {
    const wrapper = getMountedWrapper(MOCK_LABS);
    const toggleDeleteModalSpy = jest.spyOn(wrapper.instance(), 'toggleDeleteModal');
    wrapper.instance().forceUpdate();
    expect(toggleDeleteModalSpy).not.toHaveBeenCalled();
    expect(wrapper.find(DeleteDialog).exists()).toBe(false);
    expect(wrapper.state('showDeleteModal')).toBe(false);

    _.times(MOCK_LABS.length, index => {
      // open modal
      wrapper.find(Dropdown).at(index).find(Dropdown.Toggle).simulate('click');
      wrapper.find(Dropdown).at(index).find(Dropdown.Item).last().simulate('click');
      expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(2 * index + 1);
      expect(toggleDeleteModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(DeleteDialog).exists()).toBe(true);
      expect(wrapper.state('showDeleteModal')).toBe(true);

      // close modal
      wrapper.find(DeleteDialog).find(Button).first().simulate('click');
      expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(2 * (index + 1));
      expect(toggleDeleteModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(DeleteDialog).exists()).toBe(false);
      expect(wrapper.state('showDeleteModal')).toBe(false);
    });
  });
});
