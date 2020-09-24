import React from 'react';
import { Button, ButtonGroup, ToggleButton, Row, Col, Form, Modal, Dropdown } from 'react-bootstrap';
import { ToastContainer, toast } from 'react-toastify';
import moment from 'moment-timezone';
import confirmDialog from '../util/ConfirmDialog';
import axios from 'axios';
import DateInput from '../util/DateInput';
import { PropTypes } from 'prop-types';

class AdvancedFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show: false,
      showFilterNameModal: false,
      filterName: null,
      active: [],
      filterOptions: [
        { name: 'blank', title: 'Select Field...', description: '', type: 'blank' },
        { name: 'sent-today', title: 'Sent Notification Today', description: 'Monitorees who have been sent a notification so far today', type: 'boolean' },
        { name: 'responded-today', title: 'Responded Today', description: 'Monitorees who have reported today', type: 'boolean' },
        { name: 'paused', title: 'Notifications Paused', description: 'Monitorees who have paused notifications', type: 'boolean' },
        {
          name: 'preferred-contact-method',
          title: 'Preferred Contact Method',
          description: 'Monitorees preferred contact method',
          type: 'option',
          options: ['Unknown', 'E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out'],
        },
        { name: 'latest-report', title: 'Latest Report', description: 'Monitorees with latest report', type: 'date' },
        { name: 'hoh', title: 'Head of Household', description: 'Monitorees that are a head of household', type: 'boolean' },
        { name: 'enrolled', title: 'Enrolled', description: 'Monitorees enrollment', type: 'date' },
        {
          name: 'last-date-exposure',
          title: 'Last date of exposure',
          description: 'Monitorees who have a last date of exposure',
          type: 'date',
        },
        { name: 'symptom-onset', title: 'Symptom onset', description: 'Monitorees who have a symptom onset', type: 'date' },
        { name: 'continous-exposure', title: 'Continuous Exposure', description: 'Monitorees who have continuous exposure enabled', type: 'boolean' },
        { name: 'telephone-number', title: 'Telephone Number', description: 'Monitoree telephone number', type: 'search' },
        { name: 'email', title: 'Email', description: 'Monitoree email address', type: 'search' },
        { name: 'sara-id', title: 'Sara Alert ID', description: 'Monitoree Sara Alert ID', type: 'search' },
        { name: 'first-name', title: 'First Name', description: 'Monitoree first name', type: 'search' },
        { name: 'middle-name', title: 'Middle Name', description: 'Monitoree middle name', type: 'search' },
        { name: 'last-name', title: 'Last Name', description: 'Monitoree last name', type: 'search' },
        {
          name: 'monitoring-plan',
          title: 'Monitoring Plan',
          description: 'Monitoree monitoring plan',
          type: 'option',
          options: [
            'None',
            'Daily active monitoring',
            'Self-monitoring with public health supervision',
            'Self-monitoring with delegated supervision',
            'Self-observation',
          ],
        },
        { name: 'never-responded', title: 'Never Responded', description: 'Monitorees who have never reported', type: 'boolean' },
        {
          name: 'risk-exposure',
          title: 'Risk Exposure',
          description: 'Monitoree risk exposure',
          type: 'option',
          options: ['High', 'Medium', 'Low', 'No Identified Risk'],
        },
        { name: 'require-interpretation', title: 'Requires Interpretation', description: 'Monitorees who require interpretation', type: 'boolean' },
        {
          name: 'preferred-contact-time',
          title: 'Preferred Contact Time',
          description: 'Monitoree preferred contact time',
          type: 'option',
          options: ['Morning', 'Afternoon', 'Evening'],
        },
      ],
      savedFilters: [],
      activeFilter: null,
      applied: false,
    };
    this.add = this.add.bind(this);
    this.remove = this.remove.bind(this);
    this.reset = this.reset.bind(this);
    this.apply = this.apply.bind(this);
    this.save = this.save.bind(this);
    this.update = this.update.bind(this);
    this.delete = this.delete.bind(this);
    this.clear = this.clear.bind(this);
    this.newFilter = this.newFilter.bind(this);
    this.changeFilterOption = this.changeFilterOption.bind(this);
    this.changeValue = this.changeValue.bind(this);
    this.renderStatement = this.renderStatement.bind(this);
    this.renderOptions = this.renderOptions.bind(this);
    this.setFilter = this.setFilter.bind(this);
    this.renderFilterNameModal = this.renderFilterNameModal.bind(this);
  }

  componentDidMount() {
    if (this.state.active.length === 0) {
      // Start with empty default
      this.add();
    }

    // Grab saved filters
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios.get(window.BASE_PATH + '/user_filters').then(response => {
      this.setState({ savedFilters: response.data });
    });
  }

  // Add dummy active (default to first option which is a boolean type). User can then edit as needed.
  add() {
    let active = [...this.state.active];
    let dummyEntry = { filterOption: this.state.filterOptions[0], value: true };
    active.push(dummyEntry);
    this.setState({ active });
  }

  // Completely remove a statement from the active list
  remove(index) {
    let active = [...this.state.active];
    let activeWithoutIndex = active.slice(0, index).concat(active.slice(index + 1, active.length));
    this.setState({ active: activeWithoutIndex });
  }

  // Reset state back to fresh start
  reset = async () => {
    if (await confirmDialog('Are you sure you want to reset this filter? Anything currently configured will be lost.')) {
      this.newFilter();
    }
  };

  // Apply the current filter
  apply() {
    this.setState({ show: false, applied: true }, () => {
      this.props.advancedUpdate(this.state.active);
    });
  }

  // Clear the current filter
  clear() {
    this.setState({ activeFilter: null, applied: false }, () => {
      this.props.advancedUpdate(this.state.activeFilter);
    });
  }

  // Start a new filter
  newFilter() {
    this.setState({ active: [], show: true, activeFilter: null, applied: false }, () => {
      this.add();
    });
  }

  // Set the active filter
  setFilter(filter) {
    this.setState({ activeFilter: filter, show: true, active: filter.contents });
  }

  // Change an index filter option
  changeFilterOption(index, name) {
    let active = [...this.state.active];
    let filterOption = this.state.filterOptions.find(filterOption => {
      return filterOption.name === name;
    });

    // Figure out dummy value for the picked type
    let value = null;
    if (filterOption.type === 'boolean') {
      value = true;
    } else if (filterOption.type === 'option') {
      value = filterOption.options[0];
    } else if (filterOption.type === 'date') {
      // Default to "within" type
      value = { start: moment().add(-72, 'hours'), end: moment() };
    } else if (filterOption.type === 'search') {
      value = '';
    }

    active[parseInt(index)] = { filterOption, value, dateOption: filterOption.type === 'date' ? 'within' : null };
    this.setState({ active });
  }

  // Change an index filter option for date
  changeFilterDateOption(index, value) {
    let active = [...this.state.active];
    let defaultValue = null;
    if (value === 'within') {
      defaultValue = { start: moment().add(-72, 'hours'), end: moment() };
    } else {
      defaultValue = moment();
    }
    active[parseInt(index)] = { filterOption: active[parseInt(index)].filterOption, value: defaultValue, dateOption: value };
    this.setState({ active });
  }

  // Change an index value
  changeValue(index, value) {
    let active = [...this.state.active];
    active[parseInt(index)]['value'] = value;
    this.setState({ active });
  }

  // Save a new filter
  save() {
    let self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/user_filters', { active: this.state.active, name: this.state.filterName })
      .catch(() => {
        toast.error('Failed to save filter.');
      })
      .then(response => {
        toast.success('Filter successfully saved.');
        this.setState({ activeFilter: response.data, savedFilters: [...self.state.savedFilters, response.data] });
      });
  }

  // Update an existing filter
  update() {
    let self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .put(window.BASE_PATH + '/user_filters/' + this.state.activeFilter.id, { active: this.state.active })
      .catch(() => {
        toast.error('Failed to update filter.');
      })
      .then(response => {
        toast.success('Filter successfully updated.');
        this.setState({
          activeFilter: response.data,
          savedFilters: [
            ...self.state.savedFilters.filter(filter => {
              return filter.id != response.data.id;
            }),
            response.data,
          ],
        });
      });
  }

  // Delete an existing filter
  delete() {
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
  }

  // Render the options for the select that represents fields to filter on
  renderOptions(current, index) {
    return (
      <Form.Group key={index + 'opkeygroup'} className="py-0 my-0">
        <Form.Control
          as="select"
          value={current}
          className="py-0 my-0"
          size="sm"
          onChange={event => {
            this.changeFilterOption(index, event.target.value);
          }}>
          {this.state.filterOptions.map((option, op_index) => {
            return (
              <option key={index + 'opkeyop' + op_index} value={option.name} disabled={option.type === 'blank'}>
                {option.title}
              </option>
            );
          })}
        </Form.Control>
      </Form.Group>
    );
  }

  // Render date specific options
  renderDateOptions(current, index) {
    return (
      <Form.Group key={index + 'opkeygroup'} className="py-0 my-0">
        <Form.Control
          as="select"
          value={current}
          className="py-0 my-0"
          size="sm"
          onChange={event => {
            this.changeFilterDateOption(index, event.target.value);
          }}>
          <option value="within">within</option>
          <option value="before">before</option>
          <option value="after">after</option>
        </Form.Control>
      </Form.Group>
    );
  }

  renderFilterNameModal() {
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
  }

  // Render a single line "statement"
  renderStatement(filterOption, value, index, total, dateOption) {
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
          <Col className="py-0" md="8">
            {this.renderOptions(filterOption?.name, index)}
          </Col>
          {filterOption?.type === 'date' && (
            <Col className="py-0" md="3">
              {this.renderDateOptions(dateOption, index)}
            </Col>
          )}
          <Col className="py-0">
            {filterOption?.type === 'boolean' && (
              <ButtonGroup toggle>
                <ToggleButton
                  type="checkbox"
                  variant="outline-primary"
                  checked={value}
                  value="1"
                  size="sm"
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
                  size="sm"
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
                  size="sm"
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
            {filterOption?.type === 'date' && dateOption != 'within' && (
              <Form.Group className="py-0 my-0">
                <DateInput
                  date={value}
                  onChange={date => {
                    this.changeValue(index, date);
                  }}
                  placement="bottom"
                  customClass="form-control-sm"
                />
              </Form.Group>
            )}
            {filterOption?.type === 'date' && dateOption === 'within' && (
              <Form.Group className="py-0 my-0">
                <Row>
                  <Col className="pr-0">
                    <DateInput
                      date={value.start}
                      onChange={date => {
                        this.changeValue(index, { start: date, end: value.end });
                      }}
                      placement="bottom"
                      customClass="form-control-sm"
                    />
                  </Col>
                  <Col className="py-0 px-0 text-center my-auto" md="2">
                    <b>TO</b>
                  </Col>
                  <Col className="pl-0">
                    <DateInput
                      date={value.end}
                      onChange={date => {
                        this.changeValue(index, { start: value.start, end: date });
                      }}
                      placement="bottom"
                      customClass="form-control-sm"
                    />
                  </Col>
                </Row>
              </Form.Group>
            )}
            {filterOption?.type === 'search' && (
              <Form.Group className="py-0 my-0">
                <Form.Control
                  as="input"
                  value={value}
                  className="py-0 my-0"
                  size="sm"
                  onChange={event => {
                    this.changeValue(index, event.target.value);
                  }}
                />
              </Form.Group>
            )}
          </Col>
          <Col className="py-0" md={2}>
            <div className="float-right">
              <Button variant="danger" onClick={() => this.remove(index)} size="sm">
                <i className="fas fa-minus"></i>
              </Button>
            </div>
          </Col>
        </Row>
      </React.Fragment>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Modal
          show={this.state.show}
          centered
          dialogClassName="modal-af"
          onHide={() => {
            this.setState({ show: false });
          }}>
          <Modal.Header>
            <Modal.Title>Advanced Filter ({this.state.activeFilter ? this.state.activeFilter.name : 'new'})</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <Row className="pb-2 pt-1">
              <Col>
                <Button
                  variant="primary"
                  onClick={() => {
                    this.setState({ showFilterNameModal: true, show: false });
                  }}
                  className="mr-1"
                  disabled={!!this.state.activeFilter}>
                  <i className="fas fa-save"></i>
                  <span className="ml-1">Save</span>
                </Button>
                <Button variant="primary" onClick={this.update} className="mr-1" disabled={!this.state.activeFilter}>
                  <i className="fas fa-marker"></i>
                  <span className="ml-1">Update</span>
                </Button>
                <Button variant="danger" onClick={this.delete} disabled={!this.state.activeFilter}>
                  <i className="fas fa-trash"></i>
                  <span className="ml-1">Delete</span>
                </Button>
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
            {this.state.active.map((statement, index) => {
              return this.renderStatement(statement.filterOption, statement.value, index, this.state.active.length, statement.dateOption);
            })}
            <Row className="pt-2 pb-1">
              <Col>
                <Button variant="primary" disabled={this.state.active.length > 4} onClick={() => this.add()} size="sm">
                  <i className="fas fa-plus"></i>
                </Button>
              </Col>
            </Row>
          </Modal.Body>
          <Modal.Footer>
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
        <Dropdown>
          <Dropdown.Toggle variant="primary" size="sm">
            <i className="fas fa-microscope"></i>
            <span className="ml-1">Advanced Filter</span>
          </Dropdown.Toggle>
          <Dropdown.Menu>
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
                <Dropdown.Item
                  href="#"
                  onClick={() => {
                    this.setState({ show: true });
                  }}>
                  <i className="fas fa-search fa-fw"></i>
                  <span className="ml-2">View current filter</span>
                </Dropdown.Item>
              </React.Fragment>
            )}
            <Dropdown.Divider />
            <Dropdown.Header>Saved Filters</Dropdown.Header>
            {this.state.savedFilters.map((filter, index) => {
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
  advancedUpdate: PropTypes.func,
};

export default AdvancedFilter;
