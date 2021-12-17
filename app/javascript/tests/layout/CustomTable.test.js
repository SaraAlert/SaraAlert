import React from 'react';
import { shallow, mount } from 'enzyme';
import _ from 'lodash';
import { Button, Form, InputGroup, Spinner, Table } from 'react-bootstrap';
import ReactPaginate from 'react-paginate';
import ReactTooltip from 'react-tooltip';
import CustomTable from '../../components/layout/CustomTable';
import InfoTooltip from '../../components/util/InfoTooltip';

const handleEditMock = jest.fn();
const handleTableUpdateMock = jest.fn();
const handleSelectMock = jest.fn();
const handlePageUpdateMock = jest.fn();
const handleEntriesChangeMock = jest.fn();
const entryOptions = [1, 2, 3, 4, 5];
const rowData = [
  { col1: 'row 1 col 1', col2: 'row 1 col 2', col3: 'row 1 col 3', col4: true, col5: 'row 1 col 5' },
  { col1: 'row 2 col 1', col2: 'row 2 col 2', col3: 'row 2 col 3', col4: true, col5: 'row 2 col 5' },
  { col1: 'row 3 col 1', col2: 'row 3 col 2', col3: 'row 3 col 3', col4: true, col5: 'row 3 col 5' },
  { col1: 'row 4 col 1', col2: 'row 4 col 2', col3: 'row 4 col 3', col4: false, col5: 'row 4 col 5' },
  { col1: 'row 5 col 1', col2: 'row 5 col 2', col3: 'row 5 col 3', col4: true, col5: 'row 5 col 5' },
];
const columnData = [
  { field: 'col1', label: 'Column 1', isSortable: true, tooltip: null },
  { field: 'col2', label: 'Column 2', isSortable: false, tooltip: null },
  { field: 'col3', label: 'Column 3', isSortable: true, tooltip: 'tooltip key' },
  { field: 'col4', label: 'Column 4', isSortable: true, tooltip: null, options: { true: 'I am true', false: 'I am false' } },
  { field: 'col5', label: 'Column 5', isSortable: true, tooltip: null, filter: formatCell },
];

function formatCell(data) {
  return <b>{data.value}</b>;
}

function getRowCheckboxAriaLabel(data) {
  return data.col1;
}

/**
 * If additionalProps undefiend, the CustomTable component is rendered with the default props included below
 * If any props are defined in additional props, they overwrite whatever the default value was set as
 */
function getWrapper(additionalProps) {
  return shallow(
    <CustomTable
      title="test"
      dataType="test"
      rowData={rowData}
      totalRows={rowData.length}
      columnData={columnData}
      isEditable={false}
      isSelectable={false}
      selectedRows={[]}
      selectAll={false}
      disabledRows={[]}
      disabledTooltipText={'disabled tooltip'}
      handleEdit={handleEditMock}
      handleTableUpdate={handleTableUpdateMock}
      handleSelect={handleSelectMock}
      handlePageUpdate={handlePageUpdateMock}
      handleEntriesChange={handleEntriesChangeMock}
      getRowCheckboxAriaLabel={getRowCheckboxAriaLabel}
      page={0}
      entries={5}
      entryOptions={entryOptions}
      showPagination={true}
      isLoading={false}
      {...additionalProps}
    />
  );
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('CustomTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Spinner).exists()).toBe(false);
    expect(wrapper.find(Table).exists()).toBe(true);
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(ReactPaginate).exists()).toBe(true);
  });

  it('Properly renders table', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('thead').exists()).toBe(true);
    expect(wrapper.find('thead').find('th').length).toEqual(columnData.length);
    columnData.forEach((colData, colIndex) => {
      expect(wrapper.find('thead').find('th').at(colIndex).find('span').text()).toEqual(colData.label);
      expect(wrapper.find('thead').find('th').at(colIndex).find('.sort-header').exists()).toBe(colData.isSortable);
      expect(wrapper.find('thead').find('th').at(colIndex).find(InfoTooltip).exists()).toBe(!_.isNil(colData.tooltip));
      if (colData.tooltip) {
        expect(wrapper.find('thead').find('th').at(colIndex).find(InfoTooltip).prop('tooltipTextKey')).toEqual(colData.tooltip);
      }
    });
    expect(wrapper.find('tbody').exists()).toBe(true);
    expect(wrapper.find('tbody').find('tr').length).toEqual(rowData.length);
    rowData.forEach((rowData, rowIndex) => {
      const row = wrapper.find('tbody').find('tr').at(rowIndex);
      expect(row.find('td').length).toEqual(columnData.length);
      columnData.forEach((colData, colIndex) => {
        if (!_.isNil(colData.filter)) {
          expect(row.find('td').at(colIndex).children().html()).toEqual(`<b>${rowData[colData.field]}</b>`);
        } else if (!_.isNil(colData.options)) {
          expect(row.find('td').at(colIndex).text()).toEqual(colData.options[rowData[colData.field]]);
        } else {
          expect(row.find('td').at(colIndex).text()).toEqual(rowData[colData.field]);
        }
      });
    });
  });

  it('Properly renders pagination', () => {
    const numEntries = 2;
    const numPage = 1;
    const wrapper = getWrapper({ rowData: rowData.slice(0, numEntries), entries: numEntries, page: numPage });
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(InputGroup).find(InputGroup.Prepend).exists()).toBe(true);
    expect(wrapper.find(InputGroup).find(InputGroup.Prepend).find('i').exists()).toBe(true);
    expect(wrapper.find(InputGroup).find(InputGroup.Prepend).find('i').hasClass('fa-list')).toBe(true);
    expect(wrapper.find(InputGroup).find(InputGroup.Prepend).find(InputGroup.Text).text()).toEqual('Show');
    expect(wrapper.find(InputGroup).find(Form.Control).exists()).toBe(true);
    expect(wrapper.find(InputGroup).find(Form.Control).prop('value')).toEqual(numEntries);
    expect(wrapper.find(InputGroup).find(InputGroup.Append).exists()).toBe(true);
    expect(wrapper.find(InputGroup).find(InputGroup.Append).find(InputGroup.Text).text()).toEqual(`Displaying ${numEntries} out of ${rowData.length} rows.`);
    expect(wrapper.find(ReactPaginate).exists()).toBe(true);
    expect(wrapper.find(ReactPaginate).prop('pageCount')).toEqual(Math.ceil(rowData.length / numEntries));
    expect(wrapper.find(ReactPaginate).prop('initialPage')).toEqual(numPage);
    expect(wrapper.find(ReactPaginate).prop('forcePage')).toEqual(numPage);
  });

  it('Properly renders table and hides pagination if there is no table data', () => {
    const wrapper = getWrapper({ rowData: [], totalRows: 0 });
    expect(wrapper.find('thead').exists()).toBe(true);
    expect(wrapper.find('thead').find('th').length).toEqual(columnData.length);
    columnData.forEach((colData, colIndex) => {
      expect(wrapper.find('thead').find('th').at(colIndex).find('span').text()).toEqual(colData.label);
      expect(wrapper.find('thead').find('th').at(colIndex).find('.sort-header').exists()).toBe(colData.isSortable);
    });
    expect(wrapper.find('tbody').exists()).toBe(true);
    expect(wrapper.find('tbody').find('tr').length).toEqual(1);
    expect(wrapper.find('tbody').find('tr').text()).toEqual('No data available in table.');
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(InputGroup.Append).text()).toEqual('Displaying 0 out of 0 rows.');
    expect(wrapper.find(ReactPaginate).exists()).toBe(false);
  });

  it('Properly renders loading spinner when props.isLoading is true', () => {
    const wrapper = getWrapper({ isLoading: true });
    expect(wrapper.find(Spinner).exists()).toBe(true);
    expect(wrapper.find(Table).exists()).toBe(true);
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(ReactPaginate).exists()).toBe(true);
  });

  it('Properly renders column sort', () => {
    const orderBy = 'col1';
    const sortDirection = 'desc';
    const wrapper = getWrapper({ orderBy, sortDirection });
    expect(wrapper.state('tableQuery').orderBy).toEqual(orderBy);
    expect(wrapper.state('tableQuery').sortDirection).toEqual(sortDirection);
    columnData.forEach(colData => {
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-up').exists()).toBe(false);
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-down').exists()).toBe(colData.field === orderBy);
    });
  });

  it('Clicking table headers properly renders sort icon', () => {
    const wrapper = getWrapper();
    _.shuffle(columnData).forEach(colData => {
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-up').exists()).toBe(false);
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-down').exists()).toBe(false);
      wrapper.find(Table).find('thead').find(`#${colData.field}`).simulate('click');
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-up').exists()).toBe(colData.isSortable);
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-down').exists()).toBe(false);
      wrapper.find(Table).find('thead').find(`#${colData.field}`).simulate('click');
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-up').exists()).toBe(false);
      expect(wrapper.find(Table).find('thead').find(`#${colData.field}`).find('i.fa-sort-down').exists()).toBe(colData.isSortable);
    });
  });

  it('Clicking table headers calls props.handleTableUpdate and updates state', () => {
    let callCount = 0;
    const wrapper = getWrapper();
    expect(wrapper.state('tableQuery').orderBy).toBeNull();
    expect(wrapper.state('tableQuery').sortDirection).toBeNull();
    expect(handleTableUpdateMock).toHaveBeenCalledTimes(callCount);

    // Sort Ascending
    _.shuffle(columnData).forEach(colData => {
      if (colData.isSortable) {
        wrapper.find(Table).find('thead').find(`#${colData.field}`).simulate('click');
        callCount++;
        expect(wrapper.state('tableQuery').orderBy).toEqual(colData.field);
        expect(wrapper.state('tableQuery').sortDirection).toEqual('asc');
        expect(handleTableUpdateMock).toHaveBeenCalledTimes(callCount);
      } else {
        expect(handleTableUpdateMock).toHaveBeenCalledTimes(callCount);
      }
    });

    // Sort Descending
    wrapper.setProps({ orderBy: null, sortDirection: null });
    _.shuffle(columnData).forEach(colData => {
      if (colData.isSortable) {
        _.times(2, () => {
          wrapper.find(Table).find('thead').find(`#${colData.field}`).simulate('click');
          callCount++;
        });
        expect(wrapper.state('tableQuery').orderBy).toEqual(colData.field);
        expect(wrapper.state('tableQuery').sortDirection).toEqual('desc');
        expect(handleTableUpdateMock).toHaveBeenCalledTimes(callCount);
      } else {
        expect(handleTableUpdateMock).toHaveBeenCalledTimes(callCount);
      }
    });
  });

  it('Properly renders edit column if props.isEditable', () => {
    const wrapper = getWrapper({ isEditable: true });
    expect(wrapper.find('thead').find('th').length).toEqual(columnData.length + 1);
    expect(wrapper.find('thead').find('th').last().text()).toEqual('Edit');
    wrapper
      .find('tbody')
      .find('tr')
      .forEach(row => {
        expect(row.find('td').length).toEqual(columnData.length + 1);
        expect(row.find('td').last().find(Button).exists()).toBe(true);
        expect(row.find('td').last().find(Button).find('i').exists()).toBe(true);
        expect(row.find('td').last().find(Button).find('i').hasClass('fa-edit')).toBe(true);
      });
  });

  it('Clicking "Edit" button calls props.handleEditClick', () => {
    const wrapper = getWrapper({ isEditable: true });
    expect(handleEditMock).toHaveBeenCalledTimes(0);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, rowIndex) => {
        row.find('td').last().find(Button).simulate('click');
        expect(handleEditMock).toHaveBeenCalledTimes(rowIndex + 1);
      });
  });

  it('Properly renders checkbox column on the right by default if props.showPagination is true', () => {
    const wrapper = getWrapper({ isSelectable: true });
    expect(wrapper.find('thead').find('th').length).toEqual(columnData.length + 1);
    expect(wrapper.find('thead').find('th').first().find('input').exists()).toBe(false);
    expect(wrapper.find('thead').find('th').last().find('input').exists()).toBe(true);
    expect(wrapper.find('thead').find('th').last().find('input').prop('checked')).toBe(false);
    expect(wrapper.find('thead').find('th').last().find('input').prop('disabled')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach(row => {
        expect(row.find('td').length).toEqual(columnData.length + 1);
        expect(row.find('td').first().find('input').exists()).toBe(false);
        expect(row.find('td').last().find('input').exists()).toBe(true);
        expect(row.find('td').last().find('input').prop('checked')).toBe(false);
        expect(row.find('td').last().find('input').prop('disabled')).toBe(false);
      });
  });

  it('Properly renders checkbox column on the left when props.showPagination is true and props.checkboxColumnLocation is set to left', () => {
    const wrapper = getWrapper({ isSelectable: true, checkboxColumnLocation: 'left' });
    expect(wrapper.find('thead').find('th').length).toEqual(columnData.length + 1);
    expect(wrapper.find('thead').find('th').first().find('input').exists()).toBe(true);
    expect(wrapper.find('thead').find('th').first().find('input').prop('checked')).toBe(false);
    expect(wrapper.find('thead').find('th').first().find('input').prop('disabled')).toBe(false);
    expect(wrapper.find('thead').find('th').last().find('input').exists()).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach(row => {
        expect(row.find('td').length).toEqual(columnData.length + 1);
        expect(row.find('td').first().find('input').exists()).toBe(true);
        expect(row.find('td').first().find('input').prop('checked')).toBe(false);
        expect(row.find('td').first().find('input').prop('disabled')).toBe(false);
        expect(row.find('td').last().find('input').exists()).toBe(false);
      });
  });

  it('Properly renders selectedRows', () => {
    const selectedRows = [1, 4];
    const wrapper = getWrapper({ isSelectable: true, selectedRows });
    expect(wrapper.find('thead').find('th').last().find('input').prop('checked')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, rowIndex) => {
        expect(row.find('td').last().find('input').prop('checked')).toBe(selectedRows.includes(rowIndex));
      });
  });

  it('Properly renders checkboxes if props.selectAll is true', () => {
    const wrapper = getWrapper({ isSelectable: true, selectAll: true });
    expect(wrapper.find('thead').find('th').last().find('input').prop('checked')).toBe(true);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach(row => {
        expect(row.find('td').last().find('input').prop('checked')).toBe(true);
      });
  });

  it('Clicking row checkbox calls props.handleSelect', () => {
    let selectedRows = [0, 1, 2, 3, 4];
    const wrapper = getWrapper({ isSelectable: true });
    expect(handleSelectMock).toHaveBeenCalledTimes(0);

    wrapper
      .find('thead')
      .find('th')
      .last()
      .find('input')
      .simulate('change', { target: { checked: true } });
    expect(handleSelectMock).toHaveBeenCalledTimes(1);
    expect(handleSelectMock).toHaveBeenCalledWith(selectedRows);
    wrapper.setProps({ selectedRows, selectAll: true });

    wrapper
      .find('thead')
      .find('th')
      .last()
      .find('input')
      .simulate('change', { target: { checked: false } });
    expect(handleSelectMock).toHaveBeenCalledTimes(2);
    expect(handleSelectMock).toHaveBeenCalledWith([]);
    wrapper.setProps({ selectedRows: [], selectAll: false });

    wrapper
      .find('thead')
      .find('th')
      .last()
      .find('input')
      .simulate('change', { target: { checked: true } });
    expect(handleSelectMock).toHaveBeenCalledTimes(3);
    expect(handleSelectMock).toHaveBeenCalledWith(selectedRows);
    wrapper.setProps({ selectedRows, selectAll: true });
  });

  it('Clicking row checkbox calls props.handleSelect', () => {
    let callCount = 0;
    let selectedRows = [];
    const wrapper = getWrapper({ isSelectable: true });
    expect(handleSelectMock).toHaveBeenCalledTimes(callCount);

    // Select row checkboxes
    _.shuffle(rowData).forEach(row => {
      const index = _.indexOf(rowData, row);
      wrapper
        .find('tbody')
        .find('tr')
        .at(index)
        .find('td')
        .last()
        .find('input')
        .simulate('change', { target: { checked: true } });
      callCount++;
      selectedRows.push(index);
      expect(handleSelectMock).toHaveBeenCalledTimes(callCount);
      expect(handleSelectMock).toHaveBeenCalledWith(selectedRows);
      wrapper.setProps({ selectedRows });
    });

    // Deselect row checkboxes
    _.shuffle(rowData).forEach(row => {
      const index = _.indexOf(rowData, row);
      wrapper
        .find('tbody')
        .find('tr')
        .at(index)
        .find('td')
        .last()
        .find('input')
        .simulate('change', { target: { checked: false } });
      callCount++;
      selectedRows = selectedRows.filter(row => row !== index);
      expect(handleSelectMock).toHaveBeenCalledTimes(callCount);
      expect(handleSelectMock).toHaveBeenCalledWith(selectedRows);
      wrapper.setProps({ selectedRows });
    });
  });

  it('Properly renders disabled rows', () => {
    const disabledRows = [2, 3];
    const wrapper = getWrapper({ isSelectable: true, disabledRows });
    expect(wrapper.find('thead').find('th').last().find('input').prop('disabled')).toBe(false);
    wrapper
      .find('tbody')
      .find('tr')
      .forEach((row, rowIndex) => {
        expect(row.find('td').last().find('input').prop('disabled')).toBe(disabledRows.includes(rowIndex));
        expect(row.find('td').last().find(ReactTooltip).exists()).toBe(disabledRows.includes(rowIndex));
        if (disabledRows.includes(rowIndex)) {
          expect(row.find('td').last().find(ReactTooltip).find('span').text()).toEqual('disabled tooltip');
        }
      });
  });

  it('Disables select all button if all rows are disabled', () => {
    const wrapper = getWrapper({ isSelectable: true, disabledRows: [0, 1, 2, 3, 4] });
    expect(wrapper.find('thead').find('th').last().find('input').prop('disabled')).toBe(true);
  });

  it('Hides all pagination controls (entries dropdown and pagination) when props.showPagination is false', () => {
    const wrapper = getWrapper({ showPagination: false });
    expect(wrapper.find(Spinner).exists()).toBe(false);
    expect(wrapper.find(Table).exists()).toBe(true);
    expect(wrapper.find(InputGroup).exists()).toBe(false);
    expect(wrapper.find(ReactPaginate).exists()).toBe(false);
  });

  it('Changing entries dropdown calls props.handleEntriesChange', () => {
    const wrapper = getWrapper();
    expect(handleEntriesChangeMock).not.toHaveBeenCalled();
    _.shuffle(entryOptions).forEach((entry, index) => {
      wrapper
        .find(InputGroup)
        .find(Form.Control)
        .simulate('change', { target: { value: entry } });
      expect(handleEntriesChangeMock).toHaveBeenCalledTimes(index + 1);
    });
  });

  it('Changing pagination calls props.handlePageUpdate', () => {
    const entries = 2;
    const pages = Math.ceil(rowData.length / entries);
    const wrapper = mount(<CustomTable dataType="test" rowData={rowData.slice(0, entries)} totalRows={rowData.length} columnData={columnData} handlePageUpdate={handlePageUpdateMock} page={0} entries={entries} entryOptions={entryOptions} showPagination={true} />);
    expect(handlePageUpdateMock).not.toHaveBeenCalled();
    wrapper
      .find(ReactPaginate)
      .find('PageView')
      .forEach((page, pageIndex) => {
        expect(page.prop('selected')).toBe(pageIndex === 0);
      });

    _.times(pages - 1, i => {
      wrapper.find(ReactPaginate).find({ children: 'Next' }).simulate('click');
      expect(handlePageUpdateMock).toHaveBeenCalledTimes(i + 1);
      wrapper
        .find(ReactPaginate)
        .find('PageView')
        .forEach((page, pageIndex) => {
          expect(page.prop('selected')).toBe(pageIndex === i + 1);
        });
    });

    _.times(pages - 1, i => {
      wrapper.find(ReactPaginate).find({ children: 'Previous' }).simulate('click');
      expect(handlePageUpdateMock).toHaveBeenCalledTimes(i + pages);
      wrapper
        .find(ReactPaginate)
        .find('PageView')
        .forEach((page, pageIndex) => {
          expect(page.prop('selected')).toBe(pageIndex === pages - 1 - (i + 1));
        });
    });
  });
});
