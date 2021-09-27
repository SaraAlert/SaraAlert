import React from 'react';
import { shallow } from 'enzyme';
import WorkflowTable from '../../../components/analytics/display/WorkflowTable';
import InfoTooltip from '../../../components/util/InfoTooltip';

const tableTitle = 'some chart title';
const tableRows = ['row1', 'row2', 'row3', 'row4', 'row5'];
const tableColumns = ['', 'Exposure', 'Isolation', 'Total'];
const tableData = [
  [4, 7, 11],
  [8, 2, 10],
  [13, 5, 18],
  [6, 1, 7],
  [0, 16, 16],
];

describe('WorkflowTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<WorkflowTable title={tableTitle} rowHeaders={tableRows} data={tableData} />);
    expect(wrapper.find('.analytics-table-header').exists()).toBe(true);
    expect(wrapper.find('.analytics-table-header').text()).toEqual(tableTitle);
    expect(wrapper.find(InfoTooltip).exists()).toBe(false);
    expect(wrapper.find('table').exists()).toBe(true);
  });

  it('Properly renders workflow table', () => {
    const wrapper = shallow(<WorkflowTable title={tableTitle} rowHeaders={tableRows} data={tableData} />);
    expect(wrapper.find('table').exists()).toBe(true);
    expect(wrapper.find('thead').exists()).toBe(true);
    expect(wrapper.find('thead').find('.header').exists()).toBe(true);
    tableColumns.forEach((col, c_index) => {
      expect(wrapper.find('thead').find('th').at(c_index).text()).toEqual(col);
    });
    expect(wrapper.find('tbody').exists()).toBe(true);
    expect(wrapper.find('tbody').find('tr').length).toEqual(tableData.length);
    tableData.forEach((rowData, r_index) => {
      expect(wrapper.find('tbody').find('tr').at(r_index).find('td').at(0).text()).toEqual(tableRows[parseInt(r_index)]);
      expect(wrapper.find('tbody').find('tr').at(r_index).find('td').at(0).hasClass('total-column')).toBe(false);
      rowData.forEach((cellData, c_index) => {
        expect(
          wrapper
            .find('tbody')
            .find('tr')
            .at(r_index)
            .find('td')
            .at(c_index + 1)
            .text()
        ).toEqual(String(cellData));
        expect(
          wrapper
            .find('tbody')
            .find('tr')
            .at(r_index)
            .find('td')
            .at(c_index + 1)
            .hasClass('total-column')
        ).toEqual(c_index === rowData.length - 1);
      });
    });
  });

  it('Renders info tooltip in header if props.tooltipKey is defined', () => {
    const wrapper = shallow(<WorkflowTable title={tableTitle} tooltipKey={'analyticsAgeTip'} rowHeaders={tableRows} data={tableData} />);
    expect(wrapper.find('.analytics-table-header').find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find('.analytics-table-header').find(InfoTooltip).prop('tooltipTextKey')).toEqual('analyticsAgeTip');
  });
});
