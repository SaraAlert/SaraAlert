import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card } from 'react-bootstrap';
import _ from 'lodash';
import Select from 'react-select';
import Pagination from 'jw-react-pagination';
import HistoryList from '../../../components/patient/history/HistoryList';
import History from '../../../components/patient/history/History';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockEnrollmentHistory, mockCommentHistory1, mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2 } from '../../mocks/mockHistories';

const mockToken = 'testMockTokenString12345';
const histories = [[mockEnrollmentHistory], [mockCommentHistory2, mockCommentHistory2Edit1, mockCommentHistory2Edit2], [mockCommentHistory1]];
let historyCreators = _.orderBy(
  histories.map(history_group => history_group[0].created_by),
  x => x,
  'asc'
);
historyCreators = historyCreators.filter((creator, index) => historyCreators.includes(creator) && index === historyCreators.indexOf(creator));
let historyTypes = _.orderBy(
  histories.map(history_group => history_group[0].history_type),
  x => x,
  'asc'
);
historyTypes = historyTypes.filter((type, index) => historyTypes.includes(type) && index === historyTypes.indexOf(type));

function getWrapper() {
  return shallow(<HistoryList patient_id={17} histories={histories} current_user={mockUser1} authenticity_token={mockToken} history_types={{ enrollment: 'Enrollment', comment: 'Comment' }} />);
}

describe('HistoryList', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('#histories').exists()).toBeTruthy();
    expect(wrapper.find('.patient-card-header').text()).toContain('History');
    expect(wrapper.find('.patient-card-header').find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find('.patient-card-header').find(InfoTooltip).prop('tooltipTextKey')).toEqual('history');
    expect(wrapper.find('#history-filters').exists()).toBeTruthy();
    expect(wrapper.find(Select).length).toEqual(2);
    expect(
      wrapper
        .find(Select)
        .at(0)
        .prop('placeholder')
    ).toEqual('Filter by Creator');
    expect(
      wrapper
        .find(Select)
        .at(0)
        .prop('options')[0].label
    ).toEqual('History Creator');
    wrapper
      .find(Select)
      .at(0)
      .prop('options')[0]
      .options.forEach((option, index) => {
        expect(option.label).toEqual(historyCreators[Number(index)]);
        expect(option.value).toEqual(historyCreators[Number(index)]);
      });
    expect(
      wrapper
        .find(Select)
        .at(1)
        .prop('placeholder')
    ).toEqual('Filter by Type');
    expect(
      wrapper
        .find(Select)
        .at(1)
        .prop('options')[0].label
    ).toEqual('History Type');
    wrapper
      .find(Select)
      .at(1)
      .prop('options')[0]
      .options.forEach((option, index) => {
        expect(option.label).toEqual(historyTypes[Number(index)]);
        expect(option.value).toEqual(historyTypes[Number(index)]);
      });
    expect(
      wrapper
        .find(Card.Body)
        .find(History)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Pagination)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Card)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Card.Header)
        .text()
    ).toEqual('Add Comment');
    expect(
      wrapper
        .find(Card.Body)
        .find('#comment')
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find('.character-limit-text')
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find('.character-limit-text')
        .text()
    ).toEqual('10000 characters remaining');
    expect(
      wrapper
        .find(Card.Body)
        .find(Button)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Button)
        .text()
    ).toEqual(' Add Comment');
    expect(
      wrapper
        .find(Card.Body)
        .find(Button)
        .find('i')
        .hasClass('fa-comment-dots')
    ).toBeTruthy();
  });

  it('Selecting history creators in dropdown properly updates state', () => {
    const wrapper = getWrapper();
    let filterValue = [];
    expect(wrapper.state('filters').creatorFilters).toEqual(filterValue);
    filterValue.push({ label: historyCreators[0], value: historyCreators[0] });
    wrapper
      .find(Select)
      .at(0)
      .simulate('change', filterValue);
    expect(wrapper.state('filters').creatorFilters).toEqual(historyCreators.slice(0, 1));
    filterValue.push({ label: historyCreators[1], value: historyCreators[1] });
    wrapper
      .find(Select)
      .at(0)
      .simulate('change', filterValue);
    expect(wrapper.state('filters').creatorFilters).toEqual(historyCreators);
  });

  it('Selecting history type in dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    let filterValue = [];
    expect(wrapper.state('filters').typeFilters).toEqual(filterValue);
    filterValue.push({ label: historyTypes[0], value: historyTypes[0] });
    wrapper
      .find(Select)
      .at(1)
      .simulate('change', filterValue);
    expect(wrapper.state('filters').typeFilters).toEqual(historyTypes.slice(0, 1));
    filterValue.push({ label: historyTypes[1], value: historyTypes[1] });
    wrapper
      .find(Select)
      .at(1)
      .simulate('change', filterValue);
    expect(wrapper.state('filters').typeFilters).toEqual(historyTypes);
  });

  it('Selecting history dropdown filters properly filters histories', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(History).length).toEqual(histories.length);
    expect(wrapper.state('filteredHistories')).toEqual(histories);
    expect(wrapper.state('displayedHistories')).toEqual(histories);

    let filteredHistories = histories.filter(history_group => history_group[0].created_by === historyCreators[0]);
    wrapper
      .find(Select)
      .at(0)
      .simulate('change', [{ label: historyCreators[0], value: historyCreators[0] }]);
    expect(wrapper.find(History).length).toEqual(filteredHistories.length);
    expect(wrapper.state('filteredHistories')).toEqual(filteredHistories);
    expect(wrapper.state('displayedHistories')).toEqual(filteredHistories);

    filteredHistories = filteredHistories.filter(history_group => history_group[0].history_type === historyTypes[0]);
    wrapper
      .find(Select)
      .at(1)
      .simulate('change', [{ label: historyTypes[0], value: historyTypes[0] }]);
    expect(wrapper.find(History).length).toEqual(filteredHistories.length);
    expect(wrapper.state('filteredHistories')).toEqual(filteredHistories);
    expect(wrapper.state('displayedHistories')).toEqual(filteredHistories);

    filteredHistories = histories.filter(history_group => history_group[0].history_type === historyTypes[0]);
    wrapper
      .find(Select)
      .at(0)
      .simulate('change', []);
    expect(wrapper.find(History).length).toEqual(filteredHistories.length);
    expect(wrapper.state('filteredHistories')).toEqual(filteredHistories);
    expect(wrapper.state('displayedHistories')).toEqual(filteredHistories);

    filteredHistories = histories.filter(history_group => history_group[0].history_type === historyTypes[0] || history_group[0].history_type === historyTypes[1]);
    wrapper
      .find(Select)
      .at(1)
      .simulate('change', [
        { label: historyTypes[0], value: historyTypes[0] },
        { label: historyTypes[1], value: historyTypes[1] },
      ]);
    expect(wrapper.find(History).length).toEqual(filteredHistories.length);
    expect(wrapper.state('filteredHistories')).toEqual(filteredHistories);
    expect(wrapper.state('displayedHistories')).toEqual(filteredHistories);

    wrapper
      .find(Select)
      .at(1)
      .simulate('change', []);
    expect(wrapper.find(History).length).toEqual(histories.length);
    expect(wrapper.state('filteredHistories')).toEqual(histories);
    expect(wrapper.state('displayedHistories')).toEqual(histories);
  });

  it('Changing comment text properly updates state and value', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('comment')).toEqual('');
    expect(wrapper.find('#comment').prop('value')).toEqual('');
    wrapper.find('#comment').simulate('change', { target: { id: 'comment', value: 'adding comment' } });
    expect(wrapper.state('comment')).toEqual('adding comment');
    expect(wrapper.find('#comment').prop('value')).toEqual('adding comment');
    wrapper.find('#comment').simulate('change', { target: { id: 'comment', value: 'updating comment text' } });
    expect(wrapper.state('comment')).toEqual('updating comment text');
    expect(wrapper.find('#comment').prop('value')).toEqual('updating comment text');
  });

  it('Disables "Add Comment" button when text input is empty', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
    wrapper.find('#comment').simulate('change', { target: { id: 'comment', value: 'adding comment' } });
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    wrapper.find('#comment').simulate('change', { target: { id: 'comment', value: '' } });
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
  });

  it('Clicking the "Add Comment" button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#comment').simulate('change', { target: { id: 'comment', value: 'adding a comment' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(submitSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking the "Add Comment" button disables the button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find('#comment').simulate('change', { target: { id: 'comment', value: 'adding a comment' } });
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
  });
});
