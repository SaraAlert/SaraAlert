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
          comment: true,
          message: `extended isolation date to ${moment(this.state.extended_isolation).format('MM/DD/YYYY')}.`,
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
                onChange={date => this.setState({ extended_isolation: date, showExtendIsolationModal: true, reasoning: '' })}
                placement="bottom"
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
                <Form.Label className="mb-2">
                  {`Are you sure you want to extend this case’s isolation through ${this.state.extended_isolation}?
                  The case will not appear on the Records Requiring Review List until after ${this.state.extended_isolation} AND a recovery definition is met.
                  The case will move to the "Reporting" or "Non-Reporting" line list.`}
                </Form.Label>
              </Form.Group>
              <p>Please include any additional details:</p>
              <Form.Group>
                <Form.Control as="textarea" rows="2" id="reasoning" onChange={event => this.setState({ reasoning: event.target.value })} />
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
