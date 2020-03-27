import React from 'react';
import { Card, Button, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class SymptomsAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState } };
    this.handleChange = this.handleChange.bind(this);
    this.navigate = this.navigate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let field_id = event.target.id.split('_idpre')[0];
    Object.values(current.symptoms).find(symp => symp.name === field_id).value = value;
    this.setState({ current: { ...current } }, () => {
      this.props.setAssessmentState({ ...this.state.current });
    });
  }

  navigate() {
    this.props.submit();
  }

  boolSymptom = symp => {
    // null bool values will default to false
    symp.value = symp.value === true;
    return (
      <Form.Check
        type="switch"
        id={`${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
        key={`key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
        checked={symp.value === true || false}
        label={
          <div>
            <b>{symp.label}</b> {symp.notes ? ' ' + symp.notes : ''}
          </div>
        }
        onChange={this.handleChange}></Form.Check>
    );
  };

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square">
          <Card.Header as="h4">Daily Self-Report</Card.Header>
          <Card.Body>
            <Form.Row>
              <Form.Label className="nav-input-label">Please select all symptoms which you are experiencing.</Form.Label> <br />
            </Form.Row>
            <Form.Row>
              <Form.Group className="pt-1">
                {this.state.current.symptoms
                  .filter(x => {
                    return x.type === 'BoolSymptom';
                  })
                  .map(symp => this.boolSymptom(symp))}
              </Form.Group>
            </Form.Row>
            <Form.Row className="pt-4">
              <Button variant="primary" block size="lg" className="btn-block btn-square" onClick={this.navigate}>
                Submit
              </Button>
            </Form.Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

SymptomsAssessment.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
  goto: PropTypes.func,
  submit: PropTypes.func,
  idPre: PropTypes.string,
};

export default SymptomsAssessment;
