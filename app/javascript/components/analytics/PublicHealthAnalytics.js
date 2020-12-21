import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button } from 'react-bootstrap';
import moment from 'moment-timezone';
import domtoimage from 'dom-to-image';
import Switch from 'react-switch';
import 'rc-slider/assets/index.css';
import ReactTooltip from 'react-tooltip';

import MonitoreeFlow from './widgets/MonitoreeFlow';
import Demographics from './widgets/Demographics';
import ExposureSummary from './widgets/ExposureSummary';
import PreferredReportingMethod from './widgets/PreferredReportingMethod';
import reportError from '../util/ReportError';
import MonitoreesByEventDate from './widgets/MonitoreesByEventDate';
import GeographicSummary from './widgets/GeographicSummary';

class PublicHealthAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.exportAsPNG = this.exportAsPNG.bind(this);
    this.state = {
      showEpidemiologicalGraphs: false,
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

  toggleEpidemiologicalGraphs = showEpidemiologicalGraphs => this.setState({ showEpidemiologicalGraphs });

  render() {
    if (this.state.hasErrors) {
      return (
        <div className="text-center mt-4" style={{ width: '100%' }}>
          <h1 className="sr-only">Analytics</h1>
          <div className="h5">We are still crunching the latest numbers.</div>
          <div className="h5">Please check back later...</div>
        </div>
      );
    } else {
      return (
        <React.Fragment>
          <h1 className="sr-only">Analytics</h1>
          <Row className="mx-0 px-0 mt-1 mb-4 ">
            <Col className="mx-2 px-0">
              <div className="display-6">
                <div style={{ display: 'inline' }}>
                  <span data-for="analytics-refresh" data-tip="" className="ml-1">
                    <i className="fas fa-info-circle mr-1 px-0"></i>
                  </span>
                  <ReactTooltip id="analytics-refresh" multiline={true} place="right" effect="solid" className="tooltip-container">
                    <div className="font-weight-bold p-2">
                      The data on this page refreshes once a day. Therefore, any changes to records throughout the day will not be reflected on this page until
                      it is refreshed around 12:00 midnight EST.
                    </div>
                  </ReactTooltip>
                </div>
                Last Updated At{' '}
                {moment
                  .tz(this.props.stats.last_updated_at, 'UTC')
                  .tz(moment.tz.guess())
                  .format('YYYY-MM-DD HH:mm z')}
                .
              </div>
            </Col>
            <Col className="mx-2 px-0 text-right">
              <Button variant="primary" className="btn-square export-png" onClick={this.exportAsPNG}>
                <i className="fas fa-download"></i>&nbsp;&nbsp;EXPORT ANALYSIS AS PNG
              </Button>
            </Col>
          </Row>
          <Row className="mb-4 mx-2 px-0">
            <Col xl="14" lg="24" sm="24" className="mx-0 pr-xl-3">
              <PreferredReportingMethod stats={this.props.stats} />
            </Col>
            <Col xl="10" lg="24" sm="24" className="mx-0 mt-5 mt-xl-0 pl-xl-3">
              <MonitoreeFlow stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mx-2 mt-2 px-0">
            <Col xs="20">
              <span className="display-5">Epidemiological Summary</span>
            </Col>
            <Col xs="4">
              <span className="float-right">
                <Switch
                  className="ml-2 mt-4 custom-react-switch"
                  onChange={this.toggleEpidemiologicalGraphs}
                  onColor="#557385"
                  height={30}
                  width={80}
                  uncheckedIcon={false}
                  checked={this.state.showEpidemiologicalGraphs}
                />
              </span>
            </Col>
          </Row>
          <Row className="mb-4 mx-1 px-0">
            <Col xs="16">
              <h5 className="text-secondary">Among Those Currently Under Active Monitoring</h5>
            </Col>
            <Col xs="8">
              <h5 className="float-right text-secondary">View Data as Graph</h5>
            </Col>
          </Row>
          <Row className="mb-4 mx-1 px-0">
            <Col className="mx-0 pr-xl-3">
              <Demographics stats={this.props.stats} showGraphs={this.state.showEpidemiologicalGraphs} />
            </Col>
          </Row>
          <Row className="mb-4 mt-4 pt-3 mx-1 px-0">
            <Col className="mx-0 pr-xl-3">
              <ExposureSummary stats={this.props.stats} showGraphs={this.state.showEpidemiologicalGraphs} />
            </Col>
          </Row>
          <Row className="mb-2 pt-4 mx-1 px-0">
            <Col className="mx-0 pr-xl-3">
              <MonitoreesByEventDate stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mb-5 pb-3 mx-1 px-0 pt-4">
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
