import React from 'react'
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import MonitoreeFlow from '../../../components/analytics/widgets/MonitoreeFlow.js'
import mockAnalytics from '../../mocks/mockAnalytics'

const monitoreeFlowTableHeaders = ['Last 24 Hours', 'Last 7 Days', 'Last 14 Days', 'Total'];
const exposureNewEnrollmentValues = [ 54, 164, 192, 223 ];
const exposureTransferredInValues = [ 7, 21, 22, 25 ];
const exposureClosedValues = [ 4, 11, 12, 15 ];
const exposureTransferredOutValues = [ 8, 18, 20, 27 ];
const isolationNewEnrollmentValues = [ 39, 100, 171, 195 ];
const isolationTransferredInValues = [ 4, 17, 19, 22 ];
const isolationClosedValues = [ 2, 4, 6, 7 ];
const isolationTransferredOutValues = [ 5, 18, 22, 25 ];

function getWrapper() {
  return shallow(<MonitoreeFlow stats={mockAnalytics}/>);
}

describe('MonitoreeFlow', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find('.analytics-card-header').text()).toEqual('Monitoree Flow Over Time (All Records)');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find('table').exists()).toBeTruthy();
    expect(wrapper.find('.fake-demographic-text').exists()).toBeTruthy();
    expect(wrapper.find('.fake-demographic-text').find('i').hasClass('fa-info-circle')).toBeTruthy();
    expect(wrapper.find('.fake-demographic-text').text().includes('Total includes all incoming and outgoing counts ever recorded for this jurisdiction')).toBeTruthy();
  });

  it('Properly renders monitoree flow table', () => {
    const wrapper = getWrapper();
    const tableBody = wrapper.find('tbody');
    monitoreeFlowTableHeaders.forEach(function(header, index) {
      expect(wrapper.find('th').at(index+1).text()).toEqual(header);
    });
    expect(tableBody.find('tr').at(0).text()).toEqual('EXPOSURE WORKFLOW');
    expect(tableBody.find('tr').at(1).text()).toEqual('INCOMING');
    expect(tableBody.find('tr').at(2).find('td').first().text()).toEqual('NEW ENROLLMENTS');
    exposureNewEnrollmentValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(2).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(3).find('td').first().text()).toEqual('TRANSFERRED IN');
    exposureTransferredInValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(3).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(4).text()).toEqual('OUTGOING');
    expect(tableBody.find('tr').at(5).find('td').first().text()).toEqual('CLOSED');
    exposureClosedValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(5).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(6).find('td').first().text()).toEqual('TRANSFERRED OUT');
    exposureTransferredOutValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(6).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(7).text()).toEqual('ISOLATION WORKFLOW');
    expect(tableBody.find('tr').at(8).text()).toEqual('INCOMING');
    expect(tableBody.find('tr').at(9).find('td').first().text()).toEqual('NEW ENROLLMENTS');
    isolationNewEnrollmentValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(9).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(10).find('td').first().text()).toEqual('TRANSFERRED IN');
    isolationTransferredInValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(10).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(11).text()).toEqual('OUTGOING');
    expect(tableBody.find('tr').at(12).find('td').first().text()).toEqual('CLOSED');
    isolationClosedValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(12).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(13).find('td').first().text()).toEqual('TRANSFERRED OUT');
    isolationTransferredOutValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(13).find('td').at(index+1).text()).toEqual(String(value));
    });
  });
});