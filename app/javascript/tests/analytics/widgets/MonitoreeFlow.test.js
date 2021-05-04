import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import MonitoreeFlow from '../../../components/analytics/widgets/MonitoreeFlow';
import mockAnalytics from '../../mocks/mockAnalytics';

const monitoreeFlowTableHeaders = [' Last 24 Hours  n (col %) ', ' Last 7 Days  n (col %) ', ' Last 14 Days  n (col %) ', ' Total  n (col %) '];
const exposureNewEnrollmentValues = [ '54 (88.5%)', '164 (85.9%)', '192 (83.5%)', '223 (68.8%)' ];
const exposureTransferredInValues = [ '7 (11.5%)', '21 (11.0%)', '22 (9.6%)', '25 (7.7%)' ];
const exposureFromIsolationValues = [ '0 (None)', '6 (3.1%)', '16 (7.0%)', '76 (23.5%)' ];
const exposureClosedValues = [ '4 (28.6%)', '11 (22.0%)', '12 (13.6%)', '15 (8.3%)' ];
const exposureTransferredOutValues = [ '8 (57.1%)', '18 (36.0%)', '20 (22.7%)', '27 (15.0%)' ];
const exposureToIsolationValues = [ '2 (14.3%)', '21 (42.0%)', '56 (63.6%)', '138 (76.7%)' ];
const isolationNewEnrollmentValues = [ '39 (86.7%)', '100 (72.5%)', '171 (69.5%)', '195 (54.9%)' ];
const isolationTransferredInValues = [ '4 (8.9%)', '17 (12.3%)', '19 (7.7%)', '22 (6.2%)' ];
const isolationFromExposureValues = [ '2 (4.4%)', '21 (15.2%)', '56 (22.8%)', '138 (38.9%)' ];
const isolationClosedValues = [ '2 (28.6%)', '4 (14.3%)', '6 (13.6%)', '7 (6.5%)' ];
const isolationTransferredOutValues = [ '5 (71.4%)', '18 (64.3%)', '22 (50.0%)', '25 (23.1%)' ];
const isolationToExposureValues = [ '0 (None)', '6 (21.4%)', '16 (36.4%)', '76 (70.4%)' ];

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
    expect(tableBody.find('tr').at(4).find('td').first().text()).toEqual('FROM ISOLATION WORKFLOW');
    exposureFromIsolationValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(4).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(5).text()).toEqual('OUTGOING');
    expect(tableBody.find('tr').at(6).find('td').first().text()).toEqual('CLOSED');
    exposureClosedValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(6).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(7).find('td').first().text()).toEqual('TRANSFERRED OUT');
    exposureTransferredOutValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(7).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(8).find('td').first().text()).toEqual('TO ISOLATION WORKFLOW');
    exposureToIsolationValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(8).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(9).text()).toEqual('ISOLATION WORKFLOW');
    expect(tableBody.find('tr').at(10).text()).toEqual('INCOMING');
    expect(tableBody.find('tr').at(11).find('td').first().text()).toEqual('NEW ENROLLMENTS');
    isolationNewEnrollmentValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(11).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(12).find('td').first().text()).toEqual('TRANSFERRED IN');
    isolationTransferredInValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(12).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(13).find('td').first().text()).toEqual('FROM EXPOSURE WORKFLOW');
    isolationFromExposureValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(13).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(14).text()).toEqual('OUTGOING');
    expect(tableBody.find('tr').at(15).find('td').first().text()).toEqual('CLOSED');
    isolationClosedValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(15).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(16).find('td').first().text()).toEqual('TRANSFERRED OUT');
    isolationTransferredOutValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(16).find('td').at(index+1).text()).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(17).find('td').first().text()).toEqual('TO EXPOSURE WORKFLOW');
    isolationToExposureValues.forEach(function(value, index) {
      expect(tableBody.find('tr').at(17).find('td').at(index+1).text()).toEqual(String(value));
    });
  });
});