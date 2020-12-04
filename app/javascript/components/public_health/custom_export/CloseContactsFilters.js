import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, InputGroup, Row } from 'react-bootstrap';

import Select from 'react-select';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DateInput from '../../util/DateInput';

class CloseContactsFilters extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Select placeholder="Filter close contacts by..." />
      // <Form.Group className="mb-0">
      //   <Form.Label className="nav-input-label m-1">Select Close Contacts:</Form.Label>
      //   <Row className="px-3">
      //     <Col md={24} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="plus-square" />
      //             <span className="ml-1">Enrolled</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.enrolled === undefined ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('enrolled', undefined)}
      //           disabled={this.props.disabled}>
      //           All
      //         </Button>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.enrolled === true ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('enrolled', true)}
      //           disabled={this.props.disabled}>
      //           Yes
      //         </Button>
      //         <Button
      //           size="sm"
      //           variant={this.props.query?.enrolled === false ? 'primary' : 'outline-secondary'}
      //           style={{ outline: 'none', boxShadow: 'none' }}
      //           onClick={() => this.props.onQueryChange('enrolled', false)}
      //           disabled={this.props.disabled}>
      //           No
      //         </Button>
      //       </InputGroup>
      //     </Col>
      //     <Col lg={12} className="my-1 px-1">
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
      //     <Col lg={12} className="my-1 px-1">
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

CloseContactsFilters.propTypes = {
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default CloseContactsFilters;
