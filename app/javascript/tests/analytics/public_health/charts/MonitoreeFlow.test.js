import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import MonitoreeFlow from '../../../../components/analytics/public_health/charts/MonitoreeFlow';
import mockAnalytics from '../../../mocks/mockAnalytics';

const monitoreeFlowTableHeaders = ['Yesterday', 'Last 7d', 'Last 14d', 'Cumulative'];
const exposureNewEnrollmentValues = [
  { number: '54', percent: '88.5%' },
  { number: '164', percent: '88.6%' },
  { number: '192', percent: '89.7%' },
  { number: '223', percent: '89.9%' },
];
const exposureTransferredInValues = [
  { number: '7', percent: '11.5%' },
  { number: '21', percent: '11.4%' },
  { number: '22', percent: '10.3%' },
  { number: '25', percent: '10.1%' },
];
const exposureClosedValues = [
  { number: '4', percent: '33.3%' },
  { number: '11', percent: '37.9%' },
  { number: '12', percent: '37.5%' },
  { number: '15', percent: '35.7%' },
];
const exposureTransferredOutValues = [
  { number: '8', percent: '66.7%' },
  { number: '18', percent: '62.1%' },
  { number: '20', percent: '62.5%' },
  { number: '27', percent: '64.3%' },
];
const isolationNewEnrollmentValues = [
  { number: '39', percent: '90.7%' },
  { number: '100', percent: '85.5%' },
  { number: '171', percent: '90.0%' },
  { number: '195', percent: '89.9%' },
];
const isolationTransferredInValues = [
  { number: '4', percent: '9.3%' },
  { number: '17', percent: '14.5%' },
  { number: '19', percent: '10.0%' },
  { number: '22', percent: '10.1%' },
];
const isolationClosedValues = [
  { number: '2', percent: '28.6%' },
  { number: '4', percent: '18.2%' },
  { number: '6', percent: '21.4%' },
  { number: '7', percent: '21.9%' },
];
const isolationTransferredOutValues = [
  { number: '5', percent: '71.4%' },
  { number: '18', percent: '81.8%' },
  { number: '22', percent: '78.6%' },
  { number: '25', percent: '78.1%' },
];
const exposureToCaseActiveValues = [
  { number: '3', percent: '37.5%' },
  { number: '8', percent: '36.4%' },
  { number: '14', percent: '35.0%' },
  { number: '22', percent: '34.4%' },
];
const exposureToCaseNonActiveValues = [
  { number: '5', percent: '62.5%' },
  { number: '13', percent: '59.1%' },
  { number: '21', percent: '52.5%' },
  { number: '34', percent: '53.1%' },
];
const casesClosedInExposureValues = [
  { number: '0', percent: 'None' },
  { number: '1', percent: '4.5%' },
  { number: '5', percent: '12.5%' },
  { number: '8', percent: '12.5%' },
];
const exposureToCaseTotalValues = [{ number: '8' }, { number: '22' }, { number: '40' }, { number: '64' }];
const isolationToExposureTotalValues = [{ number: '1' }, { number: '7' }, { number: '12' }, { number: '23' }];

function getWrapper() {
  return shallow(<MonitoreeFlow stats={mockAnalytics} />);
}

describe('MonitoreeFlow', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Monitoree Flow Over Time (All Records)');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('.analytics-table-header').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('.analytics-table-header').length).toEqual(2);
    expect(wrapper.find(Card.Body).find('table').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('table').length).toEqual(2);
    expect(wrapper.find(Card.Body).find('.info-text').exists()).toBe(true);
    expect(wrapper.find(Card.Body).find('.info-text').find('i').hasClass('fa-info-circle')).toBe(true);
    expect(wrapper.find(Card.Body).find('.info-text').at(0).text()).toContain('Cumulative includes incoming and outgoing counts recorded for this jurisdiction (excluding today’s counts)');
    expect(wrapper.find(Card.Body).find('.info-text').at(1).text()).toContain('Cumulative includes counts of the monitorees that met the criteria listed in the tables after 10/5/2021 (excluding today’s counts)');
  });

  it('Properly renders "Exposure" monitoree flow table', () => {
    const wrapper = getWrapper();
    const tableBody = wrapper.find('tbody').at(0);
    expect(wrapper.find('.analytics-table-header').at(0).text()).toEqual('Exposure Workflow');
    monitoreeFlowTableHeaders.forEach((header, index) => {
      expect(
        wrapper
          .find('th')
          .at(index + 1)
          .text()
      ).toContain(header);
    });
    expect(tableBody.find('tr').at(0).text()).toEqual('Incoming');
    expect(tableBody.find('tr').at(1).find('td').first().text()).toEqual('New Enrollments');
    exposureNewEnrollmentValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(1)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(1)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(2).find('td').first().text()).toEqual('Transferred In');
    exposureTransferredInValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(3).text()).toEqual('Outgoing');
    expect(tableBody.find('tr').at(4).find('td').first().text()).toEqual('Closed');
    exposureClosedValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(4)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(4)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(5).find('td').first().text()).toEqual('Transferred Out');
    exposureTransferredOutValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(5)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(5)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
  });

  it('Properly renders "Isolation" monitoree flow table', () => {
    const wrapper = getWrapper();
    const tableBody = wrapper.find('tbody').at(1);
    expect(wrapper.find('.analytics-table-header').at(1).text()).toEqual('Isolation Workflow');
    monitoreeFlowTableHeaders.forEach((header, index) => {
      expect(
        wrapper
          .find('th')
          .at(index + 1)
          .text()
      ).toContain(header);
    });
    expect(tableBody.find('tr').at(0).text()).toEqual('Incoming');
    expect(tableBody.find('tr').at(1).find('td').first().text()).toEqual('New Enrollments');
    isolationNewEnrollmentValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(1)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(1)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(2).find('td').first().text()).toEqual('Transferred In');
    isolationTransferredInValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(3).text()).toEqual('Outgoing');
    expect(tableBody.find('tr').at(4).find('td').first().text()).toEqual('Closed');
    isolationClosedValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(4)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(4)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(5).find('td').first().text()).toEqual('Transferred Out');
    isolationTransferredOutValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(5)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(5)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
  });

  it('Properly renders "Exposure to Case Development" monitoree flow table', () => {
    const wrapper = getWrapper();
    const tableBody = wrapper.find('tbody').at(2);
    expect(wrapper.find('.analytics-table-header').at(2).text()).toEqual('Exposure to Case Development');
    monitoreeFlowTableHeaders.forEach((header, index) => {
      expect(
        wrapper
          .find('th')
          .at(index + 1)
          .text()
      ).toContain(header);
    });
    expect(tableBody.find('tr').at(0).text()).toEqual('Moved from Exposure to Isolation Workflow');
    expect(tableBody.find('tr').at(1).find('td').at(0).text()).toEqual('Currently Active');
    exposureToCaseActiveValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(1)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(1)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(2).find('td').at(0).text()).toEqual('Closed or Purged');
    exposureToCaseNonActiveValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(2)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(3).find('td').at(0).text()).toEqual('Cases that were closed in Exposure Workflow');
    casesClosedInExposureValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(3)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(3)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual(`(${value.percent})`);
    });
    expect(tableBody.find('tr').at(4).find('td').at(0).text()).toEqual('Total Contacts that became Cases');
    exposureToCaseTotalValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(4)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(4)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual('');
    });
  });

  it('Properly renders "Moved from Isolation to Exposure" monitoree flow table', () => {
    const wrapper = getWrapper();
    const tableBody = wrapper.find('tbody').at(3);
    expect(wrapper.find('.analytics-table-header').at(3).text()).toEqual('Moved from Isolation to Exposure');
    monitoreeFlowTableHeaders.forEach((header, index) => {
      expect(
        wrapper
          .find('th')
          .at(index + 1)
          .text()
      ).toContain(header);
    });
    expect(tableBody.find('tr').at(0).find('td').at(0).text()).toEqual('Moved from Isolation to Exposure Workflow');
    isolationToExposureTotalValues.forEach((value, index) => {
      expect(
        tableBody
          .find('tr')
          .at(0)
          .find('td')
          .at(index + 1)
          .find('.number')
          .text()
      ).toEqual(value.number);
      expect(
        tableBody
          .find('tr')
          .at(0)
          .find('td')
          .at(index + 1)
          .find('.percentage')
          .text()
      ).toEqual('');
    });
  });
});
