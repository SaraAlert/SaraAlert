import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, ToggleButton, Row, Col, Form, Modal, OverlayTrigger, Tooltip, Dropdown } from 'react-bootstrap';

import Select, { components } from 'react-select';
import ReactTooltip from 'react-tooltip';
import { toast } from 'react-toastify';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';

import DateInput from '../../util/DateInput';
import confirmDialog from '../../util/ConfirmDialog';
import supportedLanguages from '../../../data/supportedLanguages.json';

class AdvancedFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show: false,
      showFilterNameModal: false,
      filterName: null,
      activeFilterOptions: [],
      filterOptions: [
        {
          name: 'sent-today',
          title: 'Sent Notification in last 24 hours (Boolean)',
          description: 'Monitorees who have been sent a notification in the last 24 hours',
          type: 'boolean',
        },
        {
          name: 'responded-today',
          title: 'Reported in last 24 hours (Boolean)',
          description: 'Monitorees who had a report created in the last 24 hours',
          type: 'boolean',
        },
        { name: 'paused', title: 'Notifications Paused (Boolean)', description: 'Monitorees who have paused notifications', type: 'boolean' },
        {
          name: 'preferred-contact-method',
          title: 'Preferred Reporting Method (Select)',
          description: 'Monitorees preferred reporting method',
          type: 'option',
          options: ['Unknown', 'E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', ''],
        },
        {
          name: 'latest-report',
          title: 'Latest Report (Date)',
          description: 'Monitorees with latest report during specified date range',
          type: 'date',
        },
        {
          name: 'latest-report-relative',
          title: 'Latest Report (Relative Date)',
          description: 'Monitorees with latest report during specified date range (relative to the current date)',
          type: 'relative',
          hasTimestamp: true,
        },
        { name: 'hoh', title: 'Daily Reporters (Boolean)', description: 'Monitorees that are a Head of Household or self-reporter', type: 'boolean' },
        {
          name: 'household-member',
          title: 'Household Member (Boolean)',
          description: 'Monitorees that are in a household but not the Head of Household',
          type: 'boolean',
        },
        {
          name: 'enrolled',
          title: 'Enrolled (Date)',
          description: 'Monitorees enrolled in system during specified date range',
          type: 'date',
        },
        {
          name: 'enrolled-relative',
          title: 'Enrolled (Relative Date)',
          description: 'Monitorees enrolled in system during specified date range (relative to the current date)',
          type: 'relative',
          hasTimestamp: true,
        },
        {
          name: 'last-date-exposure',
          title: 'Last Date of Exposure (Date)',
          description: 'Monitorees who have a last date of exposure during specified date range',
          type: 'date',
        },
        {
          name: 'last-date-exposure-relative',
          title: 'Last Date of Exposure (Relative Date)',
          description: 'Monitorees who have a last date of exposure during specified date range (relative to the current date)',
          type: 'relative',
          hasTimestamp: false,
        },
        {
          name: 'symptom-onset',
          title: 'Symptom Onset (Date)',
          description: 'Monitorees who have a symptom onset date during specified date range',
          type: 'date',
        },
        {
          name: 'symptom-onset-relative',
          title: 'Symptom Onset (Relative Date)',
          description: 'Monitorees who have a symptom onset date during specified date range (relative to the current date)',
          type: 'relative',
          hasTimestamp: false,
        },
        { name: 'continous-exposure', title: 'Continuous Exposure (Boolean)', description: 'Monitorees who have continuous exposure enabled', type: 'boolean' },
        {
          name: 'monitoring-status',
          title: 'Active Monitoring (Boolean)',
          description: 'Monitorees who are currently under active monitoring',
          type: 'boolean',
        },
        {
          name: 'primary-language',
          title: 'Primary Language (Select)',
          description: 'Monitoree primary language',
          type: 'option',
          options: supportedLanguages.languages
            .map(lang => {
              return lang.name;
            })
            .concat(['']),
        },
        { name: 'cohort', title: 'Common Exposure Cohort Name (Text)', description: 'Monitoree common exposure cohort name or description', type: 'search' },
        {
          name: 'address-usa',
          title: 'Address (within USA) (Text)',
          description: 'Monitoree Address 1, Town/City, State, Address 2, Zip, or County within USA',
          type: 'search',
        },
        {
          name: 'address-foreign',
          title: 'Address (outside USA) (Text)',
          description: 'Monitoree Address 1, Town/City, Country, Address 2, Postal Code, Address 3 or State/Province (outside USA)',
          type: 'search',
        },
        {
          name: 'telephone-number',
          title: 'Telephone Number (Exact Match) (Text)',
          description: 'Monitorees with specified 10 digit telephone number',
          type: 'search',
        },
        {
          name: 'telephone-number-partial',
          title: 'Telephone Number (Contains) (Text)',
          description: 'Monitorees with a telephone number that contains specified digits',
          type: 'search',
        },
        {
          name: 'close-contact-with-known-case-id',
          title: 'Close Contact with a Known Case ID (Text)',
          description: 'Monitorees with a known exposure to a probable or confirmed case ID',
          type: 'search',
          options: ['Exact Match', 'Contains'],
          tooltip: true,
        },
        { name: 'email', title: 'Email (Text)', description: 'Monitoree email address', type: 'search' },
        { name: 'sara-id', title: 'Sara Alert ID (Text)', description: 'Monitoree Sara Alert ID', type: 'search' },
        { name: 'first-name', title: 'Name (First) (Text)', description: 'Monitoree first name', type: 'search' },
        { name: 'middle-name', title: 'Name (Middle) (Text)', description: 'Monitoree middle name', type: 'search' },
        { name: 'last-name', title: 'Name (Last) (Text)', description: 'Monitoree last name', type: 'search' },
        {
          name: 'monitoring-plan',
          title: 'Monitoring Plan (Select)',
          description: 'Monitoree monitoring plan',
          type: 'option',
          options: [
            'None',
            'Daily active monitoring',
            'Self-monitoring with public health supervision',
            'Self-monitoring with delegated supervision',
            'Self-observation',
            '',
          ],
        },
        { name: 'never-responded', title: 'Never Reported (Boolean)', description: 'Monitorees who have no reports', type: 'boolean' },
        {
          name: 'risk-exposure',
          title: 'Exposure Risk Assessment (Select)',
          description: 'Monitoree exposure risk assessment',
          type: 'option',
          options: ['High', 'Medium', 'Low', 'No Identified Risk', ''],
        },
        { name: 'require-interpretation', title: 'Requires Interpretation (Boolean)', description: 'Monitorees who require interpretation', type: 'boolean' },
        {
          name: 'preferred-contact-time',
          title: 'Preferred Contact Time (Select)',
          description: 'Monitoree preferred contact time',
          type: 'option',
          options: ['Morning', 'Afternoon', 'Evening', ''],
        },
        {
          name: 'manual-contact-attempts',
          title: 'Manual Contact Attempts (Number)',
          description: 'All records with the specified number of manual contact attempts',
          type: 'number',
          options: ['Successful', 'Unsuccessful', 'All'],
        },
        {
          name: 'age',
          title: 'Age (Number)',
          description: 'Current Monitoree Age',
          type: 'number',
          allowRange: true,
        },
        {
          name: 'ten-day-quarantine',
          title: 'Candidate to Reduce Quarantine after 10 Days (Boolean)',
          description: 'All asymptomatic records that meet CDC criteria to end quarantine after Day 10 (based on last date of exposure)',
          type: 'boolean',
          tooltip:
            'This filter is based on "Options to Reduce Quarantine for Contacts of Persons with SARS-COV-2 Infection Using Symptom ' +
            'Monitoring and Diagnostic Testing" released by the CDC on December 2, 2020. For more specific information, see Appendix A in the User Guide.',
        },
        {
          name: 'seven-day-quarantine',
          title: 'Candidate to Reduce Quarantine after 7 Days (Boolean)',
          description:
            'All asymptomatic records that meet CDC criteria to end quarantine after Day 7 (based on last date of exposure and most recent lab result)',
          type: 'boolean',
          tooltip:
            'This filter is based on "Options to Reduce Quarantine for Contacts of Persons with SARS-COV-2 Infection Using Symptom ' +
            'Monitoring and Diagnostic Testing" released by the CDC on December 2, 2020. For more specific information, see Appendix A in the User Guide.',
        },
      ],
      savedFilters: [],
      activeFilter: null,
      applied: false,
      lastAppliedFilter: null,
    };
  }

  componentDidMount() {
    if (this.state.activeFilterOptions?.length === 0) {
      // Start with empty default
      this.add();
    }

    // Set a timestamp to include in url to ensure browser cache is not re-used on page navigation
    const timestamp = `?t=${new Date().getTime()}`;

    // Grab saved filters
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios.get(window.BASE_PATH + '/user_filters' + timestamp).then(response => {
      this.setState({ savedFilters: response.data }, () => {
        // Apply filter if it exists in local storage
        let sessionFilter = localStorage.getItem(`SaraFilter`);
        if (this.props.updateStickySettings && parseInt(sessionFilter)) {
          this.setFilter(
            this.state.savedFilters.find(filter => {
              return filter.id === parseInt(sessionFilter);
            }),
            true
          );
        }
      });
    });
  }

  // Add dummy active (default to first option which is a boolean type). User can then edit as needed.
  add = () => {
    this.setState(state => ({
      activeFilterOptions: [...state.activeFilterOptions, { filterOption: null }],
    }));
  };

  // Completely remove a statement from the active list
  remove = index => {
    this.setState(state => ({
      activeFilterOptions: state.activeFilterOptions.slice(0, index).concat(state.activeFilterOptions.slice(index + 1, state.activeFilterOptions?.length)),
    }));
  };

  // Reset state back to fresh start
  reset = async () => {
    if (await confirmDialog('Are you sure you want to reset this filter? Anything currently configured will be lost.')) {
      this.newFilter();
    }
  };

  // Apply the current filter
  apply = keepStickySettings => {
    const appliedFilter = {
      activeFilter: this.state.activeFilter,
      activeFilterOptions: _.cloneDeep(this.state.activeFilterOptions),
    };
    this.setState({ show: false, applied: true, lastAppliedFilter: appliedFilter }, () => {
      this.props.advancedFilterUpdate(this.state.activeFilterOptions, keepStickySettings);
      if (this.props.updateStickySettings && this.state.activeFilter) {
        localStorage.setItem(`SaraFilter`, this.state.activeFilter.id);
      }
    });
  };

  handleApplyClick = () => {
    this.apply(false);
  };

  // Clear the current filter
  clear = () => {
    this.setState({ activeFilterOptions: [], show: false, activeFilter: null, applied: false }, () => {
      this.add();
      this.props.advancedFilterUpdate(this.state.activeFilter, false);
      if (this.props.updateStickySettings) {
        localStorage.setItem(`SaraFilter`, null);
      }
    });
  };

  // Reset modal when cancelled
  cancel = () => {
    const applied = this.state.applied;
    const activeFilter = applied ? this.state.lastAppliedFilter.activeFilter : null;
    const activeFilterOptions = applied ? this.state.lastAppliedFilter.activeFilterOptions : [];
    this.setState({ show: false, applied, activeFilter, activeFilterOptions }, () => {
      // if no filter was applied, start again with empty default
      if (!applied) {
        this.add();
      }
    });
  };

  // Start a new filter
  newFilter = () => {
    this.setState({ activeFilterOptions: [], show: true, activeFilter: null, applied: false }, () => {
      this.add();
    });
  };

  /**
   * Set the active filter
   *
   * @param {Object} filter
   * @param {Bool} apply - only true when called from componentDidMount(), a flag to determine when the filter should be applied to the results
   *                         results & when other existing sticky settings/filter on the table should persist
   */
  setFilter = (filter, apply = false) => {
    if (filter) {
      this.setState({ activeFilter: filter, show: true, activeFilterOptions: filter?.contents || [] }, () => {
        if (apply) {
          this.apply(true);
        }
      });
    }
  };

  // Change an index filter option
  changeFilterOption = (index, name) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let filterOption = this.state.filterOptions.find(filterOption => {
      return filterOption.name === name;
    });

    // Figure out dummy value for the picked type
    let value = null;
    if (filterOption.type === 'boolean') {
      value = true;
    } else if (filterOption.type === 'option') {
      value = filterOption.options[0];
    } else if (filterOption.type === 'number') {
      value = 0;
    } else if (filterOption.type === 'date') {
      // Default to "within" type
      value = {
        start: moment()
          .add(-72, 'hours')
          .format('YYYY-MM-DD'),
        end: moment().format('YYYY-MM-DD'),
      };
    } else if (filterOption.type === 'relative') {
      value = 'today';
    } else if (filterOption.type === 'search') {
      value = '';
    }

    activeFilterOptions[parseInt(index)] = {
      filterOption,
      value,
      numberOption: filterOption.type === 'number' ? 'equal' : null,
      dateOption: filterOption.type === 'date' ? 'within' : null,
      relativeOption: filterOption.type === 'relative' ? 'today' : null,
      additionalFilterOption: filterOption.type !== 'option' && filterOption.options ? filterOption.options[0] : null,
    };
    this.setState({ activeFilterOptions });
  };

  // Change an index filter option for type number
  changeFilterNumberOption = (index, prevNumberOption, newNumberOption, value, additionalFilterOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let newValue = value;
    if (prevNumberOption === 'between' && newNumberOption !== 'between') {
      newValue = 0;
    } else if (prevNumberOption !== 'between' && newNumberOption === 'between') {
      newValue = { firstBound: 0, secondBound: 0 };
    }
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value: newValue,
      numberOption: newNumberOption,
      additionalFilterOption,
      dateOption: null,
      relativeOption: null,
    };
    this.setState({ activeFilterOptions });
  };

  // Change an index filter option for type date
  changeFilterDateOption = (index, value) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let defaultValue = null;
    if (value === 'within') {
      defaultValue = {
        start: moment()
          .add(-72, 'hours')
          .format('YYYY-MM-DD'),
        end: moment().format('YYYY-MM-DD'),
      };
    } else {
      defaultValue = moment().format('YYYY-MM-DD');
    }
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value: defaultValue,
      dateOption: value,
      numberOption: null,
      relativeOption: null,
      additionalFilterOption: null,
    };
    this.setState({ activeFilterOptions });
  };

  // Change the relative filter option for type relative date
  changeFilterRelativeOption = (index, relativeOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    let defaultValue = relativeOption === 'custom' ? { operator: 'less-than', number: 1, unit: 'days', when: 'past' } : relativeOption;
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value: defaultValue,
      relativeOption,
      dateOption: null,
      numberOption: null,
      additionalFilterOption: null,
    };
    this.setState({ activeFilterOptions });
  };

  // Change the additional filter option supported for different types if provided
  changeFilterAdditionalFilterOption = (index, additionalFilterOption, value, numberOption, dateOption, relativeOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    // add all other options here
    activeFilterOptions[parseInt(index)] = {
      filterOption: activeFilterOptions[parseInt(index)].filterOption,
      value,
      additionalFilterOption,
      numberOption,
      dateOption,
      relativeOption,
    };
    this.setState({ activeFilterOptions });
  };

  // Change an index value
  changeValue = (index, value) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    activeFilterOptions[parseInt(index)]['value'] = value;
    this.setState({ activeFilterOptions });
  };

  // Save a new filter
  save = () => {
    let self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/user_filters', { activeFilterOptions: this.state.activeFilterOptions, name: this.state.filterName })
      .catch(err => {
        toast.error(err?.response?.data?.error ? err.response.data.error : 'Failed to save filter.', {
          autoClose: 8000,
        });
      })
      .then(response => {
        if (response?.data) {
          toast.success('Filter successfully saved.');
          let data = { ...response?.data, contents: JSON.parse(response?.data?.contents) };
          this.setState({ activeFilter: data, savedFilters: [...self.state.savedFilters, data] });
        }
      });
  };

  // Update an existing filter
  update = () => {
    let self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .put(window.BASE_PATH + '/user_filters/' + this.state.activeFilter.id, { activeFilterOptions: this.state.activeFilterOptions })
      .catch(() => {
        toast.error('Failed to update filter.');
      })
      .then(response => {
        if (response?.data) {
          toast.success('Filter successfully updated.');
          let data = { ...response?.data, contents: JSON.parse(response?.data?.contents) };
          this.setState({
            activeFilter: data,
            savedFilters: [
              ...self.state.savedFilters.filter(filter => {
                return filter.id != data.id;
              }),
              data,
            ],
          });
        }
      });
  };

  // Delete an existing filter
  delete = () => {
    let self = this;
    const id = this.state.activeFilter.id;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .delete(window.BASE_PATH + '/user_filters/' + id)
      .catch(() => {
        toast.error('Failed to delete filter.');
      })
      .then(() => {
        toast.success('Filter successfully deleted.');
        if (this.props.updateStickySettings) {
          localStorage.removeItem(`SaraFilter`);
        }
        this.setState({
          show: false,
          applied: false,
          activeFilter: null,
          activeFilterOptions: null,
          savedFilters: [
            ...self.state.savedFilters.filter(filter => {
              return filter.id != id;
            }),
          ],
        });
      });
  };

  // Format options for select
  getFormattedOptions = () => {
    return this.state.filterOptions
      .sort((a, b) => {
        if (a.type === 'blank') return -1;
        if (b.type === 'blank') return 1;
        return a.title.localeCompare(b.title);
      })
      .map(option => {
        return {
          label: option.title,
          subLabel: option.description,
          value: option.name,
          disabled: option.type === 'blank',
        };
      });
  };

  // Render the options for the select that represents fields to filter on
  renderOptions = (current, index) => {
    const selectedValue = this.getFormattedOptions().find(option => {
      return option.value === current;
    });
    const Option = props => {
      return (
        <components.Option {...props}>
          <div>{props.data.label}</div>
          <div style={{ fontSize: 12 }}>{props.data.subLabel}</div>
        </components.Option>
      );
    };
    return (
      <Select
        options={this.getFormattedOptions()}
        value={selectedValue || null}
        isOptionDisabled={option => option.disabled}
        components={{ Option }}
        onChange={event => {
          this.changeFilterOption(index, event?.value);
        }}
        placeholder="Select Field...."
        aria-label="Advanced Filter Options Dropdown"
        className="advanced-filter-select"
        theme={theme => ({
          ...theme,
          borderRadius: 0,
        })}
      />
    );
  };

  // Render number specific options
  renderNumberOptions = (current, index, value, additionalFilterOption, includeBetween) => {
    return (
      <Form.Control
        as="select"
        value={current}
        className="advanced-filter-number-options mr-4"
        aria-label="Advanced Filter Number Select Options"
        onChange={event => this.changeFilterNumberOption(index, current, event.target.value, value, additionalFilterOption)}>
        <option value="less-than">less than</option>
        <option value="less-than-equal">less than or equal to</option>
        <option value="equal">equal to</option>
        <option value="greater-than-equal">greater than or equal to</option>
        <option value="greater-than">greater than</option>
        {includeBetween && <option value="between">between</option>}
      </Form.Control>
    );
  };

  // Render date specific options
  renderDateOptions = (current, index) => {
    return (
      <Form.Control
        as="select"
        value={current}
        className="advanced-filter-date-options py-0 my-0 mr-4"
        aria-label="Advanced Filter Date Select Options"
        onChange={event => {
          this.changeFilterDateOption(index, event.target.value);
        }}>
        <option value="within">within</option>
        <option value="before">before</option>
        <option value="after">after</option>
      </Form.Control>
    );
  };

  // Render relative date specific options
  renderRelativeOptions = (current, index) => {
    return (
      <Form.Control
        as="select"
        value={current}
        className="advanced-filter-relative-options py-0 my-0 mr-3"
        aria-label="Advanced Filter Relative Date Select Options"
        onChange={event => {
          this.changeFilterRelativeOption(index, event.target.value);
        }}>
        <option value="today">today</option>
        <option value="tomorrow">tomorrow</option>
        <option value="yesterday">yesterday</option>
        <option value="custom">custom</option>
      </Form.Control>
    );
  };

  // Render additional filter option dropdown that is used in conjunction with other types
  renderAdditionalFilterOptions = (current, index, options, value, numberOption, dateOption, relativeOption) => {
    return (
      <Form.Control
        as="select"
        value={current}
        className="advanced-filter-additional-filter-options py-0 my-0 mr-3"
        aria-label="Advanced Filter Number Additional Options Input"
        onChange={event => this.changeFilterAdditionalFilterOption(index, event.target.value, value, numberOption, dateOption, relativeOption)}>
        {options.map((option, op_index) => {
          return (
            <option key={index + 'opkeyop-f' + op_index} value={option}>
              {option}
            </option>
          );
        })}
      </Form.Control>
    );
  };

  /**
   * Gets the string inside the tooltip for relative date filter options.
   * @param {Object} filter - Filter currently selected
   * @param {*} value - Filter value
   */
  getRelativeTooltipString(filter, value) {
    const filterName = filter.title.replace(' (Relative Date)', '');
    let before, after;
    let statement = '';
    const operatorValue = value.operator.replace('-', ' ');

    if (value.operator === 'more-than') {
      if (value.when === 'past') {
        before = moment()
          .subtract(value.number, value.unit)
          .format('MM/DD/YY');
      } else {
        after = moment()
          .add(value.number, value.unit)
          .format('MM/DD/YY');
      }
    } else if (value.operator === 'less-than') {
      // set variables for date options including a time stamp
      if (filter.hasTimestamp) {
        if (value.when === 'past') {
          after = moment()
            .subtract(value.number, value.unit)
            .format('MM/DD/YY');
          before = 'now';
        } else {
          after = 'now';
          before = moment()
            .add(value.number, value.unit)
            .format('MM/DD/YY');
        }
      }

      // set variables for date options without a timestamp
      else {
        if (value.when === 'past') {
          after = moment()
            .subtract(value.number, value.unit)
            .format('MM/DD/YY');
          before = moment().format('MM/DD/YY');
        } else {
          after = moment().format('MM/DD/YY');
          before = moment()
            .add(value.number, value.unit)
            .format('MM/DD/YY');
        }
      }
    }

    statement += `The current setting of "${operatorValue} ${value.number} ${value.unit} in the ${value.when}" will return records with ${filterName} date`;
    if (value.operator === 'less-than') {
      const timestampString = filter.hasTimestamp ? 'the current time on ' : '';
      if (value.when === 'past') {
        statement += ` from ${timestampString}${after} through ${before}. `;
      } else {
        statement += ` from ${after} through ${timestampString}${before}. `;
      }
    } else {
      const timestampString = filter.hasTimestamp ? 'the current time on ' : '';
      if (value.when === 'past') {
        statement += ` before ${timestampString}${before}. `;
      } else {
        statement += ` after ${timestampString}${after}. `;
      }
    }
    statement += `To filter between two dates, use the "more than" and "less than" filters in combination.`;
    return statement;
  }

  /**
   * Renders a tooltip for the specific filter option/type.
   * @param {Object} filter - Filter currently selected
   * @param {*} value - Filter value
   * @param {Number} index  - Filter index
   */
  renderOptionTooltip = (filter, value, index, additionalFilterOption) => {
    const tooltipId = `${filter.name}-${index}`;
    let statement;

    // Relative dates all get a specific tooltip
    // Filters of type number only get a tooltip if the numberOption is "between" (i.e. a range)
    // NOTE: Right now because of how this is set up, relative dates can't have a tooltip in addition to the one that is shown
    // here once "more" is selected.
    if (filter.name === 'close-contact-with-known-case-id') {
      if (additionalFilterOption === 'Exact Match') {
        statement =
          'Returns records with an exact match to one or more of the user-entered search values when the known Case ID is specified for monitorees with “Close Contact with a Known Case”. Use commas to separate multiple values (ex: “12, 45” will return records where known Case ID is “45” or “45, 12”).';
      } else if (additionalFilterOption === 'Contains') {
        statement =
          'Returns records that contain a user-entered search value when the known Case ID is specified for monitorees with “Close Contact with a Known Case”. Use commas to separate multiple values (ex: “12, 45” will return records where known Case ID is “123, 90” or “12” or “1451).';
      }
    } else if (filter.type === 'relative') {
      statement = this.getRelativeTooltipString(filter, value);
    } else if (filter.type === 'number') {
      statement = '"Between" is inclusive and will filter for values within the user-entered range, including the start and end values.';
    } else {
      // Otherwise base it on specific filter option
      statement = filter.tooltip;
    }

    // Only render if there is a valid statement for this filter option.
    if (statement) {
      return (
        <div style={{ display: 'inline' }}>
          <span data-for={tooltipId} data-tip="" className="ml-1 tooltip-af">
            <i className="fas fa-question-circle px-0"></i>
          </span>
          <ReactTooltip id={tooltipId} multiline={true} place="bottom" type="dark" effect="solid" className="tooltip-container">
            <span>{statement}</span>
          </ReactTooltip>
        </div>
      );
    }
  };

  // Modal to specify filter name
  renderFilterNameModal = () => {
    return (
      <Modal
        id="filter-name-modal"
        show={this.state.showFilterNameModal}
        centered
        className="advanced-filter-modal-container"
        onHide={() => {
          this.setState({ showFilterNameModal: false });
        }}>
        <Modal.Header>
          <Modal.Title>Filter Name</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Control
            id="filter-name-input"
            as="input"
            value={this.state.filterName || ''}
            className="py-0 my-0"
            onChange={event => {
              this.setState({ filterName: event.target.value });
            }}
          />
        </Modal.Body>
        <Modal.Footer>
          <Button
            id="filter-name-cancel"
            variant="secondary btn-square"
            onClick={() => {
              this.setState({ showFilterNameModal: false, show: true, filterName: null });
            }}>
            Cancel
          </Button>
          <Button
            id="filter-name-save"
            variant="primary btn-square"
            disabled={!this.state.filterName}
            onClick={() => {
              this.setState({ showFilterNameModal: false, show: true }, () => {
                this.save();
              });
            }}>
            Save
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  renderAdvancedFilterModal = () => {
    return (
      <Modal
        id="advanced-filter-modal"
        show={this.state.show}
        centered
        dialogClassName="modal-af"
        className="advanced-filter-modal-container"
        onHide={this.cancel}>
        <Modal.Header>
          <Modal.Title>Advanced Filter: {this.state.activeFilter ? this.state.activeFilter.name : 'untitled'}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="pb-2 pt-1">
            <Col>
              {!this.state.activeFilter && (
                <Button
                  id="advanced-filter-save"
                  variant="primary"
                  onClick={() => {
                    this.setState({ showFilterNameModal: true, show: false });
                  }}
                  className="mr-1">
                  <i className="fas fa-save"></i>
                  <span className="ml-1">Save</span>
                </Button>
              )}
              {this.state.activeFilter && (
                <Button id="advanced-filter-update" variant="primary" onClick={this.update} className="mr-1">
                  <i className="fas fa-marker"></i>
                  <span className="ml-1">Update</span>
                </Button>
              )}
              {this.state.activeFilter && (
                <Button id="advanced-filter-delete" variant="danger" onClick={this.delete} disabled={!this.state.activeFilter}>
                  <i className="fas fa-trash"></i>
                  <span className="ml-1">Delete</span>
                </Button>
              )}
              <div className="float-right">
                <Button id="advanced-filter-reset" variant="danger" onClick={this.reset}>
                  Reset
                </Button>
                <Button id="advanced-filter-apply" variant="primary" className="ml-2" onClick={this.handleApplyClick}>
                  Apply
                </Button>
              </div>
            </Col>
          </Row>
          <Row>
            <Col className="pb-3 pt-1">
              <div className="g-border-bottom-2"></div>
            </Col>
          </Row>
          {this.state.activeFilterOptions?.map((statement, index) => {
            return this.renderStatement(
              statement.filterOption,
              statement.value,
              index,
              this.state.activeFilterOptions?.length,
              statement.numberOption,
              statement.dateOption,
              statement.relativeOption,
              statement.additionalFilterOption
            );
          })}
          <Row className="pt-2 pb-1">
            <Col>
              <Button
                id="add-filter-row"
                variant="primary"
                disabled={this.state.activeFilterOptions?.length > 4}
                onClick={() => this.add()}
                aria-label="Add Advanced Filter Option">
                <i className="fas fa-plus"></i>
              </Button>
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer className="justify-unset">
          <p className="lead mr-auto">
            Filter will be applied to the line lists in the <u>{this.props.workflow}</u> workflow until reset.
          </p>
          <Button id="advanced-filter-cancel" variant="secondary btn-square" onClick={this.cancel}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  // Render a single line "statement"
  renderStatement = (filterOption, value, index, total, numberOption, dateOption, relativeOption, additionalFilterOption) => {
    return (
      <React.Fragment key={'rowkey-filter-p' + index}>
        {index > 0 && index < total && (
          <Row key={'rowkey-filter-and' + index} className="and-row py-2">
            <Col className="py-0">
              <b>AND</b>
            </Col>
          </Row>
        )}
        <Row key={'rowkey-filter' + index} className="advanced-filter-statement pb-1 pt-1">
          <Col className="py-0" md={8}>
            {this.renderOptions(filterOption?.name, index)}
          </Col>
          {/* specific dropdown for filters with a type that requires additional options (not type option) */}
          {filterOption?.type !== 'option' && filterOption?.options && (
            <Col md={4}>
              {this.renderAdditionalFilterOptions(additionalFilterOption, index, filterOption.options, value, numberOption, dateOption, relativeOption)}
            </Col>
          )}
          <Col className="p-0">
            {filterOption?.type === 'boolean' && (
              <ButtonGroup toggle>
                <ToggleButton
                  type="checkbox"
                  className="advanced-filter-boolean-true"
                  aria-label="Advanced Filter Boolean True"
                  variant="outline-primary"
                  checked={value}
                  value="1"
                  onChange={() => {
                    this.changeValue(index, !value);
                  }}>
                  TRUE
                </ToggleButton>
                <ToggleButton
                  type="checkbox"
                  className="advanced-filter-boolean-false"
                  aria-label="Advanced Filter Boolean False"
                  variant="outline-primary"
                  checked={!value}
                  value="0"
                  onChange={() => {
                    this.changeValue(index, !value);
                  }}>
                  FALSE
                </ToggleButton>
              </ButtonGroup>
            )}
            {filterOption?.type === 'option' && (
              <Form.Control
                as="select"
                value={value}
                className="py-0 my-0"
                aria-label="Advanced Filter Option Select"
                onChange={event => {
                  this.changeValue(index, event.target.value);
                }}>
                {filterOption.options.map((option, op_index) => {
                  return (
                    <option key={index + 'opkeyop-f' + op_index} value={option}>
                      {option}
                    </option>
                  );
                })}
              </Form.Control>
            )}
            {filterOption?.type === 'number' && (
              <Form.Group className="form-group-inline py-0 my-0">
                {this.renderNumberOptions(numberOption, index, value, additionalFilterOption, filterOption.allowRange)}
                {numberOption !== 'between' && (
                  <Form.Control
                    className="advanced-filter-number-input"
                    aria-label="Advanced Filter Number Input"
                    value={value}
                    type="number"
                    min="0"
                    onChange={event => this.changeValue(index, event?.target?.value)}
                  />
                )}
                {numberOption === 'between' && (
                  <React.Fragment>
                    <Form.Control
                      className="advanced-filter-number-input"
                      aria-label="Advanced Filter Number Input Bound 1"
                      value={value.firstBound}
                      type="number"
                      min="0"
                      onChange={event => this.changeValue(index, { firstBound: event?.target?.value, secondBound: value.secondBound })}
                    />
                    <div className="text-center my-auto mx-4">
                      <b>AND</b>
                    </div>
                    <Form.Control
                      className="advanced-filter-number-input"
                      aria-label="Advanced Filter Number Input Bound 2"
                      value={value.secondBound}
                      type="number"
                      min="0"
                      onChange={event => this.changeValue(index, { firstBound: value.firstBound, secondBound: event?.target?.value })}
                    />
                  </React.Fragment>
                )}
              </Form.Group>
            )}
            {filterOption?.type === 'date' && (
              <Form.Group className="form-group-inline py-0 my-0">
                {this.renderDateOptions(dateOption, index)}
                {dateOption !== 'within' && (
                  <div className="advanced-filter-date-input">
                    <DateInput
                      date={value}
                      onChange={date => {
                        this.changeValue(index, date);
                      }}
                      placement="bottom"
                      customClass="form-control-md"
                      ariaLabel="Advanced Filter Date Input"
                      minDate={'1900-01-01'}
                      maxDate={moment()
                        .add(2, 'years')
                        .format('YYYY-MM-DD')}
                    />
                  </div>
                )}
                {dateOption === 'within' && (
                  <React.Fragment>
                    <div className="advanced-filter-date-input">
                      <DateInput
                        date={value.start}
                        onChange={date => {
                          this.changeValue(index, { start: date, end: value.end });
                        }}
                        placement="bottom"
                        customClass="form-control-md"
                        ariaLabel="Advanced Filter Start Date Input"
                        minDate={'1900-01-01'}
                        maxDate={moment()
                          .add(2, 'years')
                          .format('YYYY-MM-DD')}
                      />
                    </div>
                    <div className="text-center my-auto mx-4">
                      <b>TO</b>
                    </div>
                    <div className="advanced-filter-date-input">
                      <DateInput
                        date={value.end}
                        onChange={date => {
                          this.changeValue(index, { start: value.start, end: date });
                        }}
                        placement="bottom"
                        customClass="form-control-md"
                        ariaLabel="Advanced Filter End Date Input"
                        minDate={'1900-01-01'}
                        maxDate={moment()
                          .add(2, 'years')
                          .format('YYYY-MM-DD')}
                      />
                    </div>
                  </React.Fragment>
                )}
              </Form.Group>
            )}
            {filterOption?.type === 'relative' && (
              <Form.Group className="form-group-inline py-0 my-0">
                {this.renderRelativeOptions(relativeOption, index)}
                {relativeOption === 'custom' && (
                  <Row>
                    <Form.Control
                      as="select"
                      value={value.operator}
                      className="advanced-filter-operator-input mx-3"
                      aria-label="Advanced Filter Relative Date Operator Select"
                      onChange={event => {
                        this.changeValue(index, { operator: event.target.value, number: value.number, unit: value.unit, when: value.when });
                      }}>
                      <option value="less-than">less than</option>
                      <option value="more-than">more than</option>
                    </Form.Control>
                    <Form.Control
                      value={value.number}
                      className="advanced-filter-number-input"
                      aria-label="Advanced Filter Relative Date Number Select"
                      type="number"
                      min="1"
                      onChange={event => this.changeValue(index, { operator: value.operator, number: event.target.value, unit: value.unit, when: value.when })}
                    />
                    <Form.Control
                      as="select"
                      value={value.unit}
                      className="advanced-filter-unit-input mx-3"
                      aria-label="Advanced Filter Relative Date Unit Select"
                      onChange={event => {
                        this.changeValue(index, { operator: value.operator, number: value.number, unit: event.target.value, when: value.when });
                      }}>
                      <option value="days">day(s)</option>
                      <option value="weeks">week(s)</option>
                      <option value="months">month(s)</option>
                    </Form.Control>
                    <Form.Control
                      as="select"
                      value={value.when}
                      className="advanced-filter-when-input"
                      aria-label="Advanced Filter Relative Date When Select"
                      onChange={event => {
                        this.changeValue(index, { operator: value.operator, number: value.number, unit: value.unit, when: event.target.value });
                      }}>
                      <option value="past">in the past</option>
                      {!filterOption.hasTimestamp && <option value="future">in the future</option>}
                    </Form.Control>
                  </Row>
                )}
              </Form.Group>
            )}
            {filterOption?.type === 'search' && (
              <Form.Control
                as="input"
                value={value}
                className="advanced-filter-search-input py-0 my-0"
                aria-label="Advanced Filter Search Text Input"
                onChange={event => {
                  this.changeValue(index, event.target.value);
                }}
              />
            )}
          </Col>
          <Col className="py-0" md="auto">
            {filterOption && (filterOption.tooltip || numberOption === 'between' || relativeOption === 'custom') && (
              <span className="align-middle mx-3">{this.renderOptionTooltip(filterOption, value, index, additionalFilterOption)}</span>
            )}
            <div className="float-right">
              <Button className="remove-filter-row" variant="danger" onClick={() => this.remove(index)} aria-label="Remove Advanced Filter Option">
                <i className="fas fa-minus"></i>
              </Button>
            </div>
          </Col>
        </Row>
      </React.Fragment>
    );
  };

  render() {
    return (
      <React.Fragment>
        {this.state.show && this.renderAdvancedFilterModal()}
        {this.state.showFilterNameModal && this.renderFilterNameModal()}
        <OverlayTrigger overlay={<Tooltip>Find monitorees that meet specified parameters within current workflow</Tooltip>}>
          <Button
            size="sm"
            className="ml-2"
            onClick={() => {
              this.setState({ show: true });
            }}>
            <i className="fas fa-microscope"></i>
            <span className="ml-1">Advanced Filter</span>
          </Button>
        </OverlayTrigger>
        <Dropdown>
          <Dropdown.Toggle variant="outline-secondary" size="sm" className="advanced-filter-dropdown" aria-label="Advance Filter Dropdown Menu">
            {this.state.applied && (this.state.activeFilter?.name || 'untitled')}
          </Dropdown.Toggle>
          <Dropdown.Menu alignRight>
            <Dropdown.Item href="#" onClick={this.newFilter}>
              <i className="fas fa-plus fa-fw"></i>
              <span className="ml-2">New filter</span>
            </Dropdown.Item>
            {this.state.applied && (
              <React.Fragment>
                <Dropdown.Divider />
                <Dropdown.Item href="#" onClick={this.clear}>
                  <i className="fas fa-times fa-fw"></i>
                  <span className="ml-2">Clear current filter</span>
                </Dropdown.Item>
              </React.Fragment>
            )}
            <Dropdown.Divider />
            <Dropdown.Header>Saved Filters</Dropdown.Header>
            {this.state.savedFilters?.map((filter, index) => {
              return (
                <Dropdown.Item href="#" key={`di${index}`} onClick={() => this.setFilter(filter)}>
                  {filter.name}
                </Dropdown.Item>
              );
            })}
          </Dropdown.Menu>
        </Dropdown>
      </React.Fragment>
    );
  }
}

AdvancedFilter.propTypes = {
  authenticity_token: PropTypes.string,
  advancedFilterUpdate: PropTypes.func,
  workflow: PropTypes.string,
  updateStickySettings: PropTypes.bool,
};

export default AdvancedFilter;
