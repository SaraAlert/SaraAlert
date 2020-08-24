import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../util/DateInput';
import reportError from '../util/ReportError';

class ExtendIsolation extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showExtendIsolationModal: false,
      extended_isolation:
        props.patient.extended_isolation ||
        moment()
          .add(1, 'day')
          .format('YYYY-MM-DD'),
      reasoning: '',
      loading: false,
    };
    this.toggleExtendIsolationModal = this.toggleExtendIsolationModal.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleExtendIsolationModal() {
    let current = this.state.showExtendIsolationModal;
    this.setState({
      showExtendIsolationModal: !current,
      extended_isolation:
        this.props.patient.extended_isolation ||
        moment()
          .add(1, 'day')
          .format('YYYY-MM-DD'),
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  submit() {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          extended_isolation: this.state.extended_isolation,
          message: 'User extended isolation.',
          reasoning: this.state.reasoning,
          diffState: diffState,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Group>
            <Form.Label className="mb-3">
              You are about to move this case from &quot;Records Requiring Review&quot; to either the &quot;Reporting&quot; or &quot;Non-Reporting&quot; line
              list in the isolation workflow. The date displayed in the &quot;Isolation Extended&quot; column on the dashboard will be updated.
            </Form.Label>
            <DateInput
              id="extended_isolation"
              date={this.state.extended_isolation}
              // minDate={moment()
              //   .add(1, 'day')
              //   .format('YYYY-MM-DD')}
              onChange={date => this.setState({ extended_isolation: date })}
              placement="bottom"
              isClearable
            />
          </Form.Group>
          <p>Please include any additional details:</p>
          <Form.Group>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button onClick={this.toggleExtendIsolationModal} className="ml-2">
          <i className="fas fa-house-user"></i> Extend Isolation
        </Button>
        {this.state.showExtendIsolationModal && this.createModal('Extend Isolation', this.toggleExtendIsolationModal, this.submit)}
      </React.Fragment>
    );
  }
}

ExtendIsolation.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default ExtendIsolation;
