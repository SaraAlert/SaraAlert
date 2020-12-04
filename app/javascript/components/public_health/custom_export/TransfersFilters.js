import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, InputGroup, Row } from 'react-bootstrap';

import Select from 'react-select';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DateInput from '../../util/DateInput';
import JurisdictionFilter from '../query/JurisdictionFilter';

class TransfersFilters extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Select placeholder="Filter transfers by..." />
      // <Form.Group className="mb-0">
      //   <Form.Label className="nav-input-label m-1">Select Transfers:</Form.Label>
      //   <Row className="px-3">
      //     <Col md={24} className="my-1 px-1">
      //       <JurisdictionFilter
      //         label={'From Jurisdiction'}
      //         jurisdiction_paths={this.props.jurisdiction_paths}
      //         jurisdiction={this.props.query?.from_jurisdiction || this.props.jurisdiction?.id}
      //         scope={this.props.query?.from_jurisdiction_scope || 'all'}
      //         onJurisdictionChange={jurisdiction => this.props.onQueryChange('from_jurisdiction', jurisdiction)}
      //         onScopeChange={scope => this.props.onQueryChange('from_jurisdiction_scope', scope)}
      //         disabled={this.props.disabled}
      //       />
      //     </Col>
      //     <Col md={24} className="my-1 px-1">
      //       <JurisdictionFilter
      //         label={'To Jurisdiction'}
      //         jurisdiction_paths={this.props.jurisdiction_paths}
      //         jurisdiction={this.props.query?.to_jurisdiction || this.props.jurisdiction?.id}
      //         scope={this.props.query?.to_jurisdiction_scope || 'all'}
      //         onJurisdictionChange={jurisdiction => this.props.onQueryChange('to_jurisdiction', jurisdiction)}
      //         onScopeChange={scope => this.props.onQueryChange('to_jurisdiction_scope', scope)}
      //         disabled={this.props.disabled}
      //       />
      //     </Col>
      //     <Col lg={12} className="my-1 px-1">
      //       <InputGroup size="sm">
      //         <InputGroup.Prepend>
      //           <InputGroup.Text className="rounded-0">
      //             <FontAwesomeIcon icon="calendar-alt" />
      //             <span className="ml-1">Transferred After</span>
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
      //             <span className="ml-1">Transferred Before</span>
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

TransfersFilters.propTypes = {
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.object,
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
  disabled: PropTypes.bool,
};

export default TransfersFilters;
