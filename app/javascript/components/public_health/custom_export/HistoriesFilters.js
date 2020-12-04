import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, InputGroup, Row } from 'react-bootstrap';

import Select from 'react-select';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DateInput from '../../util/DateInput';

class HistoriesFilters extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Select placeholder="Filter histories by..." />
      // <Form.Group className="mb-0">
      //   <Form.Label className="nav-input-label m-1">Select History:</Form.Label>
      //   <Row className="px-3">
      //     <Col md={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="history" />
      //             <span className="ml-1">Type</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Form.Control
      //           autoComplete="off"
      //           size="sm"
      //           value={this.props.query?.history_type || ''}
      //           onChange={event => this.props.onQueryChange('history_type', event?.target?.value)}
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //     <Col md={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="user-edit" />
      //             <span className="ml-1">Creator</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Form.Control
      //           autoComplete="off"
      //           size="sm"
      //           value={this.props.query?.creator || ''}
      //           onChange={event => this.props.onQueryChange('creator', event?.target?.value)}
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //     <Col md={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="calendar-alt" />
      //             <span className="ml-1">Created After</span>
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
      //     <Col md={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="calendar-alt" />
      //             <span className="ml-1">Created Before</span>
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

HistoriesFilters.propTypes = {
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default HistoriesFilters;
