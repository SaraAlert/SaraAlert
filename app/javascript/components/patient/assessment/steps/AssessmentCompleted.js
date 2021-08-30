import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Form } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCheckCircle } from '@fortawesome/free-solid-svg-icons';

class AssessmentCompleted extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Card className="mx-0 card-square align-item-center">
        <Card.Header className="text-center h4">{this.props.translations[`${this.props.lang}`]['html']['weblink']['title']}</Card.Header>
        <Card.Body className="text-center">
          <Form.Label className="text-center pt-1">
            <b>{this.props.translations[`${this.props.lang}`]['html']['weblink']['thank_you']}</b>
          </Form.Label>
          <br />
          <Form.Label className="text-left pt-1">
            <br />• {this.props.translations[`${this.props.lang}`]['html']['weblink']['instruction1']}
            <br />
            <br />• {this.props.translations[`${this.props.lang}`]['html']['weblink']['instruction2']}
            <br />
            <br />• {this.props.translations[`${this.props.lang}`]['html']['weblink']['instruction3']}
            <br />
            <br />
            {(this.props.contact_info.email || this.props.contact_info.phone || this.props.contact_info.webpage) && (
              <React.Fragment>
                {this.props.translations[`${this.props.lang}`]['html']['weblink']['instruction4']}
                <br />
              </React.Fragment>
            )}
            {this.props.contact_info.email && (
              <React.Fragment>
                <br />
                <i className="fa fa-envelope" aria-hidden="true"></i> {this.props.translations[`${this.props.lang}`]['html']['shared']['email']}:{' '}
                <a href={'mailto:' + this.props.contact_info.email}> {this.props.contact_info.email}</a>
              </React.Fragment>
            )}
            {this.props.contact_info.phone && (
              <React.Fragment>
                <br />
                <i className="fa fa-phone" aria-hidden="true"></i> {this.props.translations[`${this.props.lang}`]['html']['shared']['phone']}:{' '}
                <a href={'tel:' + this.props.contact_info.phone}> {this.props.contact_info.phone}</a>
              </React.Fragment>
            )}
            {this.props.contact_info.webpage && (
              <React.Fragment>
                <br />
                <i className="fa fa-desktop" aria-hidden="true"></i> {this.props.translations[`${this.props.lang}`]['html']['shared']['webpage']}:{' '}
                <a href={this.props.contact_info.webpage}> {this.props.contact_info.webpage}</a>
              </React.Fragment>
            )}
          </Form.Label>
          <br />
          <FontAwesomeIcon icon={faCheckCircle} color="#28a745" size="6x"></FontAwesomeIcon>
        </Card.Body>
      </Card>
    );
  }
}

AssessmentCompleted.propTypes = {
  contact_info: PropTypes.object,
  translations: PropTypes.object,
  lang: PropTypes.string,
};

export default AssessmentCompleted;
