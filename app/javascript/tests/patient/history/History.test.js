import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Card, Col, Form, Modal } from 'react-bootstrap';
import _ from 'lodash';
import History from '../../../components/patient/history/History';
import EditHistoryModal from '../../../components/patient/history/EditHistoryModal';
import DeleteDialog from '../../../components/util/DeleteDialog';
import { mockEnrollmentHistory, mockCommentHistory1, mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2 } from '../../mocks/mockHistories';
import { mockUser1 } from '../../mocks/mockUsers';
import { formatTimestamp, formatRelativePast } from '../../../utils/DateTime';
import ReactTooltip from 'react-tooltip';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getWrapper(historyGroup) {
  return shallow(<History versions={historyGroup} current_user={mockUser1} authenticity_token={authyToken} />);
}

function getMountedWrapper(historyGroup) {
  return mount(<History versions={historyGroup} current_user={mockUser1} authenticity_token={authyToken} />);
}

describe('History', () => {
  it('Properly renders non-comment histories', () => {
    const wrapper = getWrapper([ mockEnrollmentHistory ]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockEnrollmentHistory.created_by);
    expect(wrapper.find(Card.Header).text().includes(formatTimestamp(mockEnrollmentHistory.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).text().includes(formatRelativePast(mockEnrollmentHistory.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockEnrollmentHistory.history_type);
    expect(wrapper.find(Card.Body).find(Col).text()).toEqual(mockEnrollmentHistory.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Properly renders comment histories if current user created the comment', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockCommentHistory2.created_by);
    expect(wrapper.find(Card.Header).text().includes(formatTimestamp(mockCommentHistory2.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).text().includes(formatRelativePast(mockCommentHistory2.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockCommentHistory2.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text()).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find(Button).length).toEqual(2);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').find('i').hasClass('fa-edit')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').find('i').hasClass('fa-trash')).toBeTruthy();
    expect(wrapper.find(Card.Body).find(ReactTooltip).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(0).find('span').text()).toEqual('Edit comment');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(1).find('span').text()).toEqual('Delete comment');
  });

  it('Properly renders comment histories if current user did not create the comment', () => {
    const wrapper = getWrapper([ mockCommentHistory1 ]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockCommentHistory1.created_by);
    expect(wrapper.find(Card.Header).text().includes(formatTimestamp(mockCommentHistory1.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).text().includes(formatRelativePast(mockCommentHistory1.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockCommentHistory1.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text()).toEqual(mockCommentHistory1.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Properly renders edited comment histories', () => {
    const wrapper = getWrapper([ mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2 ]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockCommentHistory2.created_by);
    expect(wrapper.find(Card.Header).text().includes(formatTimestamp(mockCommentHistory2.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).text().includes(formatRelativePast(mockCommentHistory2.created_at))).toBeTruthy();
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockCommentHistory2.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text().includes(mockCommentHistory2Edit2.comment)).toBeTruthy();
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('.edit-text').text()).toEqual('(edited)');
    expect(wrapper.find(Card.Body).find(Button).length).toEqual(3);
    expect(wrapper.find(Card.Body).find(ReactTooltip).length).toEqual(3);
    expect(wrapper.find(Card.Body).find('.history-edited-link').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('.history-edited-link').find('i').text()).toEqual('(edited)');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(0).find('span').text()).toEqual('Click to view full edit history of comment');
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').find('i').hasClass('fa-edit')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').find('i').hasClass('fa-trash')).toBeTruthy();
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(1).find('span').text()).toEqual('Edit comment');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(2).find('span').text()).toEqual('Delete comment');
  });

  it('Clicking the edit button properly renders edit mode', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    expect(wrapper.state('editMode')).toBeFalsy();
    expect(wrapper.find(Card.Body).text().includes(mockCommentHistory2.comment)).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('.character-limit-text').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeFalsy();
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('editMode')).toBeTruthy();
    expect(wrapper.find(Card.Body).text().includes(mockCommentHistory2.comment)).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('.character-limit-text').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000-mockCommentHistory2.comment.length} characters remaining`);
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').text()).toEqual('Update');
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').text()).toEqual('Cancel');
  });

  it('Editing history text properly updates state and value', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('comment')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000-mockCommentHistory2.comment.length} characters remaining`);
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'editing comment' } });
    expect(wrapper.state('comment')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000-('editing comment').length} characters remaining`);
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'editing comment again' } });
    expect(wrapper.state('comment')).toEqual('editing comment again');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment again');
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000-('editing comment again').length} characters remaining`);
  });

  it('Disables the update button when edit text input is empty or when edit text has not changed from original', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: mockCommentHistory2.comment + '!' } });
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: '' } });
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
  });

  it('Clicking the update button calls handleEditSubmit method', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    const handleEditSubmitSpy = jest.spyOn(wrapper.instance(), 'handleEditSubmit');
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(handleEditSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'updated text' } });
    expect(handleEditSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Card.Body).find('#update-edit-history-btn').simulate('click');
    expect(handleEditSubmitSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking the update button disables update and cancel buttons and updates state', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeFalsy();
    wrapper.find(Card.Body).find('#update-edit-history-btn').simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBeTruthy();
  });

  it('Clicking the cancel button exits edit mode and resets state', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    wrapper.find(Card.Body).find('#comment').simulate('change', { target: { id: 'comment', value: 'editing comment' } });
    expect(wrapper.state('editMode')).toBeTruthy();
    expect(wrapper.state('comment')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).text().includes(mockCommentHistory2.comment)).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeTruthy();
    wrapper.find(Card.Body).find('#cancel-edit-history-btn').simulate('click');
    expect(wrapper.state('editMode')).toBeFalsy();
    expect(wrapper.state('comment')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).text().includes(mockCommentHistory2.comment)).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBeFalsy();
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBeFalsy();
  });

  it('Clicking the edited link shows the delete dialog', () => {
    const wrapper = getWrapper([ mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2 ]);
    expect(wrapper.state('showEditHistoryModal')).toBeFalsy();
    expect(wrapper.find(EditHistoryModal).exists()).toBeFalsy();
    wrapper.find(Card.Body).find('.history-edited-link').simulate('click');
    expect(wrapper.state('showEditHistoryModal')).toBeTruthy();
    expect(wrapper.find(EditHistoryModal).exists()).toBeTruthy();
  });

  it('Clicking the delete button shows the delete dialog', () => {
    const wrapper = getWrapper([ mockCommentHistory2 ]);
    expect(wrapper.state('showDeleteModal')).toBeFalsy();
    expect(wrapper.find(DeleteDialog).exists()).toBeFalsy();
    wrapper.find(Card.Body).find('#delete-history-btn').simulate('click');
    expect(wrapper.state('showDeleteModal')).toBeTruthy();
    expect(wrapper.find(DeleteDialog).exists()).toBeTruthy();
  });

  it('Clicking the delete button in the delete dialog calls handleDeleteSubmit', () => {
    const wrapper = getMountedWrapper([ mockCommentHistory2 ]);
    const handleDeleteSubmitSpy = jest.spyOn(wrapper.instance(), 'handleDeleteSubmit');
    expect(handleDeleteSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#delete-history-btn').find(Button).simulate('click');
    expect(handleDeleteSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Modal).find('#delete_reason').find(Form.Control).simulate('change', { target: { id: 'delete_reason', value: 'Duplicate entry' }, persist: jest.fn() });
    expect(handleDeleteSubmitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Modal).find(Button).at(1).simulate('click');
    expect(handleDeleteSubmitSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking the cancel button in the delete dialog calls toggleDeleteModal', () => {
    const wrapper = getMountedWrapper([ mockCommentHistory2 ]);
    const toggleDeleteModalSpy = jest.spyOn(wrapper.instance(), 'toggleDeleteModal');
    expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#delete-history-btn').find(Button).simulate('click');
    expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Modal).find('#delete_reason').find(Form.Control).simulate('change', { target: { id: 'delete_reason', value: 'Duplicate entry' }, persist: jest.fn() });
    expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Modal).find(Button).at(0).simulate('click');
    expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking the cancel button in the delete dialog resets state', () => {
    const wrapper = getMountedWrapper([ mockCommentHistory2 ]);
    expect(wrapper.state('showDeleteModal')).toBeFalsy();
    expect(wrapper.state('delete_reason')).toEqual();
    expect(wrapper.state('delete_reason_text')).toEqual();
    wrapper.find('#delete-history-btn').find(Button).simulate('click');
    expect(wrapper.state('showDeleteModal')).toBeTruthy();
    expect(wrapper.state('delete_reason')).toEqual(null);
    expect(wrapper.state('delete_reason_text')).toEqual(null);
    wrapper.find(Modal).find('#delete_reason').find(Form.Control).simulate('change', { target: { id: 'delete_reason', value: 'Other' }, persist: jest.fn() });
    expect(wrapper.state('showDeleteModal')).toBeTruthy();
    expect(wrapper.state('delete_reason')).toEqual('Other');
    expect(wrapper.state('delete_reason_text')).toEqual(null);
    wrapper.find(Modal).find('#delete_reason_text').find(Form.Control).simulate('change', { target: { id: 'delete_reason_text', value: 'some comment' } });
    expect(wrapper.state('showDeleteModal')).toBeTruthy();
    expect(wrapper.state('delete_reason')).toEqual('Other');
    expect(wrapper.state('delete_reason_text')).toEqual('some comment');
    wrapper.find(Modal).find(Button).at(0).simulate('click');
    expect(wrapper.state('showDeleteModal')).toBeFalsy();
    expect(wrapper.state('delete_reason')).toEqual(null);
    expect(wrapper.state('delete_reason_text')).toEqual(null);
  });
});
