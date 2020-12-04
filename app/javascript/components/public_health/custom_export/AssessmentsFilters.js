import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, InputGroup, Row } from 'react-bootstrap';

import Select from 'react-select';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DateInput from '../../util/DateInput';

class AssessmentsFilters extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      filterOptions: [
        {
          name: 'needs-review',
          title: 'Needs Review (Boolean)',
          description: 'Reports the system considers as symptomatic',
          type: 'boolean',
        },
        {
          name: 'reporter-type',
          title: 'Reporter Type (Select)',
          description: 'Reports created by user or monitoree',
          type: 'option',
          options: ['User', 'Monitoree'],
        },
        {
          name: 'reporter-email',
          title: 'Reporter Email (Text)',
          description: 'Reports created by user with email',
          type: 'search',
        },
        {
          name: 'created-at',
          title: 'Report Created (Date)',
          description: 'Reports created during specified date range',
          type: 'date',
        },
        {
          name: 'created-at-relative',
          title: 'Report Created (Relative Date)',
          description: 'Reports created during specified date range (relative to the current date',
          type: 'relative',
        },
      ],
    };
  }

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

  render() {
    return (
      <Select
        options={this.getFormattedOptions()}
        placeholder="Filter reports by..."
        theme={theme => ({
          ...theme,
          borderRadius: 0,
        })}
      />
      // <Form.Group className="mb-0">
      //   <Form.Label className="nav-input-label m-1">Select Reports:</Form.Label>
      //   <Row className="px-3">
      //     <Col lg={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="clipboard-list" />
      //             <span className="ml-1">Needs Review</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.symptomatic === undefined ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('symptomatic', undefined)}
      //           disabled={this.props.disabled}>
      //           All
      //         </Button>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.symptomatic === true ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('symptomatic', true)}
      //           disabled={this.props.disabled}>
      //           Yes
      //         </Button>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.symptomatic === false ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('symptomatic', false)}
      //           disabled={this.props.disabled}>
      //           No
      //         </Button>
      //       </InputGroup>
      //     </Col>
      //     <Col lg={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="user-edit" />
      //             <span className="ml-1">Reporter</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Form.Control
      //           autoComplete="off"
      //           size="sm"
      //           value={this.props.query?.who_reported || ''}
      //           onChange={event => this.props.onQueryChange('who_reported', event?.target?.value)}
      //           disabled={this.props.disabled}
      //         />
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.who_reported === undefined ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('who_reported', undefined)}
      //           disabled={this.props.disabled}>
      //           All
      //         </Button>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.who_reported === 'User' ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('who_reported', 'User')}
      //           disabled={this.props.disabled}>
      //           User
      //         </Button>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.who_reported === 'Monitoree' ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('who_reported', 'Monitoree')}
      //           disabled={this.props.disabled}>
      //           Monitoree
      //         </Button>
      //       </InputGroup>
      //     </Col>
      //     <Col md={24} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="head-side-cough" />
      //             <span className="ml-1">Symptoms</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Form.Control
      //           autoComplete="off"
      //           size="sm"
      //           value={this.props.query?.symptoms || ''}
      //           onChange={event => this.props.onQueryChange('symptoms', event?.target?.value)}
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //     <Col lg={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="calendar-alt" />
      //             <span className="ml-1">Submitted After</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <DateInput
      //           date={this.props.query?.created_at_after}
      //           minDate={'2020-01-01'}
      //           maxDate={moment()
      //             .add(30, 'days')
      //             .format('YYYY-MM-DD')}
      //           onChange={date => this.props.onQueryChange('created_at_after', date)}
      //           placement="bottom"
      //           isClearable
      //           customClass="form-control-sm"
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //     <Col lg={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="calendar-alt" />
      //             <span className="ml-1">Submitted Before</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <DateInput
      //           date={this.props.query?.created_at_before}
      //           minDate={'2020-01-01'}
      //           maxDate={moment()
      //             .add(30, 'days')
      //             .format('YYYY-MM-DD')}
      //           onChange={date => this.props.onQueryChange('created_at_before', date)}
      //           placement="bottom"
      //           isClearable
      //           customClass="form-control-sm"
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //   </Row>
      // </Form.Group>
    );
  }
}

AssessmentsFilters.propTypes = {
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default AssessmentsFilters;
