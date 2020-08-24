import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment';

import confirmDialog from '../util/ConfirmDialog';
import DateInput from '../util/DateInput';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class ExtendedIsolation extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      extended_isolation: this.props.patient.extended_isolation,
      extended_isolation_old: this.props.patient.extended_isolation,
      loading: false,
    };
    this.handleSubmit = this.handleSubmit.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    this.setState({ extended_isolation_old: this.state.extended_isolation, [event.target.id]: event.target.value });
  }

  handleSubmit = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.submit();
    } else {
      this.setState({ extended_isolation: this.state.extended_isolation_old });
    }
  };

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          extended_isolation: this.state.extended_isolation,
          comment: true,
          message: `extended isolation date to ${moment(this.state.extended_isolation).format('MM/DD/YYYY')}.`,
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
                onChange={date =>
                  this.setState({ extended_isolation: date }, () => {
                    this.handleSubmit(
                      `Are you sure you want to modify the extended isolation date to ${moment(this.state.extended_isolation).format('MM/DD/YYYY')}?`
                    );
                  })
                }
                placement="bottom"
              />
            </Col>
          </Row>
          <Row>
            <Col></Col>
          </Row>
        </Col>
      </React.Fragment>
    );
  }
}

ExtendedIsolation.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default ExtendedIsolation;
