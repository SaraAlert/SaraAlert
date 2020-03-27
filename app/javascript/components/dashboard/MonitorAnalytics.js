import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button } from 'react-bootstrap';
import RiskStratificationTable from './widgets/RiskStratificationTable';
import MonitoreeFlow from './widgets/MonitoreeFlow';
import AgeStratification from './widgets/AgeStratification';
import Demographics from './widgets/Demographics';
import MonitoreesByDateOfExposure from './widgets/MonitoreesByDateOfExposure';
import RiskFactors from './widgets/RiskFactors';
import MapChart from './widgets/MapChart';
import CumulativeMapChart from './widgets/CumulativeMapChart';
import moment from 'moment';
import Switch from 'react-switch';
import domtoimage from 'dom-to-image';

class MonitorAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.state = { checked: false, viewTotal: false };
    this.handleClick = this.handleClick.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
  }

  handleClick() {
    var node = document.getElementById('sara-alert-body');
    domtoimage
      .toPng(node)
      .then(dataUrl => {
        if (confirm("Are you sure you'd like to download a screenshot of this page?")) {
          var img = new Image();
          img.src = dataUrl;
          let link = document.createElement('a');
          let jurisdiction = this.props.current_user.jurisdiction_path.join('_');
          let currentDate = moment().format('YYYY_MM_DD');
          let imageName = `SaraAlert_${jurisdiction}_${currentDate}.png`;
          link.download = imageName;
          link.href = dataUrl;
          link.click();
        }
      })
      .catch(function(error) {
        console.error(error);
      });
  }

  toggleBetweenActiveAndTotal = viewTotal => this.setState({ viewTotal });

  render() {
    return (
      <React.Fragment>
        <Row className="text-left mb-4">
          <Col xs="10">
            <Button variant="primary" className="ml-2 btn-square" onClick={this.handleClick}>
              EXPORT ANALYSIS AS PNG
            </Button>
          </Col>
          <Col xs="14" className="text-right">
            <h5 className="display-6 pt-3"> Last Updated At: {moment(this.props.stats.last_updated_at).format('YYYY-MM-DD HH:mm:ss')} UTC </h5>
          </Col>
        </Row>
        <Row className="mb-4">
          <Col lg="14" md="24">
            <RiskStratificationTable stats={this.props.stats} />
          </Col>
          <Col lg="10" md="24">
            <MonitoreeFlow stats={this.props.stats} />
          </Col>
        </Row>
        <div className="h2 mx-3">
          Epidemiological Summary
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
        </div>
        <Row className="mb-4">
          <Col lg="12" md="24" className="mb-4">
            <AgeStratification stats={this.props.stats} viewTotal={this.state.viewTotal} />
            <RiskFactors stats={this.props.stats} viewTotal={this.state.viewTotal} />
          </Col>
          <Col lg="12" md="24">
            <Demographics stats={this.props.stats} viewTotal={this.state.viewTotal} />
          </Col>
        </Row>
        <Row className="mb-4">
          <Col>
            <MonitoreesByDateOfExposure stats={this.props.stats} />
          </Col>
        </Row>
        <h2> Geographical Summary </h2>
        <Row className="mb-4">
          <Col lg="12" md="24" className="mb-4">
            <CumulativeMapChart stats={this.props.stats} />
          </Col>
          <Col lg="12" md="24">
            <MapChart stats={this.props.stats} />
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
