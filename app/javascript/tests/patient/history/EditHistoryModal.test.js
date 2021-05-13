import React from 'react';
import { shallow } from 'enzyme';
import { Button, ListGroup, Modal } from 'react-bootstrap';
import EditHistoryModal from '../../../components/patient/history/EditHistoryModal';
import { mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2 } from '../../mocks/mockHistories';
import { formatRelativePast } from '../../../utils/DateTime';

const toggleMock = jest.fn();
const historyVersions = [ mockCommentHistory2Edit2, mockCommentHistory2Edit1, mockCommentHistory2 ];

function getWrapper() {
  return shallow(<EditHistoryModal versions={historyVersions} toggle={toggleMock} />);
}

describe('EditHistoryModal', () => {
  it('Properly renders all main components of modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Comment History');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find(ListGroup).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find(ListGroup.Item).length).toEqual(historyVersions.length);
    historyVersions.forEach((history, index) => {
      expect(wrapper.find(Modal.Body).find(ListGroup.Item).at(index).find('div').text()).toEqual(history.comment);
      expect(wrapper.find(Modal.Body).find(ListGroup.Item).at(index).find('i').text())
        .toEqual(`${history.created_by} ${index === historyVersions.length-1 ? 'created' : 'edited'} ${formatRelativePast(history.created_at)}`);
    });
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(1);
    expect(wrapper.find(Modal.Footer).find(Button).text()).toEqual('Close');
    expect(wrapper.find(Modal.Footer).find(Button).prop('disabled')).toBeFalsy();
  });

  it('Clicking close button calls props.toggle', () => {
    const wrapper = getWrapper();
    expect(toggleMock).toHaveBeenCalledTimes(0);
    wrapper.find(Modal.Footer).find(Button).simulate('click');
    expect(toggleMock).toHaveBeenCalledTimes(1);
  });
});
