import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button } from 'react-bootstrap';
import moment from 'moment-timezone';
import domtoimage from 'dom-to-image';
import 'rc-slider/assets/index.css';

import RiskStratificationTable from './widgets/RiskStratificationTable';
import MonitoreeFlow from './widgets/MonitoreeFlow';
import Demographics from './widgets/Demographics';
import RiskFactors from './widgets/RiskFactors';
import PreferredReportingMethod from './widgets/PreferredReportingMethod';
import reportError from '../util/ReportError';
import MonitoreesByDateOfExposure from './widgets/MonitoreesByDateOfExposure';
import GeographicSummary from './widgets/GeographicSummary';

class PublicHealthAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.exportAsPNG = this.exportAsPNG.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
    this.state = {
      checked: false,
      viewTotal: false,
      hasErrors: !this.props.stats || Object.entries(this.props.stats).length === 0,
    };
  }

  exportAsPNG() {
    if (window.document.documentMode) {
      alert(
        'Analytics export is not availale using the Internet Explorer web browser. Please use an alternative browser or a local image capture application instead.'
      );
    } else {
      var node = document.getElementById('sara-alert-body');
      domtoimage
        .toPng(node)
        .then(dataUrl => {
          let img = new Image();
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
          reportError(error);
        });
    }
  }

  toggleBetweenActiveAndTotal = viewTotal => this.setState({ viewTotal });

  render() {
    if (this.state.hasErrors) {
      return (
        <div className="text-center mt-4" style={{ width: '100%' }}>
          <h5>We are still crunching the latest numbers.</h5>
          <h5>Please check back later...</h5>
        </div>
      );
    } else {
      return (
        <React.Fragment>
          <Row className="mb-2 mx-0 px-0 pt-2">
            <Col md="24" className="mx-2 px-0">
              <Button variant="primary" className="btn-square export-png" onClick={this.exportAsPNG}>
                <i className="fas fa-download"></i>&nbsp;&nbsp;EXPORT ANALYSIS AS PNG
              </Button>
            </Col>
          </Row>
          <Row className="mb-2 mx-0 px-0 pt-4 pb-2">
            <Col md="24" className="mx-2 px-0">
              <p className="display-6">
                <i className="fas fa-info-circle mr-1"></i> Analytics are generated using data from both exposure and isolation workflows. Last Updated At{' '}
                {moment
                  .tz(this.props.stats.last_updated_at, 'UTC')
                  .tz(moment.tz.guess())
                  .format('YYYY-MM-DD HH:mm z')}
                .
              </p>
            </Col>
          </Row>
          <Row className="mb-4 mx-2 px-0">
            <Col xl="14" lg="24" sm="24" className="mx-0 pr-xl-3">
              <PreferredReportingMethod stats={this.props.stats} />
            </Col>
            <Col xl="10" lg="24" sm="24" className="mx-0 pl-xl-3">
              <MonitoreeFlow stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mb-4 mx-2 px-0 pt-4">
            <Col md="24" className="mx-0 px-0">
              <span className="display-5">Epidemiological Summary</span>
              {/* <span className="float-right display-6">
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
              </span> */}
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
          <Row className="mb-1 mx-2 px-0">
            <Col md="24" className="mx-0 px-0">
              <MonitoreesByDateOfExposure stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mb-5 pb-3 mx-2 px-0 pt-4">
            <GeographicSummary stats={this.props.stats} />
          </Row>
        </React.Fragment>
      );
    }
  }
}

PublicHealthAnalytics.propTypes = {
  stats: PropTypes.object,
  current_user: PropTypes.object,
};

export default PublicHealthAnalytics;
