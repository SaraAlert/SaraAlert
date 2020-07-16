import React from 'react';
import { Card, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class AssessmentCompleted extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, ...this.props.currentState };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ [event.target.id]: value }, () => {
      this.props.setAssessmentState({ ...this.state });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square align-item-center">
          <Card.Header className="text-center" as="h4">
            {this.props.translations[this.props.lang]['web']['title']}
          </Card.Header>
          <Card.Body className="text-center">
            <Form.Label className="text-center pt-1">
              <b>{this.props.translations[this.props.lang]['web']['thank-you']}</b>
            </Form.Label>
            <br />
            <Form.Label className="text-left pt-1">
              <br />• {this.props.translations[this.props.lang]['web']['instruction1']}
              <br />
              <br />• {this.props.translations[this.props.lang]['web']['instruction2']}
              <br />
              <br />• {this.props.translations[this.props.lang]['web']['instruction3']}
              <br />
              <br />
              {this.props.translations[this.props.lang]['web']['instruction4']}
              <br />
              <br />
              <i class="fa fa-envelope" aria-hidden="true"></i> {this.props.translations[this.props.lang]['web']['email']}:{' '}
              <a href={'mailto:' + this.props.contact_info.email}> {this.props.contact_info.email}</a>
              <br />
              <i class="fa fa-phone" aria-hidden="true"></i> {this.props.translations[this.props.lang]['web']['phone']}:{' '}
              <a href={'tel:' + this.props.contact_info.phone}> {this.props.contact_info.phone}</a>
              <br />
              <i class="fa fa-desktop" aria-hidden="true"></i> {this.props.translations[this.props.lang]['web']['webpage']}:{' '}
              <a href={'//' + this.props.contact_info.webpage}> {this.props.contact_info.webpage}</a>
            </Form.Label>
            <br />
            <Form.Label className="fas fa-check fa-10x text-center pt-2"> </Form.Label>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

AssessmentCompleted.propTypes = {
  contact_info: PropTypes.object,
  translations: PropTypes.object,
  lang: PropTypes.string,
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
};

export default AssessmentCompleted;
