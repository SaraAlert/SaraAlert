import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Modal, Row } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../util/DateInput';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class ExtendedIsolation extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showExtendIsolationModal: false,
      extended_isolation: this.props.patient.extended_isolation,
      reasoning: '',
      loading: false,
    };
    this.submit = this.submit.bind(this);
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          extended_isolation: this.state.extended_isolation,
          reasoning: this.state.reasoning,
          diffState: ['extended_isolation'],
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Col>
          <Row className="reports-actions-title">
            <Col>
              <Form.Label className="nav-input-label">
                EXTEND ISOLATION TO
                <InfoTooltip tooltipTextKey="extendedIsolation" location="right"></InfoTooltip>
              </Form.Label>
            </Col>
          </Row>
          <Row>
            <Col>
              <DateInput
                id="extended_isolation"
                date={this.state.extended_isolation}
                minDate={moment()
                  .subtract(30, 'days')
                  .format('YYYY-MM-DD')}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={date => this.setState({ extended_isolation: date, showExtendIsolationModal: true, reasoning: '' })}
                placement="bottom"
                customClass="form-control-lg"
                ariaLabel="Extended Isolation to Date Input"
                isClearable
              />
            </Col>
          </Row>
          <Row>
            <Col></Col>
          </Row>
        </Col>
        {this.state.showExtendIsolationModal && (
          <Modal
            size="lg"
            show
            centered
            onHide={() => this.setState({ showExtendIsolationModal: false, extended_isolation: this.props.patient.extended_isolation })}>
            <Modal.Header>
              <Modal.Title>Extend Isolation</Modal.Title>
            </Modal.Header>
            <Modal.Body>
              <Form.Group>
                {this.props.patient.monitoring ? (
                  <React.Fragment>
                    {this.state.extended_isolation ? (
                      <React.Fragment>
                        {moment(this.state.extended_isolation).isSameOrAfter(moment().format('MM/DD/YYYY')) ? (
                          <Form.Label className="mb-2">
                            {`Are you sure you want to extend this case’s isolation through ${moment(this.state.extended_isolation).format('MM/DD/YYYY')}?`}
                            <br></br>
                            <br></br>
                            {`After clicking “Submit”, the case will be moved to the "Reporting" or "Non-Reporting" line list.
                              This case cannot appear on the records Requiring Review Line List until after ${moment(this.state.extended_isolation).format(
                                'MM/DD/YYYY'
                              )}.
                              If the record meets a recovery definition after ${moment(this.state.extended_isolation).format(
                                'MM/DD/YYYY'
                              )}, it will appear on the
                              Records Requiring Review Line List for review by public health to determine if it is safe to discontinue isolation.`}
                          </Form.Label>
                        ) : (
                          <Form.Label className="mb-2">
                            {`The date you have entered has already passed. Are you sure you want to update the "Extend Isolation To" date to ${moment(
                              this.state.extended_isolation
                            ).format(
                              'MM/DD/YYYY'
                            )}? Since the specified date has already passed, this case is eligible to appear on the Records Requiring Review Line List if a recovery definition is met.`}
                          </Form.Label>
                        )}
                      </React.Fragment>
                    ) : (
                      <Form.Label className="mb-2">
                        {`Are you sure you want to clear the "Extend Isolation To" date? Since the date is cleared, this case is eligible to appear on the Records Requiring Review Line List if a recovery definition is met.`}
                      </Form.Label>
                    )}
                  </React.Fragment>
                ) : (
                  <React.Fragment>
                    {this.state.extended_isolation ? (
                      <Form.Label className="mb-2">
                        {`Are you sure you want to change the Extend Isolation Date to ${moment(this.state.extended_isolation).format(
                          'MM/DD/YYYY'
                        )}? Since this record is on the Closed line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record’s Monitoring Status.`}
                      </Form.Label>
                    ) : (
                      <Form.Label className="mb-2">
                        {`Are you sure you want to clear the "Extend Isolation To" date? Since this record is on the Closed line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record’s Monitoring Status.`}
                      </Form.Label>
                    )}
                  </React.Fragment>
                )}
              </Form.Group>
              <p>Please include any additional details:</p>
              <Form.Group>
                <Form.Control
                  as="textarea"
                  rows="2"
                  id="reasoning"
                  onChange={event => this.setState({ reasoning: event.target.value })}
                  aria-label="Additional Details Text Area"
                />
              </Form.Group>
            </Modal.Body>
            <Modal.Footer>
              <Button
                variant="secondary btn-square"
                onClick={() => this.setState({ showExtendIsolationModal: false, extended_isolation: this.props.patient.extended_isolation })}>
                Cancel
              </Button>
              <Button variant="primary btn-square" onClick={this.submit} disabled={this.state.loading}>
                {this.state.loading && (
                  <React.Fragment>
                    <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                  </React.Fragment>
                )}
                Submit
              </Button>
            </Modal.Footer>
          </Modal>
        )}
      </React.Fragment>
    );
  }
}

ExtendedIsolation.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default ExtendedIsolation;
