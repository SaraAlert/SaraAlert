import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, InputGroup, Row } from 'react-bootstrap';

import Select from 'react-select';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DateInput from '../../util/DateInput';

class LaboratoriesFilters extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Select placeholder="Filter lab results by..." />
      // <Form.Group className="mb-0">
      //   <Form.Label className="nav-input-label m-1">Select Lab Results:</Form.Label>
      //   <Row className="px-3">
      //     <Col md={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="vial" />
      //             <span className="ml-1">Type</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Form.Control
      //           autoComplete="off"
      //           size="sm"
      //           value={this.props.query?.lab_type || ''}
      //           onChange={event => this.props.onQueryChange('lab_type', event?.target?.value)}
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //     <Col md={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="poll" />
      //             <span className="ml-1">Result</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <Form.Control
      //           autoComplete="off"
      //           size="sm"
      //           value={this.props.query?.result || ''}
      //           onChange={event => this.props.onQueryChange('result', event?.target?.value)}
      //           disabled={this.props.disabled}
      //         />
      //       </InputGroup>
      //     </Col>
      //     <Col lg={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="calendar-alt" />
      //             <span className="ml-1">Collected After</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <DateInput
      //           date={this.props.query?.specimen_collection_after}
      //           minDate={'2020-01-01'}
      //           maxDate={moment()
      //             .add(30, 'days')
      //             .format('YYYY-MM-DD')}
      //           onChange={date => this.props.onQueryChange('specimen_collection_after', date)}
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
      //             <span className="ml-1">Collected Before</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <DateInput
      //           date={this.props.query?.specimen_collection_before}
      //           minDate={'2020-01-01'}
      //           maxDate={moment()
      //             .add(30, 'days')
      //             .format('YYYY-MM-DD')}
      //           onChange={date => this.props.onQueryChange('specimen_collection_before', date)}
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
      //             <span className="ml-1">Reported After</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <DateInput
      //           date={this.props.query?.report_after}
      //           minDate={'2020-01-01'}
      //           maxDate={moment()
      //             .add(30, 'days')
      //             .format('YYYY-MM-DD')}
      //           onChange={date => this.props.onQueryChange('report_after', date)}
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
      //             <span className="ml-1">Reported Before</span>
      //           </InputGroup.Text>
      //         </InputGroup.Prepend>
      //         <DateInput
      //           date={this.props.query?.report_before}
      //           minDate={'2020-01-01'}
      //           maxDate={moment()
      //             .add(30, 'days')
      //             .format('YYYY-MM-DD')}
      //           onChange={date => this.props.onQueryChange('report_before', date)}
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

LaboratoriesFilters.propTypes = {
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default LaboratoriesFilters;
