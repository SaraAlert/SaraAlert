import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Card, Col, Form, Modal } from 'react-bootstrap';
import History from '../../../components/patient/history/History';
import EditHistoryModal from '../../../components/patient/history/EditHistoryModal';
import DeleteDialog from '../../../components/util/DeleteDialog';
import { mockEnrollmentHistory, mockCommentHistory1, mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2 } from '../../mocks/mockHistories';
import { mockUser1 } from '../../mocks/mockUsers';
import { formatTimestamp, formatRelativePast } from '../../../utils/DateTime';
import ReactTooltip from 'react-tooltip';

const mockToken = 'testMockTokenString12345';

function getShallowWrapper(historyGroup) {
  return shallow(<History versions={historyGroup} current_user={mockUser1} authenticity_token={mockToken} />);
}

function getMountedWrapper(historyGroup) {
  return mount(<History versions={historyGroup} current_user={mockUser1} authenticity_token={mockToken} />);
}

describe('History', () => {
  it('Properly renders non-comment histories', () => {
    const wrapper = getShallowWrapper([mockEnrollmentHistory]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBe(true);
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockEnrollmentHistory.created_by);
    expect(wrapper.find(Card.Header).text()).toContain(formatTimestamp(mockEnrollmentHistory.created_at));
    expect(wrapper.find(Card.Header).text()).toContain(formatRelativePast(mockEnrollmentHistory.created_at));
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockEnrollmentHistory.history_type);
    expect(wrapper.find(Card.Body).find(Col).text()).toEqual(mockEnrollmentHistory.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(ReactTooltip).exists()).toBe(false);
  });

  it('Properly renders comment histories if current user created the comment', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBe(true);
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockCommentHistory2.created_by);
    expect(wrapper.find(Card.Header).text()).toContain(formatTimestamp(mockCommentHistory2.created_at));
    expect(wrapper.find(Card.Header).text()).toContain(formatRelativePast(mockCommentHistory2.created_at));
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockCommentHistory2.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text()).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(Button).length).toEqual(2);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').find('i').hasClass('fa-edit')).toBe(true);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').find('i').hasClass('fa-trash')).toBe(true);
    expect(wrapper.find(Card.Body).find(ReactTooltip).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(0).find('span').text()).toEqual('Edit comment');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(1).find('span').text()).toEqual('Delete comment');
  });

  it('Properly renders comment histories if current user did not create the comment', () => {
    const wrapper = getShallowWrapper([mockCommentHistory1]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBe(true);
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockCommentHistory1.created_by);
    expect(wrapper.find(Card.Header).text()).toContain(formatTimestamp(mockCommentHistory1.created_at));
    expect(wrapper.find(Card.Header).text()).toContain(formatRelativePast(mockCommentHistory1.created_at));
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockCommentHistory1.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text()).toEqual(mockCommentHistory1.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(ReactTooltip).exists()).toBe(false);
  });

  it('Properly renders edited comment histories', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2]);
    expect(wrapper.find(Card.Header).find('b').exists()).toBe(true);
    expect(wrapper.find(Card.Header).find('b').text()).toEqual(mockCommentHistory2.created_by);
    expect(wrapper.find(Card.Header).text()).toContain(formatTimestamp(mockCommentHistory2.created_at));
    expect(wrapper.find(Card.Header).text()).toContain(formatRelativePast(mockCommentHistory2.created_at));
    expect(wrapper.find(Card.Header).find('.badge').text()).toEqual(mockCommentHistory2.history_type);
    expect(wrapper.find(Card.Body).find(Col).at(0).text()).toContain(mockCommentHistory2Edit2.comment);
    expect(wrapper.find(Card.Body).find('.edit-text').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('.edit-text').text()).toEqual('(edited)');
    expect(wrapper.find(Card.Body).find(Button).length).toEqual(3);
    expect(wrapper.find(Card.Body).find(ReactTooltip).length).toEqual(3);
    expect(wrapper.find(Card.Body).find('.history-edited-link').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('.history-edited-link').find('i').text()).toEqual('(edited)');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(0).find('span').text()).toEqual('Click to view full edit history of comment');
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').find('i').hasClass('fa-edit')).toBe(true);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').find('i').hasClass('fa-trash')).toBe(true);
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(1).find('span').text()).toEqual('Edit comment');
    expect(wrapper.find(Card.Body).find(ReactTooltip).at(2).find('span').text()).toEqual('Delete comment');
  });

  it('Clicking the edit button properly renders edit mode', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    expect(wrapper.state('editMode')).toBe(false);
    expect(wrapper.find(Card.Body).text()).toContain(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('.character-limit-text').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBe(false);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('editMode')).toBe(true);
    expect(wrapper.find(Card.Body).text()).not.toContain(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('.character-limit-text').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000 - mockCommentHistory2.comment.length} characters remaining`);
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').text()).toEqual('Update');
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').text()).toEqual('Cancel');
  });

  it('Editing history text properly updates state and value', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('comment')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000 - mockCommentHistory2.comment.length} characters remaining`);
    wrapper
      .find(Card.Body)
      .find('#comment')
      .simulate('change', { target: { id: 'comment', value: 'editing comment' } });
    expect(wrapper.state('comment')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000 - 'editing comment'.length} characters remaining`);
    wrapper
      .find(Card.Body)
      .find('#comment')
      .simulate('change', { target: { id: 'comment', value: 'editing comment again' } });
    expect(wrapper.state('comment')).toEqual('editing comment again');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment again');
    expect(wrapper.find(Card.Body).find('.character-limit-text').text()).toEqual(`${10000 - 'editing comment again'.length} characters remaining`);
  });

  it('Disables the update button when edit text input is empty or when edit text has not changed from original', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBe(true);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBe(false);
    wrapper
      .find(Card.Body)
      .find('#comment')
      .simulate('change', { target: { id: 'comment', value: mockCommentHistory2.comment + '!' } });
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBe(false);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBe(false);
    wrapper
      .find(Card.Body)
      .find('#comment')
      .simulate('change', { target: { id: 'comment', value: '' } });
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBe(true);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBe(false);
  });

  it('Clicking the update button calls handleEditSubmit method', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    const handleEditSubmitSpy = jest.spyOn(wrapper.instance(), 'handleEditSubmit');
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(handleEditSubmitSpy).not.toHaveBeenCalled();
    wrapper
      .find(Card.Body)
      .find('#comment')
      .simulate('change', { target: { id: 'comment', value: 'updated text' } });
    expect(handleEditSubmitSpy).not.toHaveBeenCalled();
    wrapper.find(Card.Body).find('#update-edit-history-btn').simulate('click');
    expect(handleEditSubmitSpy).toHaveBeenCalled();
  });

  it('Clicking the update button disables update and cancel buttons and updates state', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBe(true);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBe(false);
    wrapper.find(Card.Body).find('#update-edit-history-btn').simulate('click');
    expect(wrapper.state('loading')).toBe(true);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').prop('disabled')).toBe(true);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').prop('disabled')).toBe(true);
  });

  it('Clicking the cancel button exits edit mode and resets state', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    wrapper.find(Card.Body).find('#edit-history-btn').simulate('click');
    wrapper
      .find(Card.Body)
      .find('#comment')
      .simulate('change', { target: { id: 'comment', value: 'editing comment' } });
    expect(wrapper.state('editMode')).toBe(true);
    expect(wrapper.state('comment')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).text()).not.toContain(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#comment').prop('value')).toEqual('editing comment');
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBe(true);
    wrapper.find(Card.Body).find('#cancel-edit-history-btn').simulate('click');
    expect(wrapper.state('editMode')).toBe(false);
    expect(wrapper.state('comment')).toEqual(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).text()).toContain(mockCommentHistory2.comment);
    expect(wrapper.find(Card.Body).find('#edit-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#delete-history-btn').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('#comment').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#update-edit-history-btn').exists()).toBe(false);
    expect(wrapper.find(Card.Body).find('#cancel-edit-history-btn').exists()).toBe(false);
  });

  it('Clicking the edited link shows the delete dialog', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2]);
    expect(wrapper.state('showEditHistoryModal')).toBe(false);
    expect(wrapper.find(EditHistoryModal).exists()).toBe(false);
    wrapper.find(Card.Body).find('.history-edited-link').simulate('click');
    expect(wrapper.state('showEditHistoryModal')).toBe(true);
    expect(wrapper.find(EditHistoryModal).exists()).toBe(true);
  });

  it('Clicking the delete button shows the delete dialog', () => {
    const wrapper = getShallowWrapper([mockCommentHistory2]);
    expect(wrapper.state('showDeleteModal')).toBe(false);
    expect(wrapper.find(DeleteDialog).exists()).toBe(false);
    wrapper.find(Card.Body).find('#delete-history-btn').simulate('click');
    expect(wrapper.state('showDeleteModal')).toBe(true);
    expect(wrapper.find(DeleteDialog).exists()).toBe(true);
  });

  it('Clicking the delete button in the delete dialog calls handleDeleteSubmit', () => {
    const wrapper = getMountedWrapper([mockCommentHistory2]);
    const handleDeleteSubmitSpy = jest.spyOn(wrapper.instance(), 'handleDeleteSubmit');
    expect(handleDeleteSubmitSpy).not.toHaveBeenCalled();
    wrapper.find('#delete-history-btn').find(Button).simulate('click');
    expect(handleDeleteSubmitSpy).not.toHaveBeenCalled();
    wrapper
      .find(Modal)
      .find('#delete_reason')
      .find(Form.Control)
      .simulate('change', { target: { id: 'delete_reason', value: 'Duplicate entry' }, persist: jest.fn() });
    expect(handleDeleteSubmitSpy).not.toHaveBeenCalled();
    wrapper.find(Modal).find(Button).at(1).simulate('click');
    expect(handleDeleteSubmitSpy).toHaveBeenCalled();
  });

  it('Clicking the cancel button in the delete dialog calls toggleDeleteModal', () => {
    const wrapper = getMountedWrapper([mockCommentHistory2]);
    const toggleDeleteModalSpy = jest.spyOn(wrapper.instance(), 'toggleDeleteModal');
    expect(toggleDeleteModalSpy).not.toHaveBeenCalled();
    wrapper.find('#delete-history-btn').find(Button).simulate('click');
    expect(toggleDeleteModalSpy).not.toHaveBeenCalled();
    wrapper
      .find(Modal)
      .find('#delete_reason')
      .find(Form.Control)
      .simulate('change', { target: { id: 'delete_reason', value: 'Duplicate entry' }, persist: jest.fn() });
    expect(toggleDeleteModalSpy).not.toHaveBeenCalled();
    wrapper.find(Modal).find(Button).at(0).simulate('click');
    expect(toggleDeleteModalSpy).toHaveBeenCalled();
  });

  it('Clicking the cancel button in the delete dialog resets state', () => {
    const wrapper = getMountedWrapper([mockCommentHistory2]);
    expect(wrapper.state('showDeleteModal')).toBe(false);
    expect(wrapper.state('delete_reason')).toEqual();
    expect(wrapper.state('delete_reason_text')).toEqual();
    wrapper.find('#delete-history-btn').find(Button).simulate('click');
    expect(wrapper.state('showDeleteModal')).toBe(true);
    expect(wrapper.state('delete_reason')).toBeNull();
    expect(wrapper.state('delete_reason_text')).toBeNull();
    wrapper
      .find(Modal)
      .find('#delete_reason')
      .find(Form.Control)
      .simulate('change', { target: { id: 'delete_reason', value: 'Other' }, persist: jest.fn() });
    expect(wrapper.state('showDeleteModal')).toBe(true);
    expect(wrapper.state('delete_reason')).toEqual('Other');
    expect(wrapper.state('delete_reason_text')).toBeNull();
    wrapper
      .find(Modal)
      .find('#delete_reason_text')
      .find(Form.Control)
      .simulate('change', { target: { id: 'delete_reason_text', value: 'some comment' } });
    expect(wrapper.state('showDeleteModal')).toBe(true);
    expect(wrapper.state('delete_reason')).toEqual('Other');
    expect(wrapper.state('delete_reason_text')).toEqual('some comment');
    wrapper.find(Modal).find(Button).at(0).simulate('click');
    expect(wrapper.state('showDeleteModal')).toBe(false);
    expect(wrapper.state('delete_reason')).toBeNull();
    expect(wrapper.state('delete_reason_text')).toBeNull();
  });
});
