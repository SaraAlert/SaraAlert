import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card, Col } from 'react-bootstrap';
import _ from 'lodash';
import History from '../../../components/patient/history/History';
import { mockHistory1, mockHistory2, mockHistory3 } from '../../mocks/mockHistories';
import { formatTimestamp, formatRelativePast } from '../../../utils/DateTime';
import ReactTooltip from 'react-tooltip';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getWrapper(history) {
  return shallow(<History key={history.id} history={history} authenticity_token={authyToken} />);
}

describe('History', () => {
  it('Properly renders non-comment histories', () => {
    const wrapper = getWrapper(mockHistory1);
    expect(wrapper.find(Card.Header).find('b').exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockHistory1.created_by);
    expect(wrapper.find(Card.Header).text().includes(formatTimestamp(mockHistory1.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).text().includes(formatRelativePast(mockHistory1.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockHistory1.history_type);
    expect(wrapper.find(Card.Body).find(Col).text()).toEqual(mockHistory1.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Properly renders comment histories', () => {
    const wrapper = getWrapper(mockHistory2);
    expect(wrapper.find(Card.Header).find('b').exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockHistory2.created_by);
    expect(wrapper.find(Card.Header).text().includes(formatTimestamp(mockHistory2.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).text().includes(formatRelativePast(mockHistory2.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockHistory2.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text()).toEqual(mockHistory2.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find(Button).length).toEqual(2);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').find('i').hasClass('fa-edit')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').find('i').hasClass('fa-trash')).toBeTruthy();
    expect(wrapper.find(Card.Body).find(ReactTooltip).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(0).find('span').text()).toEqual('You may edit comments you have added');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(1).find('span').text()).toEqual('You may delete comments you have added');
  });

  it('Clicking the edit button properly renders edit mode', () => {
    const wrapper = getWrapper(mockHistory2);
    expect(wrapper.state('editMode')).toBeFalsy();
    expect(wrapper.find(Card.Body).text().includes(mockHistory2.comment)).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeFalsy();
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('editMode')).toBeTruthy();
    expect(wrapper.find(Card.Body).text().includes(mockHistory2.comment)).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual(mockHistory2.comment);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').text()).toEqual('Update');
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').text()).toEqual('Cancel');
  });

  it('Editing history text properly updates state and value', () => {
    const wrapper = getWrapper(mockHistory2);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('comment')).toEqual(mockHistory2.comment);
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual(mockHistory2.comment);
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'editing comment' } });
    expect(wrapper.state('comment')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'editing comment again' } });
    expect(wrapper.state('comment')).toEqual('editing comment again');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment again');
  });

  it('Disables the update button when edit text input is empty', () => {
    const wrapper = getWrapper(mockHistory2);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: '' } });
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
  });

  it('Clicking the update button calls handleEditSubmit method', () => {
    const wrapper = getWrapper(mockHistory2);
    const handleEditSubmitSpy = jest.spyOn(wrapper.instance(), 'handleEditSubmit');
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(handleEditSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'updated text' } });
    expect(handleEditSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Card.Body).find('#update-edit-history-btn').simulate('click');
    expect(handleEditSubmitSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking the update button disables update and cancel buttons and updates state', () => {
    const wrapper = getWrapper(mockHistory2);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
    wrapper.find(Card.Body).find('#update-edit-history-btn').simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeTruthy();
  });

  it('Clicking the cancel button exits edit mode and resets state', () => {
    const wrapper = getWrapper(mockHistory2);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'editing comment' } });
    expect(wrapper.state('editMode')).toBeTruthy();
    expect(wrapper.state('comment')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).text().includes(mockHistory2.comment)).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeTruthy();
    wrapper.find(Card.Body).find('#cancel-edit-history-btn').simulate('click');
    expect(wrapper.state('editMode')).toBeFalsy();
    expect(wrapper.state('comment')).toEqual(mockHistory2.comment);
    expect(wrapper.find(Card.Body).text().includes(mockHistory2.comment)).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeFalsy();
  });

  it('Properly renders "edited" tag if comment was edited', () => {
    const wrapper = getWrapper(mockHistory3);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('.edit-text').text()).toEqual(' (edited)');
  });

  it('Clicking the delete button calls delete method', () => {
    const wrapper = getWrapper(mockHistory2);
    const deleteSpy = jest.spyOn(wrapper.instance(), 'delete');
    expect(deleteSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Card.Body).find('#delete-history-btn').simulate('click');
    expect(deleteSpy).toHaveBeenCalledTimes(1);
  });
});