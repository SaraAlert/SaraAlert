import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, ToggleButton, Row, Col, Form, Modal, OverlayTrigger, Tooltip, Dropdown } from 'react-bootstrap';
import Select, { components } from 'react-select';
import ReactTooltip from 'react-tooltip';
import { ToastContainer, toast } from 'react-toastify';
import moment from 'moment-timezone';
import axios from 'axios';
import confirmDialog from '../util/ConfirmDialog';
import DateInput from '../util/DateInput';
import supportedLanguages from '../../data/supportedLanguages.json';

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
          description: 'Monitoree risk exposure risk assessment',
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
      ],
      savedFilters: [],
      activeFilter: null,
      applied: false,
    };
  }

  componentDidMount() {
    if (this.state.activeFilterOptions?.length === 0) {
      // Start with empty default
      this.add();
    }

    // Grab saved filters
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios.get(window.BASE_PATH + '/user_filters').then(response => {
      this.setState({ savedFilters: response.data }, () => {
        // Apply filter if it exists in local storage
        let sessionFilter = localStorage.getItem(`SaraFilter`);
        if (parseInt(sessionFilter)) {
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
  apply = () => {
    this.setState({ show: false, applied: true }, () => {
      this.props.advancedFilterUpdate(this.state.activeFilterOptions);
    });
  };

  // Clear the current filter
  clear = () => {
    this.setState({ activeFilter: null, applied: false }, () => {
      this.props.advancedFilterUpdate(this.state.activeFilter);
      localStorage.setItem(`SaraFilter`, null);
    });
  };

  // Start a new filter
  newFilter = () => {
    this.setState({ activeFilterOptions: [], show: true, activeFilter: null, applied: false }, () => {
      this.add();
    });
  };

  // Set the active filter
  setFilter = (filter, apply = false) => {
    if (filter) {
      this.setState({ activeFilter: filter, show: true, activeFilterOptions: filter?.contents || [] }, () => {
        localStorage.setItem(`SaraFilter`, filter.id);
        if (apply) {
          this.apply();
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
      value = {
        number: 0,
        operator: 'equal',
        option: filterOption.options ? filterOption.options[0] : null,
      };
    } else if (filterOption.type === 'date') {
      // Default to "within" type
      value = {
        start: moment()
          .add(-72, 'hours')
          .format('YYYY-MM-DD'),
        end: moment().format('YYYY-MM-DD'),
      };
    } else if (filterOption.type === 'relative') {
      value = { number: 1, unit: 'days', when: 'past' };
    } else if (filterOption.type === 'search') {
      value = '';
    }

    activeFilterOptions[parseInt(index)] = {
      filterOption,
      value,
      dateOption: filterOption.type === 'date' ? 'within' : null,
      relativeOption: filterOption.type === 'relative' ? 'today' : null,
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
    activeFilterOptions[parseInt(index)] = { filterOption: activeFilterOptions[parseInt(index)].filterOption, value: defaultValue, dateOption: value };
    this.setState({ activeFilterOptions });
  };

  // Change the relative filter option for type relative date
  changeFilterRelativeOption = (index, value, relativeOption) => {
    let activeFilterOptions = [...this.state.activeFilterOptions];
    activeFilterOptions[parseInt(index)] = { filterOption: activeFilterOptions[parseInt(index)].filterOption, value: value, relativeOption: relativeOption };
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
      .catch(() => {
        toast.error('Failed to save filter.');
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
        localStorage.removeItem(`SaraFilter`);
        this.setState({
          show: false,
          applied: false,
          activeFilter: null,
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
        value={this.getFormattedOptions().find(option => {
          return option.value === current;
        })}
        isOptionDisabled={option => option.disabled}
        components={{ Option }}
        onChange={event => {
          this.changeFilterOption(index, event?.value);
        }}
        placeHolder="Select Field...."
        theme={theme => ({
          ...theme,
          borderRadius: 0,
        })}
      />
    );
  };

  // Render date specific options
  renderDateOptions = (current, index) => {
    return (
      <Form.Group key={index + 'opkeygroup'} className="py-0 my-0">
        <Form.Control
          as="select"
          value={current}
          className="py-0 my-0"
          onChange={event => {
            this.changeFilterDateOption(index, event.target.value);
          }}>
          <option value="within">within</option>
          <option value="before">before</option>
          <option value="after">after</option>
        </Form.Control>
      </Form.Group>
    );
  };

  // Render relative date specific options
  renderRelativeOptions = (current, index, value) => {
    return (
      <Form.Control
        as="select"
        value={current}
        onChange={event => {
          this.changeFilterRelativeOption(index, value, event.target.value);
        }}>
        <option value="today">today</option>
        <option value="tomorrow">tomorrow</option>
        <option value="yesterday">yesterday</option>
        <option value="custom">more...</option>
      </Form.Control>
    );
  };

  renderRelativeTooltip = (filter, value, index) => {
    const tooltipId = `${filter.name}-${index}`;
    const filterName = filter.title.replace(' (Relative Date)', '');
    let rangeString, start, end;

    // set variables for date options without a timestamp
    if (filter.name === 'symptom-onset-relative' || filter.name === 'last-date-exposure-relative') {
      if (value.when === 'past') {
        rangeString = 'dated through today’s date';
        start = moment()
          .subtract(value.number, value.unit)
          .format('MM/DD/YY');
        end = moment().format('MM/DD/YY');
      } else {
        rangeString = 'with today’s date';
        start = moment().format('MM/DD/YY');
        end = moment()
          .add(value.number, value.unit)
          .format('MM/DD/YY');
      }

      // set variables for date options including a time stamp
    } else {
      if (value.when === 'past') {
        rangeString = 'dated through today’s date';
        start = moment()
          .subtract(value.number, value.unit)
          .format('MM/DD/YY');
        end = 'now';
      } else {
        rangeString = 'with today’s date as of the current time';
        start = 'now';
        end = moment()
          .add(value.number, value.unit)
          .format('MM/DD/YY');
      }
    }

    const statement = `${filterName} “${value.when}” relative date periods include records ${rangeString}.  The current setting of "${value.when}  ${value.number} ${value.unit}" will return records with ${filterName} date from ${start} through ${end}.`;
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
  };

  // Modal to specify filter name
  renderFilterNameModal = () => {
    return (
      <Modal
        show={this.state.showFilterNameModal}
        centered
        onHide={() => {
          this.setState({ showFilterNameModal: false });
        }}>
        <Modal.Header>
          <Modal.Title>Filter Name</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Control
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
            variant="secondary btn-square"
            onClick={() => {
              this.setState({ showFilterNameModal: false, show: true, filterName: null });
            }}>
            Cancel
          </Button>
          <Button
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

  // Render a single line "statement"
  renderStatement = (filterOption, value, index, total, dateOption, relativeOption) => {
    return (
      <React.Fragment key={'rowkey-filter-p' + index}>
        {index > 0 && index < total && (
          <Row key={'rowkey-filter-and' + index} className="pb-2 pt-2">
            <Col className="py-0">
              <b>AND</b>
            </Col>
          </Row>
        )}
        <Row key={'rowkey-filter' + index} className="pb-1 pt-1">
          <Col className="py-0" md="9">
            {this.renderOptions(filterOption?.name, index)}
          </Col>
          <Col className="py-0">
            {filterOption?.type === 'boolean' && (
              <ButtonGroup toggle>
                <ToggleButton
                  type="checkbox"
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
              <Form.Group className="py-0 my-0">
                <Form.Control
                  as="select"
                  value={value}
                  className="py-0 my-0"
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
              </Form.Group>
            )}
            {filterOption?.type === 'number' && (
              <Form.Group className="py-0 my-0">
                <Row>
                  {filterOption?.options && (
                    // specific dropdown for filters with number type but require additional options
                    <Col md="8">
                      <Form.Control
                        as="select"
                        value={value?.option}
                        onChange={event =>
                          this.changeValue(index, {
                            number: value?.number,
                            operator: value?.operator,
                            option: event?.target?.value,
                          })
                        }>
                        {filterOption.options.map((option, op_index) => {
                          return (
                            <option key={index + 'opkeyop-f' + op_index} value={option}>
                              {option}
                            </option>
                          );
                        })}
                      </Form.Control>
                    </Col>
                  )}
                  <Col md="12">
                    <Form.Control
                      as="select"
                      value={value?.operator}
                      onChange={event =>
                        this.changeValue(index, {
                          number: value?.number,
                          operator: event?.target?.value,
                          option: value?.option,
                        })
                      }>
                      <option value="less-than">{'less than'}</option>
                      <option value="less-than-equal">{'less than or equal to'}</option>
                      <option value="equal">{'equal to'}</option>
                      <option value="greater-than-equal">{'greater than or equal to'}</option>
                      <option value="greater-than">{'greater than'}</option>
                    </Form.Control>
                  </Col>
                  <Col md="4">
                    <Form.Control
                      className="form-control-number"
                      value={value?.number}
                      type="number"
                      min="0"
                      onChange={event =>
                        this.changeValue(index, {
                          number: event?.target?.value,
                          operator: value?.operator,
                          option: value?.option,
                        })
                      }
                    />
                  </Col>
                </Row>
              </Form.Group>
            )}
            {filterOption?.type === 'date' && (
              <Row>
                <Col className="py-0" md="6">
                  {this.renderDateOptions(dateOption, index)}
                </Col>
                {dateOption !== 'within' && (
                  <Col className="py-0">
                    <Form.Group className="py-0 my-0">
                      <DateInput
                        date={value}
                        onChange={date => {
                          this.changeValue(index, date);
                        }}
                        placement="bottom"
                        customClass="form-control-md"
                        minDate={'1900-01-01'}
                        maxDate={moment()
                          .add(2, 'years')
                          .format('YYYY-MM-DD')}
                      />
                    </Form.Group>
                  </Col>
                )}
                {dateOption === 'within' && (
                  <React.Fragment>
                    <Col className="pr-0" md="8">
                      <Form.Group className="py-0 my-0">
                        <DateInput
                          date={value.start}
                          onChange={date => {
                            this.changeValue(index, { start: date, end: value.end });
                          }}
                          placement="bottom"
                          customClass="form-control-md"
                          minDate={'1900-01-01'}
                          maxDate={moment()
                            .add(2, 'years')
                            .format('YYYY-MM-DD')}
                        />
                      </Form.Group>
                    </Col>
                    <Col className="py-0 px-0 text-center my-auto" md="2">
                      <b>TO</b>
                    </Col>
                    <Col className="pl-0" md="8">
                      <Form.Group className="py-0 my-0">
                        <DateInput
                          date={value.end}
                          onChange={date => {
                            this.changeValue(index, { start: value.start, end: date });
                          }}
                          placement="bottom"
                          customClass="form-control-md"
                          minDate={'1900-01-01'}
                          maxDate={moment()
                            .add(2, 'years')
                            .format('YYYY-MM-DD')}
                        />
                      </Form.Group>
                    </Col>
                  </React.Fragment>
                )}
              </Row>
            )}
            {filterOption?.type === 'relative' && (
              <Row>
                <Col className="py-0" md="7">
                  {this.renderRelativeOptions(relativeOption, index, value)}
                </Col>
                {relativeOption === 'custom' && (
                  <React.Fragment>
                    <Col md="6" className="pr-0">
                      <Form.Control
                        as="select"
                        value={value.when}
                        onChange={event => {
                          this.changeValue(index, { number: value.number, unit: value.unit, when: event.target.value });
                        }}>
                        <option value="past">in the past</option>
                        <option value="next">in the next</option>
                      </Form.Control>
                    </Col>
                    <Col md="4" className="pr-0">
                      <Form.Control
                        value={value.number}
                        type="number"
                        min="1"
                        onChange={event => this.changeValue(index, { number: event.target.value, unit: value.unit, when: value.when })}
                      />
                    </Col>
                    <Col md="5" className="pr-0">
                      <Form.Control
                        as="select"
                        value={value.unit}
                        onChange={event => {
                          this.changeValue(index, { number: value.number, unit: event.target.value, when: value.when });
                        }}>
                        <option value="days">day(s)</option>
                        <option value="weeks">week(s)</option>
                        <option value="months">month(s)</option>
                      </Form.Control>
                    </Col>
                    <Col md="2" className="text-center my-auto">
                      {this.renderRelativeTooltip(filterOption, value, index)}
                    </Col>
                  </React.Fragment>
                )}
              </Row>
            )}
            {filterOption?.type === 'search' && (
              <Form.Group className="py-0 my-0">
                <Form.Control
                  as="input"
                  value={value}
                  className="py-0 my-0"
                  onChange={event => {
                    this.changeValue(index, event.target.value);
                  }}
                />
              </Form.Group>
            )}
          </Col>
          <Col className="py-0" md={2}>
            <div className="float-right">
              <Button variant="danger" onClick={() => this.remove(index)}>
                <i className="fas fa-minus"></i>
              </Button>
            </div>
          </Col>
        </Row>
      </React.Fragment>
    );
  };

  onHide = () => {
    this.setState({ show: false });
  };

  render() {
    return (
      <React.Fragment>
        <Modal show={this.state.show} centered dialogClassName="modal-af" onHide={this.onHide}>
          <Modal.Header>
            <Modal.Title>Advanced Filter: {this.state.activeFilter ? this.state.activeFilter.name : 'untitled'}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <Row className="pb-2 pt-1">
              <Col>
                {!this.state.activeFilter && (
                  <Button
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
                  <Button variant="primary" onClick={this.update} className="mr-1">
                    <i className="fas fa-marker"></i>
                    <span className="ml-1">Update</span>
                  </Button>
                )}
                {this.state.activeFilter && (
                  <Button variant="danger" onClick={this.delete} disabled={!this.state.activeFilter}>
                    <i className="fas fa-trash"></i>
                    <span className="ml-1">Delete</span>
                  </Button>
                )}
                <div className="float-right">
                  <Button variant="danger" onClick={this.reset}>
                    Reset
                  </Button>
                  <Button variant="primary" className="ml-2" onClick={this.apply}>
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
                statement.dateOption,
                statement.relativeOption
              );
            })}
            <Row className="pt-2 pb-1">
              <Col>
                <Button variant="primary" disabled={this.state.activeFilterOptions?.length > 4} onClick={() => this.add()}>
                  <i className="fas fa-plus"></i>
                </Button>
              </Col>
            </Row>
          </Modal.Body>
          <Modal.Footer className="justify-unset">
            <p className="lead mr-auto">
              Filter will be applied to the line lists in the <u>{this.props.workflow}</u> workflow until reset.
            </p>
            <Button
              variant="secondary btn-square"
              onClick={() => {
                this.setState({ show: false });
              }}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
        {this.renderFilterNameModal()}
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
          <Dropdown.Toggle variant="outline-secondary" size="sm" className="advanced-filter-dropdown">
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
        <ToastContainer position="top-center" autoClose={2000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </React.Fragment>
    );
  }
}

AdvancedFilter.propTypes = {
  authenticity_token: PropTypes.string,
  advancedFilterUpdate: PropTypes.func,
  workflow: PropTypes.string,
};

export default AdvancedFilter;
