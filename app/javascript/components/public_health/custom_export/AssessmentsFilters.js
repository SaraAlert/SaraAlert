import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, InputGroup, Row } from 'react-bootstrap';

import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DateInput from '../../util/DateInput';

class AssessmentsFilters extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Form.Group className="mb-0">
        <Form.Label className="nav-input-label m-1">Select Reports:</Form.Label>
        <Row className="px-3">
          <Col lg={12} className="my-1 px-1">
            <InputGroup size="sm">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="clipboard-list" />
                  <span className="ml-1">Needs Review</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Button
                size="sm"
                variant={this.props.query?.symptomatic === undefined ? 'primary' : 'outline-secondary'}
                style={{ outline: 'none', boxShadow: 'none' }}
                onClick={() => this.props.onQueryChange('symptomatic', undefined)}
                disabled={this.props.disabled}>
                All
              </Button>
              <Button
                size="sm"
                variant={this.props.query?.symptomatic === true ? 'primary' : 'outline-secondary'}
                style={{ outline: 'none', boxShadow: 'none' }}
                onClick={() => this.props.onQueryChange('symptomatic', true)}
                disabled={this.props.disabled}>
                Yes
              </Button>
              <Button
                size="sm"
                variant={this.props.query?.symptomatic === false ? 'primary' : 'outline-secondary'}
                style={{ outline: 'none', boxShadow: 'none' }}
                onClick={() => this.props.onQueryChange('symptomatic', false)}
                disabled={this.props.disabled}>
                No
              </Button>
            </InputGroup>
          </Col>
          <Col lg={12} className="my-1 px-1">
            <InputGroup size="sm">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="user-edit" />
                  <span className="ml-1">Reporter</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                autoComplete="off"
                size="sm"
                value={this.props.query?.who_reported || ''}
                onChange={event => this.props.onQueryChange('who_reported', event?.target?.value)}
                disabled={this.props.disabled}
              />
              <Button
                size="sm"
                variant={this.props.query?.who_reported === undefined ? 'primary' : 'outline-secondary'}
                style={{ outline: 'none', boxShadow: 'none' }}
                onClick={() => this.props.onQueryChange('who_reported', undefined)}
                disabled={this.props.disabled}>
                All
              </Button>
              <Button
                size="sm"
                variant={this.props.query?.who_reported === 'User' ? 'primary' : 'outline-secondary'}
                style={{ outline: 'none', boxShadow: 'none' }}
                onClick={() => this.props.onQueryChange('who_reported', 'User')}
                disabled={this.props.disabled}>
                User
              </Button>
              <Button
                size="sm"
                variant={this.props.query?.who_reported === 'Monitoree' ? 'primary' : 'outline-secondary'}
                style={{ outline: 'none', boxShadow: 'none' }}
                onClick={() => this.props.onQueryChange('who_reported', 'Monitoree')}
                disabled={this.props.disabled}>
                Monitoree
              </Button>
            </InputGroup>
          </Col>
          <Col md={24} className="my-1 px-1">
            <InputGroup size="sm">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="head-side-cough" />
                  <span className="ml-1">Symptoms</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                autoComplete="off"
                size="sm"
                value={this.props.query?.symptoms || ''}
                onChange={event => this.props.onQueryChange('symptoms', event?.target?.value)}
                disabled={this.props.disabled}
              />
            </InputGroup>
          </Col>
          <Col lg={12} className="my-1 px-1">
            <InputGroup size="sm">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="calendar-alt" />
                  <span className="ml-1">Submitted After</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <DateInput
                date={this.props.query?.created_at_after}
                minDate={'2020-01-01'}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={date => this.props.onQueryChange('created_at_after', date)}
                placement="bottom"
                isClearable
                customClass="form-control-sm"
                disabled={this.props.disabled}
              />
            </InputGroup>
          </Col>
          <Col lg={12} className="my-1 px-1">
            <InputGroup size="sm">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="calendar-alt" />
                  <span className="ml-1">Submitted Before</span>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <DateInput
                date={this.props.query?.created_at_before}
                minDate={'2020-01-01'}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={date => this.props.onQueryChange('created_at_before', date)}
                placement="bottom"
                isClearable
                customClass="form-control-sm"
                disabled={this.props.disabled}
              />
            </InputGroup>
          </Col>
        </Row>
      </Form.Group>
    );
  }
}

AssessmentsFilters.propTypes = {
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default AssessmentsFilters;
