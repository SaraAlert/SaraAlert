import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import MonitoreeFlow from '../../../components/analytics/public_health/charts/MonitoreeFlow';
import mockAnalytics from '../../../mocks/mockAnalytics';

const monitoreeFlowTableHeaders = ['Last 24 Hours  n (col %)', 'Last 7 Days  n (col %)', 'Last 14 Days  n (col %)', 'Total  n (col %)'];
const exposureNewEnrollmentValues = ['54 (88.5%)', '164 (88.6%)', '192 (89.7%)', '223 (89.9%)'];
const exposureTransferredInValues = ['7 (11.5%)', '21 (11.4%)', '22 (10.3%)', '25 (10.1%)'];
const exposureClosedValues = ['4 (33.3%)', '11 (37.9%)', '12 (37.5%)', '15 (35.7%)'];
const exposureTransferredOutValues = ['8 (66.7%)', '18 (62.1%)', '20 (62.5%)', '27 (64.3%)'];
const isolationNewEnrollmentValues = ['39 (90.7%)', '100 (85.5%)', '171 (90.0%)', '195 (89.9%)'];
const isolationTransferredInValues = ['4 (9.3%)', '17 (14.5%)', '19 (10.0%)', '22 (10.1%)'];
const isolationClosedValues = ['2 (28.6%)', '4 (18.2%)', '6 (21.4%)', '7 (21.9%)'];
const isolationTransferredOutValues = ['5 (71.4%)', '18 (81.8%)', '22 (78.6%)', '25 (78.1%)'];

function getWrapper() {
  return shallow(<MonitoreeFlow stats={mockAnalytics} />);
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
    monitoreeFlowTableHeaders.forEach((header, index) => {
      expect(
        wrapper
          .find('th')
          .at(index + 1)
          .text()
      ).toContain(header);
    });
    expect(tableBody.find('tr').at(0).text()).toEqual('EXPOSURE WORKFLOW');
    expect(tableBody.find('tr').at(1).text()).toEqual('INCOMING');
    expect(tableBody.find('tr').at(2).find('td').first().text()).toEqual('NEW ENROLLMENTS');
    exposureNewEnrollmentValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(3).find('td').first().text()).toEqual('TRANSFERRED IN');
    exposureTransferredInValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(3)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(4).text()).toEqual('OUTGOING');
    expect(tableBody.find('tr').at(5).find('td').first().text()).toEqual('CLOSED');
    exposureClosedValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(5)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(6).find('td').first().text()).toEqual('TRANSFERRED OUT');
    exposureTransferredOutValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(6)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(7).text()).toEqual('ISOLATION WORKFLOW');
    expect(tableBody.find('tr').at(8).text()).toEqual('INCOMING');
    expect(tableBody.find('tr').at(9).find('td').first().text()).toEqual('NEW ENROLLMENTS');
    isolationNewEnrollmentValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(9)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(10).find('td').first().text()).toEqual('TRANSFERRED IN');
    isolationTransferredInValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(10)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(11).text()).toEqual('OUTGOING');
    expect(tableBody.find('tr').at(12).find('td').first().text()).toEqual('CLOSED');
    isolationClosedValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(12)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
    expect(tableBody.find('tr').at(13).find('td').first().text()).toEqual('TRANSFERRED OUT');
    isolationTransferredOutValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(13)
          .find('td')
          .at(index + 1)
          .text()
      ).toEqual(String(value));
    });
  });
});
