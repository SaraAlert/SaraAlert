import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button } from 'react-bootstrap';
import RiskStratificationTable from './widgets/RiskStratificationTable';
import MonitoreeFlow from './widgets/MonitoreeFlow';
import Demographics from './widgets/Demographics';
import RiskFactors from './widgets/RiskFactors';
import MonitoreesByDateOfExposure from './widgets/MonitoreesByDateOfExposure';
import CDCMapsTotal from './widgets/CDCMapsTotal';
import CDCMapsSymptomatic from './widgets/CDCMapsSymptomatic';
import moment from 'moment';
import Switch from 'react-switch';
import domtoimage from 'dom-to-image';

class MonitorAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.state = { checked: false, viewTotal: false };
    this.exportAsPNG = this.exportAsPNG.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
  }

  exportAsPNG() {
    var node = document.getElementById('sara-alert-body');
    domtoimage
      .toPng(node)
      .then(dataUrl => {
        var img = new Image();
        img.src = dataUrl;
        let link = document.createElement('a');
        let email = this.props.current_user.email;
        let currentDate = moment().format('YYYY_MM_DD');
        let imageName = `SaraAlert_Analytics_${email}_${currentDate}.png`;
        link.download = imageName;
        link.href = dataUrl;
        link.click();
      })
      .catch(error => {
        alert('An error occured.');
        console.error(error);
      });
  }

  toggleBetweenActiveAndTotal = viewTotal => this.setState({ viewTotal });

  render() {
    return (
      <React.Fragment>
        <Row className="mb-2 mx-0 px-0 pt-2">
          <Col md="24" className="mx-2 px-0">
            <Button variant="primary" className="btn-square" onClick={this.exportAsPNG}>
              <i className="fas fa-download"></i>&nbsp;&nbsp;EXPORT ANALYSIS AS PNG
            </Button>
            <p className="display-6 pt-3">Last Updated At: {moment(this.props.stats.last_updated_at).format('YYYY-MM-DD HH:mm:ss')} UTC</p>
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0">
          <Col md="14" className="ml-0 pl-0">
            <RiskStratificationTable stats={this.props.stats} />
          </Col>
          <Col md="10" className="mr-0 pr-0">
            <MonitoreeFlow stats={this.props.stats} />
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0 pt-4">
          <Col md="24" className="mx-0 px-0">
            <span className="display-5">Epidemiological Summary</span>
            <span className="float-right display-6">
              View Overall
              <Switch
                className="ml-2"
                onChange={this.toggleBetweenActiveAndTotal}
                onColor="#82A0E4"
                height={18}
                width={40}
                uncheckedIcon={false}
                checked={this.state.viewTotal}
              />
            </span>
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0">
          <Col md="12" className="ml-0 pl-0">
            <Demographics stats={this.props.stats} viewTotal={this.state.viewTotal} />
          </Col>
          <Col md="12" className="mr-0 pr-0">
            <RiskFactors stats={this.props.stats} viewTotal={this.state.viewTotal} />
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0">
          <Col md="24" className="mx-0 px-0">
            <MonitoreesByDateOfExposure stats={this.props.stats} />
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0 pt-4">
          <Col md="24" className="mx-0 px-0">
            <span className="display-5">Geographical Summary</span>
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0">
          <Col lg="12" md="24">
            <CDCMapsTotal stats={this.props.stats} />
          </Col>
          <Col lg="12" md="24">
            <CDCMapsSymptomatic stats={this.props.stats} />
          </Col>
        </Row>
      </React.Fragment>
    );
  }
}

MonitorAnalytics.propTypes = {
  stats: PropTypes.object,
  current_user: PropTypes.object,
};

export default MonitorAnalytics;
