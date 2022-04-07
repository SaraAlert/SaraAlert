import React from 'react';
import { shallow } from 'enzyme';
import _ from 'lodash';
import moment from 'moment';
import ReactTooltip from 'react-tooltip';
import { Button, ButtonGroup, Dropdown, Modal, OverlayTrigger, ToggleButton } from 'react-bootstrap';
import AdvancedFilter from '../../../components/public_health/query/AdvancedFilter';
import DateInput from '../../../components/util/DateInput';
import { mockFilterOptions, additionalMultiOption, mockFilter1, mockFilter2, mockSavedFilters, mockBlankContents, mockBooleanContents, mockSearchContents, mockSelectContents, mockNumberContents, mockDateContents, mockRelativeContents, mockMultiContents, mockCombinationContents, mockAdditionalFilterContents, getDefaultCombinationValues } from '../../mocks/mockFilters';

const advancedFilterUpdateMock = jest.fn();
const mockToken = 'testMockTokenString12345';
const numberOptionValues = {
  'less-than': 'less than',
  'less-than-equal': 'less than or equal to',
  equal: 'equal to',
  'greater-than-equal': 'greater than or equal to',
  'greater-than': 'greater than',
  between: 'between',
  '': '',
};
const dateOptionValues = ['within', 'before', 'after'];
const combinationDateOptionValues = ['before', 'after', ''];
const relativeOptionValues = ['today', 'tomorrow', 'yesterday', 'custom'];
const relativeOptionOperatorValues = ['less-than', 'greater-than'];
const relativeOptionUnitValues = ['day(s)', 'week(s)', 'month(s)'];
const relativeOptionWhenValues = ['past', 'future'];

function getWrapper(additionalProps) {
  return shallow(<AdvancedFilter advanced_filter_options={mockFilterOptions} advancedFilterUpdate={advancedFilterUpdateMock} updateStickySettings={true} authenticity_token={mockToken} {...additionalProps} />);
}

function checkStatementRender(wrapper, contents, index) {
  const statement = wrapper.find('.advanced-filter-statement').at(index || 0);
  expect(statement.find('.advanced-filter-options-dropdown').exists()).toBe(true);

  if (_.isNil(contents.filterOption)) {
    expect(statement.find('.advanced-filter-options-dropdown').prop('value')).toBeNull();
    expect(statement.find(ButtonGroup).exists()).toBe(false);
    expect(statement.find('.advanced-filter-search-input').exists()).toBe(false);
    expect(statement.find('.advanced-filter-number-options').exists()).toBe(false);
    expect(statement.find('.advanced-filter-number-options').exists()).toBe(false);
    expect(statement.find('.advanced-filter-date-options').exists()).toBe(false);
    expect(statement.find('.advanced-filter-relative-options').exists()).toBe(false);
    expect(statement.find('.advanced-filter-multi-select').exists()).toBe(false);
    expect(statement.find('.advanced-filter-combination-type-statement').exists()).toBe(false);
  } else {
    expect(statement.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(contents.filterOption.name);

    /* BOOLEAN TYPE */
    if (contents.filterOption.type === 'boolean') {
      expect(statement.find(ButtonGroup).exists()).toBe(true);
      expect(statement.find(ToggleButton).length).toEqual(2);
      expect(statement.find(ToggleButton).at(0).prop('checked')).toEqual(contents.value);
      expect(statement.find(ToggleButton).at(1).prop('checked')).toEqual(!contents.value);

      /* SEARCH TYPE */
    } else if (contents.filterOption.type === 'search') {
      expect(statement.find('.advanced-filter-search-input').exists()).toBe(true);
      expect(statement.find('.advanced-filter-search-input').prop('value')).toEqual(contents.value);

      /* SELECT TYPE */
    } else if (contents.filterOption.type === 'select') {
      expect(statement.find('.advanced-filter-select').exists()).toBe(true);
      expect(statement.find('.advanced-filter-select').prop('value')).toEqual(contents.value);
      expect(statement.find('.advanced-filter-select').find('option').length).toEqual(contents.filterOption.options.length);
      contents.filterOption.options.forEach((option, index) => {
        expect(statement.find('.advanced-filter-select').find('option').at(index).text()).toEqual(option);
        expect(statement.find('.advanced-filter-select').find('option').at(index).prop('value')).toEqual(option);
      });

      /* NUMBER TYPE */
    } else if (contents.filterOption.type === 'number') {
      let numberOptions = _.keys(_.clone(numberOptionValues));
      if (!contents.filterOption.support_blank) {
        numberOptions = numberOptions.filter(o => o !== '');
      }
      if (!contents.filterOption.allow_range) {
        numberOptions = numberOptions.filter(o => o !== 'between');
      }

      expect(statement.find('.advanced-filter-number-options').exists()).toBe(true);
      expect(statement.find('.advanced-filter-number-options').prop('value')).toEqual(contents.numberOption);
      expect(statement.find('.advanced-filter-number-options').find('option').length).toEqual(numberOptions.length);
      numberOptions.forEach((option, index) => {
        expect(statement.find('.advanced-filter-number-options').find('option').at(index).text()).toEqual(numberOptionValues[`${option}`]);
        expect(statement.find('.advanced-filter-number-options').find('option').at(index).prop('value')).toEqual(option === '' ? undefined : option);
      });
      if (contents.numberOption === '') {
        expect(statement.find('.advanced-filter-number-input').exists()).toBe(false);
      } else if (contents.numberOption === 'between') {
        expect(statement.find('.advanced-filter-number-input').exists()).toBe(true);
        expect(statement.find('.advanced-filter-number-input').length).toEqual(2);
        expect(statement.find('.advanced-filter-number-input').at(0).prop('value')).toEqual(contents.value.firstBound);
        expect(statement.find('.advanced-filter-number-input').at(1).prop('value')).toEqual(contents.value.secondBound);
      } else {
        expect(statement.find('.advanced-filter-number-input').exists()).toBe(true);
        expect(statement.find('.advanced-filter-number-input').length).toEqual(1);
        expect(statement.find('.advanced-filter-number-input').prop('value')).toEqual(contents.value);
      }

      /* DATE TYPE */
    } else if (contents.filterOption.type === 'date') {
      expect(statement.find('.advanced-filter-date-options').exists()).toBe(true);
      expect(statement.find('.advanced-filter-date-options').prop('value')).toEqual(contents.dateOption);
      expect(statement.find('.advanced-filter-date-options').find('option').length).toEqual(dateOptionValues.length + (contents.filterOption.support_blank ? 1 : 0));
      dateOptionValues.forEach((value, index) => {
        expect(statement.find('.advanced-filter-date-options').find('option').at(index).text()).toEqual(value);
        expect(statement.find('.advanced-filter-date-options').find('option').at(index).prop('value')).toEqual(value);
      });
      if (contents.filterOption.support_blank) {
        expect(statement.find('.advanced-filter-date-options').find('option').at(dateOptionValues.length).text()).toEqual('');
        expect(statement.find('.advanced-filter-date-options').find('option').at(dateOptionValues.length).prop('value')).toBeUndefined();
      }
      if (contents.dateOption === 'within') {
        expect(statement.find(DateInput).length).toEqual(2);
        expect(statement.find(DateInput).at(0).prop('date')).toEqual(contents.value.start);
        expect(statement.find('.text-center').exists()).toBe(true);
        expect(statement.find('.text-center').find('b').text()).toEqual('TO');
        expect(statement.find(DateInput).at(1).prop('date')).toEqual(contents.value.end);
      } else if (contents.dateOption === '') {
        expect(statement.find(DateInput).length).toEqual(0);
        expect(statement.find('.text-center').exists()).toBe(false);
      } else {
        expect(statement.find(DateInput).length).toEqual(1);
        expect(statement.find(DateInput).prop('date')).toEqual(contents.value);
        expect(statement.find('.text-center').exists()).toBe(false);
      }

      /* RELATIVE DATE TYPE */
    } else if (contents.filterOption.type === 'relative') {
      expect(statement.find('.advanced-filter-relative-options').exists()).toBe(true);
      expect(statement.find('.advanced-filter-relative-options').prop('value')).toEqual(contents.relativeOption);
      expect(statement.find('.advanced-filter-relative-options').find('option').length).toEqual(relativeOptionValues.length);
      relativeOptionValues.forEach((value, index) => {
        expect(statement.find('.advanced-filter-relative-options').find('option').at(index).text()).toEqual(value);
        expect(statement.find('.advanced-filter-relative-options').find('option').at(index).prop('value')).toEqual(value);
      });
      expect(statement.find('.advanced-filter-operator-input').exists()).toBe(contents.relativeOption === 'custom');
      expect(statement.find('.advanced-filter-number-input').exists()).toBe(contents.relativeOption === 'custom');
      expect(statement.find('.advanced-filter-unit-input').exists()).toBe(contents.relativeOption === 'custom');
      expect(statement.find('.advanced-filter-when-input').exists()).toBe(contents.relativeOption === 'custom');

      if (contents.relativeOption === 'custom') {
        expect(statement.find('.advanced-filter-operator-input').prop('value')).toEqual(contents.value.operator);
        expect(statement.find('.advanced-filter-relative-options').find('option').length).toEqual(relativeOptionValues.length);
        relativeOptionValues.forEach((value, index) => {
          expect(statement.find('.advanced-filter-relative-options').find('option').at(index).text()).toEqual(value);
          expect(statement.find('.advanced-filter-relative-options').find('option').at(index).prop('value')).toEqual(value);
        });
        expect(statement.find('.advanced-filter-number-input').prop('value')).toEqual(contents.value.number);
        expect(statement.find('.advanced-filter-unit-input').prop('value')).toEqual(contents.value.unit);
        expect(statement.find('.advanced-filter-unit-input').find('option').length).toEqual(relativeOptionUnitValues.length);
        relativeOptionUnitValues.forEach((value, index) => {
          expect(statement.find('.advanced-filter-unit-input').find('option').at(index).text()).toEqual(value);
          expect(statement.find('.advanced-filter-unit-input').find('option').at(index).prop('value')).toEqual(value.replace('(', '').replace(')', ''));
        });
        expect(statement.find('.advanced-filter-when-input').prop('value')).toEqual(contents.value.when);
        expect(statement.find('.advanced-filter-when-input').find('option').length).toEqual(contents.filterOption.has_timestamp ? relativeOptionWhenValues.length - 1 : relativeOptionWhenValues.length);
        expect(statement.find('.advanced-filter-when-input').find('option').at(0).text()).toEqual('in the past');
        expect(statement.find('.advanced-filter-when-input').find('option').at(0).prop('value')).toEqual('past');
        if (!contents.filterOption.has_timestamp) {
          expect(statement.find('.advanced-filter-when-input').find('option').at(1).text()).toEqual('in the future');
          expect(statement.find('.advanced-filter-when-input').find('option').at(1).prop('value')).toEqual('future');
        }
      }

      /* MULTI SELECT TYPE */
    } else if (contents.filterOption.type === 'multi') {
      expect(statement.find('.advanced-filter-multi-select').exists()).toBe(true);
      expect(statement.find('.advanced-filter-multi-select').prop('value')).toEqual(contents.value);
      contents.filterOption.options.forEach((value, index) => {
        expect(statement.find('.advanced-filter-multi-select').prop('options')[parseInt(index)].value).toEqual(value.value);
        expect(statement.find('.advanced-filter-multi-select').prop('options')[parseInt(index)].label).toEqual(value.label);
      });

      /* COMBINATION TYPE */
    } else if (contents.filterOption.type === 'combination') {
      expect(statement.find('.advanced-filter-combination-type-statement').exists()).toBe(true);
      expect(statement.find('.advanced-filter-combination-type-statement').length).toEqual(contents.value.length);
      contents.value.forEach((val, valIndex) => {
        const comboStatement = statement.find('.advanced-filter-combination-type-statement').at(valIndex);
        expect(comboStatement.find('.advanced-filter-combination-options').prop('value')).toEqual(val.name);
        expect(comboStatement.find('.advanced-filter-combination-options').find('option').length).toEqual(contents.filterOption.fields.length);
        contents.filterOption.fields.forEach((field, fieldIndex) => {
          const matchingValueIndex = contents.value.findIndex(v => v.name === field.name);
          expect(comboStatement.find('.advanced-filter-combination-options').find('option').at(fieldIndex).text()).toEqual(field.title);
          expect(comboStatement.find('.advanced-filter-combination-options').find('option').at(fieldIndex).prop('value')).toEqual(field.name);
          expect(comboStatement.find('.advanced-filter-combination-options').find('option').at(fieldIndex).prop('disabled')).toBe(matchingValueIndex !== valIndex && matchingValueIndex >= 0);
        });

        const matchingField = contents.filterOption.fields.find(field => field.name === val.name);
        if (matchingField.type === 'search') {
          expect(comboStatement.find('.advanced-filter-combination-search-input').exists()).toBe(true);
          expect(comboStatement.find('.advanced-filter-combination-search-input').prop('value')).toEqual(val.value);
        } else if (matchingField.type === 'select') {
          expect(comboStatement.find('.advanced-filter-combination-select-options').exists()).toBe(true);
          expect(comboStatement.find('.advanced-filter-combination-select-options').prop('value')).toEqual(val.value);
          expect(comboStatement.find('.advanced-filter-combination-select-options').find('option').length).toEqual(matchingField.options.length);
          matchingField.options.forEach((option, index) => {
            expect(comboStatement.find('.advanced-filter-combination-select-options').find('option').at(index).text()).toEqual(option);
            expect(comboStatement.find('.advanced-filter-combination-select-options').find('option').at(index).prop('value')).toEqual(option);
          });
        } else if (matchingField.type === 'date') {
          expect(comboStatement.find('.advanced-filter-date-options').exists()).toBe(true);
          expect(comboStatement.find('.advanced-filter-date-options').prop('value')).toEqual(val.value.when);
          expect(comboStatement.find('.advanced-filter-date-options').find('option').length).toEqual(combinationDateOptionValues.length);
          combinationDateOptionValues.forEach((value, index) => {
            expect(comboStatement.find('.advanced-filter-date-options').find('option').at(index).text()).toEqual(value);
            expect(comboStatement.find('.advanced-filter-date-options').find('option').at(index).prop('value')).toEqual(value === '' ? undefined : value);
          });
          expect(statement.find(DateInput).exists()).toBe(val.value.when !== '');
          if (val.value.when !== '') {
            expect(statement.find(DateInput).prop('date')).toEqual(val.value.date);
          }
        } else if (matchingField.type === 'multi') {
          expect(comboStatement.find('.advanced-filter-combination-multi-select-options').exists()).toBe(true);
          expect(comboStatement.find('.advanced-filter-combination-multi-select-options').prop('value')).toEqual(val.value);
          matchingField.options.forEach((value, index) => {
            expect(statement.find('.advanced-filter-combination-multi-select-options').prop('options')[parseInt(index)].value).toEqual(value.value);
            expect(statement.find('.advanced-filter-combination-multi-select-options').prop('options')[parseInt(index)].label).toEqual(value.label);
          });
        }
      });
    }

    /* TOOLTIPS */
    expect(statement.find(ReactTooltip).exists()).toBe(!_.isNil(contents.filterOption.tooltip) || contents.filterOption.type === 'number' || contents.relativeOption === 'custom' || (contents.filterOption.type === 'combination' && contents.filterOption.fields.length !== contents.value.length));
    if (!_.isNil(contents.filterOption.tooltip)) {
      if (_.isArray(contents.filterOption.tooltip)) {
        contents.filterOption.tooltip.forEach((text, index) => {
          expect(statement.find(ReactTooltip).find('span').at(index).text()).toEqual(text);
        });
      } else if (_.isObject(contents.filterOption.tooltip)) {
        expect(statement.find(ReactTooltip).find('span').text()).toEqual(contents.filterOption.tooltip[contents.additionalFilterOption]);
      } else {
        expect(statement.find(ReactTooltip).find('span').text()).toEqual(contents.filterOption.tooltip);
      }
    } else if (contents.filterOption.type === 'number') {
      if (contents.numberOption === '') {
        expect(statement.find(ReactTooltip).find('span').text()).toEqual('Leaving the operator blank will return monitorees with a blank value for this field.');
      } else if (contents.numberOption === 'between') {
        expect(statement.find(ReactTooltip).find('span').text()).toEqual('"Between" is inclusive and will filter for values within the user-entered range, including the start and end values. Leaving either or both number fields blank will result in no monitorees being filtered out.');
      } else {
        expect(statement.find(ReactTooltip).find('span').text()).toEqual('Leaving the number field blank will result in no monitorees being filtered out.');
      }
    } else if (contents.relativeOption === 'custom') {
      expect(statement.find(ReactTooltip).find('span').text()).toEqual(wrapper.instance().getRelativeTooltipString(contents.filterOption, contents.value));
    } else if (contents.filterOption.type === 'combination' && contents.filterOption.fields.length !== contents.value.length) {
      expect(statement.find(ReactTooltip).find('span').text()).toEqual(`Select to add multiple ${contents.filterOption.title.replace(' (Combination)', '')} search criteria.`);
    }

    /* ADDITIONAL FILTER OPTION */
    const hasAdditionalFilterOption = contents.filterOption.type !== 'select' && contents.filterOption.type !== 'multi' && !_.isNil(contents.filterOption.options);
    expect(statement.find('.advanced-filter-additional-filter-options').exists()).toBe(hasAdditionalFilterOption);
    if (hasAdditionalFilterOption) {
      expect(statement.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(contents.additionalFilterOption);
      expect(statement.find('.advanced-filter-additional-filter-options').find('option').length).toEqual(contents.filterOption.options.length);
      contents.filterOption.options.forEach((option, index) => {
        expect(statement.find('.advanced-filter-additional-filter-options').find('option').at(index).text()).toEqual(option);
        expect(statement.find('.advanced-filter-additional-filter-options').find('option').at(index).prop('value')).toEqual(option);
      });
    }
  }
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('AdvancedFilter', () => {
  it('Properly renders all Advanced Filter dropdown and button without any saved filters', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(OverlayTrigger).exists()).toBe(true);
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).find('i').hasClass('fa-microscope')).toBe(true);
    expect(wrapper.find(Button).text()).toEqual('Advanced Filter');
    expect(wrapper.find(Dropdown).exists()).toBe(true);
    expect(wrapper.find(Dropdown.Item).length).toEqual(1);
    expect(wrapper.find(Dropdown.Item).text()).toEqual('New filter');
    expect(wrapper.find(Dropdown.Item).find('i').hasClass('fa-plus')).toBe(true);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).text()).toEqual('Saved Filters');
    expect(wrapper.find(Modal).exists()).toBe(false);
  });

  it('Properly renders all Advanced Filter dropdown and button with saved filters', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    expect(wrapper.find(OverlayTrigger).exists()).toBe(true);
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).find('i').hasClass('fa-microscope')).toBe(true);
    expect(wrapper.find(Button).text()).toEqual('Advanced Filter');
    expect(wrapper.find(Dropdown).exists()).toBe(true);
    expect(wrapper.find(Dropdown.Item).length).toEqual(mockSavedFilters.length + 1);
    expect(wrapper.find(Dropdown.Item).at(0).text()).toEqual('New filter');
    expect(wrapper.find(Dropdown.Item).at(0).find('i').hasClass('fa-plus')).toBe(true);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).text()).toEqual('Saved Filters');
    mockSavedFilters.forEach((filter, index) => {
      expect(
        wrapper
          .find(Dropdown.Item)
          .at(index + 1)
          .text()
      ).toEqual(filter.name);
    });
    expect(wrapper.find(Modal).exists()).toBe(false);
  });

  it('Clicking "Advanced Filter" button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Clicking "New Filter" dropdown option opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Dropdown.Item).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Clicking a saved filter in dropdown opens modal', () => {
    const wrapper = getWrapper();
    wrapper.setState({ savedFilters: mockSavedFilters });
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Renders all main modal components with no active filter set', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).text()).toEqual('Advanced Filter: untitled');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Button).length).toEqual(3);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').text()).toEqual('Save');
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').find('i').hasClass('fa-save')).toBe(true);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').exists()).toBe(false);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').exists()).toBe(false);
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find(Modal.Body).find('.remove-filter-row').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#add-filter-row').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to all line lists until cleared by the user.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').text()).toEqual('Apply');
  });

  it('Properly renders option dropdown', () => {
    const wrapper = getWrapper();
    const sortedFilterOptions = mockFilterOptions.sort((a, b) => {
      return a?.title?.localeCompare(b?.title);
    });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('options').length).toEqual(sortedFilterOptions.length);
    wrapper
      .find('.advanced-filter-options-dropdown')
      .prop('options')
      .forEach((option, index) => {
        expect(option.label).toEqual(sortedFilterOptions[Number(index)].title);
        expect(option.subLabel).toEqual(sortedFilterOptions[Number(index)].description);
        expect(option.value).toEqual(sortedFilterOptions[Number(index)].name);
        expect(option.disabled).toBe(false);
      });
  });

  it('Renders all main modal components when an active filter is set', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).text()).toEqual(`Advanced Filter: ${mockFilter1.name}`);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Button).length).toEqual(mockFilter1.contents.length + 3);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').exists()).toBe(false);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').text()).toEqual('Update');
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').find('i').hasClass('fa-marker')).toBe(true);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').text()).toEqual('Delete');
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').find('i').hasClass('fa-trash')).toBe(true);
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').length).toEqual(mockFilter1.contents.length);
    expect(wrapper.find(Modal.Body).find('.remove-filter-row').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#add-filter-row').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to all line lists until cleared by the user.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').text()).toEqual('Apply');
  });

  it('Renders advanced filter statements properly when an active filter is set', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(mockFilter1.contents.length);
    wrapper.find('.advanced-filter-statement').forEach((statement, index) => {
      checkStatementRender(wrapper, mockFilter1.contents[parseInt(index)], index);
    });
  });

  it('Renders advanced filter statements properly when loading a saved filter', () => {
    const wrapper = getWrapper();
    wrapper.setState({ savedFilters: mockSavedFilters });
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(mockFilter1.contents.length);
    wrapper.find('.advanced-filter-statement').forEach((statement, index) => {
      checkStatementRender(wrapper, mockFilter1.contents[parseInt(index)], index);
    });
  });

  it('Clicking "+" button adds another filter statement row and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, i => {
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i + 1);
      expect(wrapper.state('activeFilterOptions').length).toEqual(i + 1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
    expect(wrapper.state('activeFilterOptions').length).toEqual(5);
  });

  it('Clicking "+" button displays "AND" row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.and-row').length).toEqual(0);
    _.times(4, i => {
      wrapper.find('#add-filter-row').simulate('click');
      expect(wrapper.find('.and-row').length).toEqual(i + 1);
      expect(wrapper.find('.and-row').at(i).text()).toEqual('AND');
    });
  });

  it('Adding five statements disables the "+" button', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, i => {
      expect(wrapper.find('#add-filter-row').prop('disabled')).toBe(false);
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i + 1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('#add-filter-row').prop('disabled')).toBe(true);
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
  });

  it('Clicking "-" button removes filter statement row and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, () => {
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
    expect(wrapper.state('activeFilterOptions').length).toEqual(5);
    expect(wrapper.find('.remove-filter-row').length).toEqual(5);
    expect(wrapper.find('.and-row').length).toEqual(4);
    _.times(5, i => {
      let random = _.random(1, wrapper.find('.remove-filter-row').length);
      wrapper
        .find('.remove-filter-row')
        .at(random - 1)
        .simulate('click');
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(4 - i);
      expect(wrapper.state('activeFilterOptions').length).toEqual(4 - i);
      expect(wrapper.find('.remove-filter-row').length).toEqual(4 - i);
      expect(wrapper.find('.and-row').length).toEqual(3 - i > 0 ? 3 - i : 0);
    });
  });

  it('Clicking "-" button removes properly updates state and dropdown value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');

    mockFilter2.contents.forEach((content, index) => {
      if (!_.isNil(content.filterOption)) {
        wrapper.find('.advanced-filter-options-dropdown').at(index).simulate('change', { value: content.filterOption.name });
      }
      checkStatementRender(wrapper, content, index);
      if (mockFilter2.contents.length - 1 !== index) {
        wrapper.find('#add-filter-row').simulate('click');
      }
    });
    expect(wrapper.state('activeFilterOptions')).toEqual(mockFilter2.contents);

    const filter = _.clone(mockFilter2);
    _.times(mockFilter2.contents.length, () => {
      const random = _.random(0, filter.contents.length - 1);
      filter.contents.splice(random, 1);
      wrapper.find('.remove-filter-row').at(random).simulate('click');
      expect(wrapper.state('activeFilterOptions')).toEqual(filter.contents);
      filter.contents.forEach((content, index) => {
        checkStatementRender(wrapper, content, index);
      });
    });
  });

  it('Properly renders advanced filter boolean type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockBooleanContents.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockBooleanContents.filterOption.name);
    checkStatementRender(wrapper, mockBooleanContents);
  });

  it('Toggling boolean buttons properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockBooleanContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value = false;
    wrapper.find('.advanced-filter-boolean-false').simulate('change');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value = true;
    wrapper.find('.advanced-filter-boolean-true').simulate('change');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);
  });

  it('Properly renders advanced filter search type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockSearchContents.filterOption.name });
    checkStatementRender(wrapper, mockSearchContents);
  });

  it('Changing input text for search type advanced filter properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockSearchContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value = 'Parks & Rec';
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: contents.value } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value = '';
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: contents.value } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);
  });

  it('Properly renders advanced filter select type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockSelectContents.filterOption.name });
    checkStatementRender(wrapper, mockSelectContents);
  });

  it('Changing advanced filter select type option dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockSelectContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(contents.filterOption.options).forEach(option => {
      contents.value = option;
      wrapper.find('.advanced-filter-select').simulate('change', { target: { value: option } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);
    });
  });

  it('Properly renders advanced filter number type statement with single number', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockNumberContents.filterOption.name });
    checkStatementRender(wrapper, mockNumberContents);
  });

  it('Properly renders advanced filter number type statement with number range (filter.allow_range)', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');

    const contents = _.clone(mockNumberContents);
    contents.filterOption.allow_range = true;
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    checkStatementRender(wrapper, contents);

    contents.numberOption = 'between';
    contents.value = { firstBound: 0, secondBound: 0 };
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: contents.numberOption } });
    checkStatementRender(wrapper, contents);
  });

  it('Properly renders advanced filter number type statement with blank number option (filter.support_blank)', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');

    const contents = _.clone(mockNumberContents);
    contents.filterOption.support_blank = true;
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    checkStatementRender(wrapper, contents);

    contents.numberOption = '';
    contents.value = null;
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: contents.numberOption } });
    checkStatementRender(wrapper, contents);
  });

  it('Changing advanced filter numberOption and value for number type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockNumberContents);
    contents.filterOption.allow_range = true;
    contents.filterOption.support_blank = true;
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(_.keys(numberOptionValues)).forEach(option => {
      if (option === '') {
        contents.value = null;
      } else if (option === 'between') {
        contents.value = { firstBound: 0, secondBound: 0 };
      } else if (contents.numberOption === '' || contents.numberOption === 'between') {
        contents.value = 0;
      }
      contents.numberOption = option;

      wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: contents.numberOption } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      if (contents.numberOption === 'between') {
        contents.value.firstBound = _.random(1, 10);
        wrapper
          .find('.advanced-filter-number-input')
          .at(0)
          .simulate('change', { target: { value: contents.value.firstBound } });
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);

        contents.value.secondBound = _.random(1, 10);
        wrapper
          .find('.advanced-filter-number-input')
          .at(1)
          .simulate('change', { target: { value: contents.value.secondBound } });
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);
      } else if (contents.numberOption === '') {
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);
      } else {
        contents.value = _.random(1, 10);
        wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: contents.value } });
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);
      }
    });
  });

  it('Properly renders advanced filter date type statement with date range', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockDateContents.filterOption.name });
    checkStatementRender(wrapper, mockDateContents);
  });

  it('Properly renders advanced filter date type statement with single date', () => {
    const wrapper = getWrapper();
    const contents = _.clone(mockDateContents);
    contents.dateOption = 'before';
    contents.value = moment(new Date()).format('YYYY-MM-DD');
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.dateOption } });
    checkStatementRender(wrapper, contents);
  });

  it('Properly renders advanced filter number type statement with blank date option (filter.support_blank)', () => {
    const wrapper = getWrapper();
    const contents = _.clone(mockDateContents);
    contents.dateOption = '';
    contents.value = null;
    contents.filterOption.support_blank = true;
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.dateOption } });
    checkStatementRender(wrapper, contents);
  });

  it('Changing advanced filter dateOption and values for date type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockDateContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value.start = moment(new Date()).subtract(14, 'd').format('YYYY-MM-DD');
    wrapper.find(DateInput).at(0).simulate('change', contents.value.start);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value.end = moment(new Date()).subtract(5, 'd').format('YYYY-MM-DD');
    wrapper.find(DateInput).at(1).simulate('change', contents.value.end);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.dateOption = 'before';
    contents.value = moment(new Date()).format('YYYY-MM-DD');
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.dateOption } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value = moment(new Date()).add(5, 'd').format('YYYY-MM-DD');
    wrapper.find(DateInput).simulate('change', contents.value);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.dateOption = '';
    contents.value = '';
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.dateOption } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.dateOption = 'after';
    contents.value = moment(new Date()).format('YYYY-MM-DD');
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.dateOption } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value = moment(new Date()).subtract(5, 'd').format('YYYY-MM-DD');
    wrapper.find(DateInput).simulate('change', contents.value);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.dateOption = 'within';
    contents.value = { start: moment(new Date()).subtract(3, 'd').format('YYYY-MM-DD'), end: moment(new Date()).format('YYYY-MM-DD') };
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.dateOption } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);
  });

  it('Properly renders advanced filter relative date type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockRelativeContents.filterOption.name });
    checkStatementRender(wrapper, mockRelativeContents);
  });

  it('Properly renders advanced filter relative date type custom statement', () => {
    const wrapper = getWrapper();
    const contents = _.clone(mockRelativeContents);
    contents.relativeOption = 'custom';
    contents.value = { operator: 'less-than', number: 1, unit: 'days', when: 'past' };
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: contents.relativeOption } });
    checkStatementRender(wrapper, contents);
  });

  it('Changing advanced filter relativeOption and values for relative type advanced filters without timestamp properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockRelativeContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(relativeOptionValues).forEach(option => {
      contents.relativeOption = option;
      contents.value = contents.relativeOption === 'custom' ? { operator: 'less-than', number: 1, unit: 'days', when: 'past' } : contents.relativeOption;
      wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: contents.relativeOption } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      if (contents.relativeOption === 'custom') {
        _.shuffle(relativeOptionOperatorValues).forEach(operator => {
          contents.value.operator = operator;
          wrapper.find('.advanced-filter-operator-input').simulate('change', { target: { value: contents.value.operator } });
          expect(wrapper.state('activeFilter')).toBeNull();
          expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
          checkStatementRender(wrapper, contents);

          _.shuffle(relativeOptionUnitValues).forEach(unit => {
            contents.value.unit = unit;
            wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: contents.value.unit } });
            expect(wrapper.state('activeFilter')).toBeNull();
            expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
            checkStatementRender(wrapper, contents);

            _.shuffle(relativeOptionWhenValues).forEach(when => {
              contents.value.when = when;
              wrapper.find('.advanced-filter-when-input').simulate('change', { target: { value: contents.value.when } });
              expect(wrapper.state('activeFilter')).toBeNull();
              expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
              checkStatementRender(wrapper, contents);

              contents.value.number = _.random(0, 10);
              wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: contents.value.number } });
              expect(wrapper.state('activeFilter')).toBeNull();
              expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
              checkStatementRender(wrapper, contents);
            });
          });
        });
      }
    });
  });

  it('Changing advanced filter relativeOption and values for relative type advanced filters with timestamp properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockRelativeContents);
    contents.filterOption.has_timestamp = true;
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(relativeOptionValues).forEach(option => {
      contents.relativeOption = option;
      contents.value = contents.relativeOption === 'custom' ? { operator: 'less-than', number: 1, unit: 'days', when: 'past' } : contents.relativeOption;
      wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: contents.relativeOption } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      if (contents.relativeOption === 'custom') {
        _.shuffle(relativeOptionOperatorValues).forEach(operator => {
          contents.value.operator = operator;
          wrapper.find('.advanced-filter-operator-input').simulate('change', { target: { value: contents.value.operator } });
          expect(wrapper.state('activeFilter')).toBeNull();
          expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
          checkStatementRender(wrapper, contents);

          _.shuffle(relativeOptionUnitValues).forEach(unit => {
            contents.value.unit = unit;
            wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: contents.value.unit } });
            expect(wrapper.state('activeFilter')).toBeNull();
            expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
            checkStatementRender(wrapper, contents);

            contents.value.number = _.random(0, 10);
            wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: contents.value.number } });
            expect(wrapper.state('activeFilter')).toBeNull();
            expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
            checkStatementRender(wrapper, contents);
          });
        });
      }
    });
  });

  it('Properly renders advanced filter multi-select type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockMultiContents.filterOption.name });
    checkStatementRender(wrapper, mockMultiContents);
  });

  it('Changing advanced filter multi-select selected options properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockMultiContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(contents.filterOption.options).forEach(option => {
      contents.value.push(option);
      wrapper.find('.advanced-filter-multi-select').simulate('change', contents.value);
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      if (_.sample([true, false])) {
        contents.value.splice(_.random(0, contents.value.length - 1), 1);
        wrapper.find('.advanced-filter-multi-select').simulate('change', contents.value);
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);
      }
    });

    const selectedOptions = contents.value;
    _.shuffle(selectedOptions).forEach(option => {
      contents.value = contents.value.filter(value => value !== option);
      wrapper.find('.advanced-filter-multi-select').simulate('change', contents.value);
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);
    });
  });

  it('Changing advanced filter multi-select filter to another multi-select resets selected', () => {
    const newFilterOptions = _.clone(mockFilterOptions);
    newFilterOptions.push(additionalMultiOption);
    const wrapper = getWrapper({ advanced_filter_options: newFilterOptions });
    wrapper.find(Button).simulate('click');

    const value = mockMultiContents.filterOption.options[_.random(0, mockMultiContents.filterOption.options.length - 1)];
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockMultiContents.filterOption.name });
    expect(wrapper.find('.advanced-filter-multi-select').prop('value')).toEqual([]);
    wrapper.find('.advanced-filter-multi-select').simulate('change', [value]);
    expect(wrapper.find('.advanced-filter-multi-select').prop('value')).toEqual([value]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: additionalMultiOption.name });
    expect(wrapper.find('.advanced-filter-multi-select').prop('value')).toEqual([]);
  });

  it('Properly renders main components of advanced filter combination type statement', () => {
    const wrapper = getWrapper();
    const contents = _.cloneDeep(mockCombinationContents);
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });

    contents.filterOption.fields.forEach((field, index) => {
      if (index !== 0) {
        wrapper.find('.btn-circle').simulate('click');
        contents.value.push({ name: field.name, value: getDefaultCombinationValues(field) });
      }
      checkStatementRender(wrapper, contents);
    });
  });

  it('Changing advanced filter combination type main dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockCombinationContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(contents.filterOption.fields).forEach(field => {
      contents.value = [{ name: field.name, value: getDefaultCombinationValues(field) }];
      wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: field.name } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);
    });
  });

  it('Changing advanced filter combination type search statement input properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockCombinationContents);
    const searchField = contents.filterOption.fields.find(field => field.type === 'search');
    contents.value = [{ name: searchField.name, value: getDefaultCombinationValues(searchField) }];
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: searchField.name } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value[0].value = 'Harry Potter';
    wrapper.find('.advanced-filter-combination-search-input').simulate('change', { target: { value: contents.value[0].value } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    contents.value[0].value = '';
    wrapper.find('.advanced-filter-combination-search-input').simulate('change', { target: { value: contents.value[0].value } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);
  });

  it('Changing advanced filter combination type select statement input properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockCombinationContents);
    const selectField = contents.filterOption.fields.find(field => field.type === 'select');
    contents.value = [{ name: selectField.name, value: getDefaultCombinationValues(selectField) }];
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: selectField.name } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(selectField.options).forEach(option => {
      contents.value[0].value = option;
      wrapper.find('.advanced-filter-combination-select-options').simulate('change', { target: { value: contents.value[0].value } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);
    });
  });

  it('Changing advanced filter combination type date statement input properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockCombinationContents);
    const dateField = contents.filterOption.fields.find(field => field.type === 'date');
    contents.value = [{ name: dateField.name, value: getDefaultCombinationValues(dateField) }];
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: dateField.name } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(combinationDateOptionValues).forEach(option => {
      contents.value[0].value.when = option;
      wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: contents.value[0].value.when } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      if (option !== '') {
        contents.value[0].value.date = moment(new Date()).subtract(_.random(1, 14), 'd').format('YYYY-MM-DD');
        wrapper.find(DateInput).simulate('change', contents.value[0].value.date);
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);
      }
    });
  });

  it('Changing advanced filter combination type multi statement inputs properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockCombinationContents);
    const multiField = contents.filterOption.fields.find(field => field.type === 'multi');
    contents.value = [{ name: multiField.name, value: getDefaultCombinationValues(multiField) }];
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: multiField.name } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(multiField.options).forEach(option => {
      contents.value[0].value.push(option);
      wrapper.find('.advanced-filter-combination-multi-select-options').simulate('change', contents.value[0].value);
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      if (_.sample([true, false])) {
        contents.value[0].value.splice(_.random(0, contents.value[0].value.length - 1), 1);
        wrapper.find('.advanced-filter-combination-multi-select-options').simulate('change', contents.value[0].value);
        expect(wrapper.state('activeFilter')).toBeNull();
        expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
        checkStatementRender(wrapper, contents);
      }
    });

    const selectedOptions = contents.value[0].value;
    _.shuffle(selectedOptions).forEach(option => {
      contents.value[0].value = contents.value[0].value.filter(value => value !== option);
      wrapper.find('.advanced-filter-combination-multi-select-options').simulate('change', contents.value[0].value);
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);
    });
  });

  it('Clicking the combination type "+" button adds another combination statement and displays "AND" row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockCombinationContents.filterOption.name });
    _.times(mockCombinationContents.filterOption.fields.length - 1, i => {
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(i + 1);
      expect(wrapper.find('.and-row').length).toEqual(i);
      expect(wrapper.find(`#${mockCombinationContents.filterOption.name}-0-combination-add`).exists()).toBe(true);
      wrapper.find('.btn-circle').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(mockCombinationContents.filterOption.fields.length);
    expect(wrapper.find('.and-row').length).toEqual(mockCombinationContents.filterOption.fields.length - 1);
    expect(wrapper.find(`#${mockCombinationContents.filterOption.name}-0-combination-add`).exists()).toBe(false);
  });

  it('Adding additional fields to combination filter does not allow for repeats', () => {
    const wrapper = getWrapper();
    const contents = _.clone(mockCombinationContents);
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    checkStatementRender(wrapper, contents);

    let availableFields = _.clone(mockCombinationContents.filterOption.fields);
    _.times(mockCombinationContents.filterOption.fields.length, i => {
      const randomField = availableFields[_.random(0, availableFields.length - 1)];
      contents.value[parseInt(i)] = { name: randomField.name, value: getDefaultCombinationValues(randomField) };
      wrapper
        .find('.advanced-filter-combination-options')
        .at(i)
        .simulate('change', { target: { value: randomField.name } });
      checkStatementRender(wrapper, contents);
      if (i < mockCombinationContents.filterOption.fields.length - 1) {
        wrapper.find('.btn-circle').simulate('click');
      }
      availableFields = availableFields.filter(field => field.name !== randomField.name);
    });

    _.times(mockCombinationContents.filterOption.fields.length - 1, () => {
      let random = _.random(0, contents.value.length - 1);
      contents.value = contents.value.slice(0, random).concat(contents.value.slice(random + 1, contents.value.length));
      wrapper.find('.remove-filter-row').at(random).simulate('click');
      checkStatementRender(wrapper, contents);
    });
  });

  it('Removes the combination type "+" button when all the filter option fields are displayed', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockCombinationContents.filterOption.name });
    _.times(mockCombinationContents.filterOption.fields.length - 1, () => {
      expect(wrapper.find('.advanced-filter-combination-type-statement').find('.btn-circle').exists()).toBe(true);
      wrapper.find('.btn-circle').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-combination-type-statement').find('.btn-circle').exists()).toBe(false);
  });

  it('Clicking the combination type "-" removes combination statements until there is one left, then removes the entire filter statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockCombinationContents.filterOption.name });
    _.times(mockCombinationContents.filterOption.fields.length - 1, () => {
      wrapper.find('.btn-circle').simulate('click');
    });
    _.times(mockCombinationContents.filterOption.fields.length, i => {
      let random = _.random(0, wrapper.find('.remove-filter-row').length - 1);
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(mockCombinationContents.filterOption.fields.length - i);
      wrapper.find('.remove-filter-row').at(random).simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').exists()).toBe(false);
    expect(wrapper.find('.advanced-filter-combination-type-statement').exists()).toBe(false);
  });

  it('Properly renders advanced filter type with additional dropdown options statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockAdditionalFilterContents.filterOption.name });
    checkStatementRender(wrapper, mockAdditionalFilterContents);
  });

  it('Changing additional options dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);

    const contents = _.clone(mockAdditionalFilterContents);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    _.shuffle(contents.filterOption.options).forEach(option => {
      contents.additionalFilterOption = option;
      wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: option } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);

      contents.value = Math.random().toString(36).slice(2); // generates random string
      wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: contents.value } });
      expect(wrapper.state('activeFilter')).toBeNull();
      expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
      checkStatementRender(wrapper, contents);
    });
  });

  it('Clicking "Save" button opens Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBe(true);
    expect(wrapper.find('#filter-name-modal').exists()).toBe(false);
    expect(wrapper.state('showAdvancedFilterModal')).toBe(true);
    expect(wrapper.state('showFilterNameModal')).toBe(false);
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find('#filter-name-modal').exists()).toBe(true);
    expect(wrapper.find('#advanced-filter-modal').exists()).toBe(false);
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('showFilterNameModal')).toBe(true);
  });

  it('Properly renders Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal.Header).text()).toEqual('Filter Name');
    expect(wrapper.find('#filter-name-input').exists()).toBe(true);
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
    expect(wrapper.find('#filter-name-cancel').text()).toEqual('Cancel');
    expect(wrapper.find('#filter-name-save').text()).toEqual('Save');
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBe(true);
  });

  it('Adding text to Filter Name modal input enables "Save" button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBe(true);
    expect(wrapper.state('filterName')).toBeNull();
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBe(false);
    expect(wrapper.state('filterName')).toEqual('some filter name');
  });

  it('Clicking Filter Name modal "Cancel" button hides modal and shows Advanced Filter modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-modal').exists()).toBe(true);
    expect(wrapper.find('#advanced-filter-modal').exists()).toBe(false);
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBe(true);
    expect(wrapper.find('#filter-name-modal').exists()).toBe(false);
  });

  it('Clicking Filter Name modal "Cancel" button resets modal and state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('showFilterNameModal')).toBe(true);
    expect(wrapper.state('filterName')).toEqual('some filter name');
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('some filter name');
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(true);
    expect(wrapper.state('showFilterNameModal')).toBe(false);
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('showFilterNameModal')).toBe(true);
    expect(wrapper.state('filterName')).toBeNull();
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
  });

  it('Filter name is cleared when saving a new filter', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('filterName')).toBeNull();
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.state('filterName')).toEqual('some filter name');
    wrapper.find('#filter-name-save').simulate('click');
    expect(wrapper.state('filterName')).toEqual('some filter name');
    wrapper.find('#advanced-filter-cancel').simulate('click');
    expect(wrapper.state('filterName')).toEqual('some filter name');
    wrapper.find(Dropdown.Item).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('filterName')).toBeNull();
  });

  it('Opening Filter Name modal and clicking "Cancel" button maintains advanced filter modal state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockSearchContents.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockSearchContents.value } });
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockSearchContents]);
    expect(wrapper.state('showAdvancedFilterModal')).toBe(true);
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockSearchContents.filterOption.name);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockSearchContents.value);
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockSearchContents]);
    expect(wrapper.find('.advanced-filter-options-dropdown').exists()).toBe(false);
    expect(wrapper.find('.advanced-filter-search-input').exists()).toBe(false);
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(true);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockSearchContents]);
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockSearchContents.filterOption.name);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockSearchContents.value);
  });

  it('Clicking Filter Name modal "Save" button calls save method', () => {
    const wrapper = getWrapper();
    const saveSpy = jest.spyOn(wrapper.instance(), 'save');
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(saveSpy).not.toHaveBeenCalled();
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(saveSpy).not.toHaveBeenCalled();
    wrapper.find('#filter-name-save').simulate('click');
    expect(saveSpy).toHaveBeenCalled();
  });

  it('Clicking Filter Name modal "Save" button hides modal and shows Advanced Filter modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-modal').exists()).toBe(true);
    expect(wrapper.find('#advanced-filter-modal').exists()).toBe(false);
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    wrapper.find('#filter-name-save').simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBe(true);
    expect(wrapper.find('#filter-name-modal').exists()).toBe(false);
  });

  it('Clicking "Update" button calls update method', () => {
    const wrapper = getWrapper();
    const updateSpy = jest.spyOn(wrapper.instance(), 'update');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(updateSpy).not.toHaveBeenCalled();
    wrapper.find('#advanced-filter-update').simulate('click');
    expect(updateSpy).toHaveBeenCalled();
  });

  it('Clicking "Delete" button calls delete method', () => {
    const wrapper = getWrapper();
    const deleteSpy = jest.spyOn(wrapper.instance(), 'delete');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(deleteSpy).not.toHaveBeenCalled();
    wrapper.find('#advanced-filter-delete').simulate('click');
    expect(deleteSpy).toHaveBeenCalled();
  });

  it('Clicking "Apply" button calls props.advancedFilterUpdate with the right format', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).not.toHaveBeenCalled();
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledWith(
      mockFilter1.contents.map(content => {
        return {
          name: content.filterOption.name,
          value: content.value,
          additionalFilterOption: content.additionalFilterOption,
          dateOption: content.dateOption,
          numberOption: content.numberOption,
          relativeOption: content.relativeOption,
          type: content.filterOption.type,
        };
      }),
      false
    );
  });

  it('Clicking "Apply" button properly updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(true);
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('applied')).toBe(true);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
  });

  it('Clicking "Clear current filter" dropdown option calls props.advancedFilterUpdate', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(0);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(1);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(2);
  });

  it('Clicking "Clear current filter" dropdown option properly updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(true);
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('applied')).toBe(true);
    expect(wrapper.state('activeFilterOptions')).toEqual(mockFilter1.contents);
    expect(wrapper.state('activeFilter')).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBe(false);
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
  });

  it('Clicking "Cancel" button calls cancel method and hides modal', () => {
    const wrapper = getWrapper();
    const cancelSpy = jest.spyOn(wrapper.instance(), 'cancel');
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(cancelSpy).not.toHaveBeenCalled();
    wrapper.find('#advanced-filter-cancel').simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);
    expect(cancelSpy).toHaveBeenCalled();
  });

  it('Triggering advanced filter modal onHide prop calls cancel method and hides modal', () => {
    const wrapper = getWrapper();
    const cancelSpy = jest.spyOn(wrapper.instance(), 'cancel');
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(cancelSpy).not.toHaveBeenCalled();
    wrapper.find(Modal).prop('onHide')();
    expect(wrapper.find(Modal).exists()).toBe(false);
    expect(cancelSpy).toHaveBeenCalled();
  });

  it('Clicking "Cancel" button after making changes properly resets modal to initial state if no filter was applied', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockBlankContents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    checkStatementRender(wrapper, mockBlankContents);

    const contents = _.clone(mockSearchContents);
    contents.value = Math.random().toString(36).slice(2); // generates random string
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: contents.value } });
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    checkStatementRender(wrapper, contents);

    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockBlankContents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    checkStatementRender(wrapper, mockBlankContents);
  });

  it('Clicking "Cancel" button after making changes properly resets modal to the most recent filter applied', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockBlankContents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    checkStatementRender(wrapper, mockBlankContents);

    const contents = _.clone(mockSearchContents);
    contents.value = Math.random().toString(36).slice(2); // generates random string
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: contents.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: contents.value } });
    expect(wrapper.state('applied')).toBe(false);
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter')).toBeNull();
    checkStatementRender(wrapper, contents);

    wrapper.find('#advanced-filter-apply').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBe(true);
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilter).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([contents]);
    checkStatementRender(wrapper, contents);

    const newContents = _.clone(contents);
    newContents.value = Math.random().toString(36).slice(2); // generates random string
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: newContents.value } });
    expect(wrapper.state('applied')).toBe(true);
    expect(wrapper.state('activeFilterOptions')).toEqual([newContents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilter).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([contents]);
    checkStatementRender(wrapper, newContents);

    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBe(true);
    expect(wrapper.state('activeFilterOptions')).toEqual([contents]);
    expect(wrapper.state('activeFilter')).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilter).toBeNull();
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([contents]);
    checkStatementRender(wrapper, contents);
  });
});
