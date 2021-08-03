import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import PreferredReportingMethod from '../../../../components/analytics/public_health/charts/PreferredReportingMethod';
import mockAnalyticsData from '../../../mocks/mockAnalytics';

const columnHeaders = ['Email', 'SMS Weblink', 'SMS Text', 'Phone Call', 'Opt-Out', 'Unknown', 'Missing', 'Total'];
const exposureRowHeaders = ['Symptomatic', 'Non-Reporting', 'Asymptomatic', 'PUI', 'Total'];
const exposureValues = [
  [
    { number: '8', percent: '19.5%' },
    { number: '10', percent: '37.0%' },
    { number: '7', percent: '20.0%' },
    { number: '5', percent: '14.7%' },
    { number: '7', percent: '20.0%' },
    { number: '14', percent: '38.9%' },
    { number: '0', percent: 'None' },
    { number: '51', percent: '24.5%' },
  ],
  [
    { number: '9', percent: '22.0%' },
    { number: '4', percent: '14.8%' },
    { number: '6', percent: '17.1%' },
    { number: '3', percent: '8.8%' },
    { number: '4', percent: '11.4%' },
    { number: '5', percent: '13.9%' },
    { number: '0', percent: 'None' },
    { number: '31', percent: '14.9%' },
  ],
  [
    { number: '20', percent: '48.8%' },
    { number: '10', percent: '37.0%' },
    { number: '17', percent: '48.6%' },
    { number: '23', percent: '67.6%' },
    { number: '19', percent: '54.3%' },
    { number: '15', percent: '41.7%' },
    { number: '0', percent: 'None' },
    { number: '104', percent: '50.0%' },
  ],
  [
    { number: '4', percent: '9.8%' },
    { number: '3', percent: '11.1%' },
    { number: '5', percent: '14.3%' },
    { number: '3', percent: '8.8%' },
    { number: '5', percent: '14.3%' },
    { number: '2', percent: '5.6%' },
    { number: '0', percent: 'None' },
    { number: '22', percent: '10.6%' },
  ],
  [{ number: '41' }, { number: '27' }, { number: '35' }, { number: '34' }, { number: '35' }, { number: '36' }, { number: '0' }, { number: '208' }],
];
const isolationRowHeaders = ['Records Requiring Review', 'Non-Reporting', 'Reporting', 'Total'];
const isolationValues = [
  [
    { number: '5', percent: '22.7%' },
    { number: '3', percent: '8.8%' },
    { number: '2', percent: '6.9%' },
    { number: '6', percent: '15.4%' },
    { number: '2', percent: '5.9%' },
    { number: '6', percent: '20.0%' },
    { number: '0', percent: 'None' },
    { number: '24', percent: '12.8%' },
  ],
  [
    { number: '5', percent: '22.7%' },
    { number: '4', percent: '11.8%' },
    { number: '4', percent: '13.8%' },
    { number: '6', percent: '15.4%' },
    { number: '9', percent: '26.5%' },
    { number: '3', percent: '10.0%' },
    { number: '0', percent: 'None' },
    { number: '31', percent: '16.5%' },
  ],
  [
    { number: '12', percent: '54.5%' },
    { number: '27', percent: '79.4%' },
    { number: '23', percent: '79.3%' },
    { number: '27', percent: '69.2%' },
    { number: '23', percent: '67.6%' },
    { number: '21', percent: '70.0%' },
    { number: '0', percent: 'None' },
    { number: '133', percent: '70.7%' },
  ],
  [{ number: '22' }, { number: '34' }, { number: '29' }, { number: '39' }, { number: '34' }, { number: '30' }, { number: '0' }, { number: '188' }],
];

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
];

function getWrapper() {
  return shallow(<PreferredReportingMethod stats={mockAnalyticsData} available_workflows={available_workflows} />);
}

describe('PreferredReportingMethod', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Monitorees by Reporting Method (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find('table')
        .exists()
    ).toBeTruthy();
  });

  it('Properly renders reporting method table', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('thead').exists()).toBeTruthy();
    expect(wrapper.find('thead').find('th').length).toEqual(columnHeaders.length + 2);
    columnHeaders.forEach((col, c_index) => {
      expect(
        wrapper
          .find('thead')
          .find('th')
          .at(c_index + 2)
          .text()
      ).toEqual(col);
    });
    expect(wrapper.find('tbody').exists()).toBeTruthy();
    expect(wrapper.find('tbody').find('tr').length).toEqual(exposureRowHeaders.length + isolationRowHeaders.length + 2);
    expect(
      wrapper
        .find('tbody')
        .find('tr')
        .at(0)
        .find('td')
        .at(0)
        .text()
    ).toEqual('Exposure Workflow');
    exposureRowHeaders.forEach((row, r_index) => {
      const rowWrapper = wrapper
        .find('tbody')
        .find('tr')
        .at(r_index + 1);
      expect(
        rowWrapper
          .find('td')
          .at(1)
          .text()
      ).toEqual(row);
      exposureValues[parseInt(r_index)].forEach((cell, c_index) => {
        expect(
          rowWrapper
            .find('td')
            .at(c_index + 2)
            .find('.number')
            .text()
        ).toEqual(cell.number);
        expect(
          rowWrapper
            .find('td')
            .at(c_index + 2)
            .find('.percentage')
            .text()
        ).toEqual(row !== 'Total' ? `(${cell.percent})` : '');
      });
    });
    expect(
      wrapper
        .find('tbody')
        .find('tr')
        .at(exposureRowHeaders.length + 1)
        .find('td')
        .at(0)
        .text()
    ).toEqual('Isolation Workflow');
    isolationRowHeaders.forEach((row, r_index) => {
      const rowWrapper = wrapper
        .find('tbody')
        .find('tr')
        .at(exposureRowHeaders.length + 2 + r_index);
      expect(
        rowWrapper
          .find('td')
          .at(1)
          .text()
      ).toEqual(row);
      isolationValues[parseInt(r_index)].forEach((cell, c_index) => {
        expect(
          rowWrapper
            .find('td')
            .at(c_index + 2)
            .find('.number')
            .text()
        ).toEqual(cell.number);
        expect(
          rowWrapper
            .find('td')
            .at(c_index + 2)
            .find('.percentage')
            .text()
        ).toEqual(row !== 'Total' ? `(${cell.percent})` : '');
      });
    });
  });
});
