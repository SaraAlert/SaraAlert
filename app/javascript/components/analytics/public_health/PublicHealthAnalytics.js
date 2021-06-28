import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Row } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import moment from 'moment-timezone';
import domtoimage from 'dom-to-image';
import Switch from 'react-switch';
import 'rc-slider/assets/index.css';

import MonitoreeFlow from './charts/MonitoreeFlow';
import Demographics from './charts/Demographics';
import ExposureSummary from './charts/ExposureSummary';
import PreferredReportingMethod from './charts/PreferredReportingMethod';
import MonitoreesByEventDate from './charts/MonitoreesByEventDate';
import GeographicSummary from './charts/GeographicSummary';
import reportError from '../../util/ReportError';
import { formatTimestamp } from '../../../utils/DateTime';

class PublicHealthAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      showEpidemiologicalGraphs: false,
      hasErrors: !this.props.stats || Object.entries(this.props.stats).length === 0,
    };
  }

  handleClick = () => {
    this.setState({ loading: true }, () => {
      this.exportAsPNG();
    });
  };

  exportAsPNG = () => {
    if (window.document.documentMode) {
      alert(
        'Analytics export is not availale using the Internet Explorer web browser. Please use an alternative browser or a local image capture application instead.'
      );
    } else {
      var node = document.getElementById('sara-alert-body');
      let isDemo = false;
      if (node?.className === 'demo-bg') {
        node.className = '';
        isDemo = true;
      }
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
          this.setState({ loading: false });
          if (isDemo) {
            node.className = 'demo-bg';
          }
        })
        .catch(error => {
          reportError(error);
        });
    }
  };

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
          <Row className="mx-2">
            <Col className="align-self-center mb-3">
              <div className="display-6">
                <div style={{ display: 'inline' }}>
                  <span data-for="analytics-refresh" data-tip="">
                    <i className="fas fa-info-circle mr-2"></i>
                  </span>
                  <ReactTooltip id="analytics-refresh" multiline={true} place="right" effect="solid" className="tooltip-container">
                    <div className="font-weight-bold">
                      The data on this page refreshes once a day. Therefore, any changes to records throughout the day will not be reflected on this page until
                      it is refreshed around 12:00 midnight EST.
                    </div>
                  </ReactTooltip>
                </div>
                Last Updated At {formatTimestamp(this.props.stats.last_updated_at)}.
              </div>
            </Col>
            <Col sm="24" md="auto" className="text-right mb-3">
              <Button variant="primary" className="btn-square export-png" disabled={this.state.loading} onClick={this.handleClick}>
                <i className="fas fa-download"></i>&nbsp;&nbsp;EXPORT ANALYSIS AS PNG&nbsp;&nbsp;
                {this.state.loading && (
                  <React.Fragment>
                    <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                  </React.Fragment>
                )}
              </Button>
            </Col>
          </Row>
          <Row className="mx-2">
            <Col className="mx-0 my-3">
              <PreferredReportingMethod stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mx-2">
            <Col className="mx-0 my-3">
              <MonitoreeFlow stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mx-2 my-1">
            <Col xs="20">
              <span className="display-5">Epidemiological Summary</span>
            </Col>
            <Col xs="4" className="align-self-end">
              <span className="float-right">
                <Switch
                  id="epidemiological-graph-switch"
                  className="custom-react-switch"
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
          <Row className="mx-2 mb-2">
            <Col xs="16">
              <label htmlFor="epidemiological-graph-switch" className="h5 text-secondary">
                Among Those Currently Under Active Monitoring
              </label>
            </Col>
            <Col xs="8">
              <span className="h5 float-right text-secondary">View Data as Graph</span>
            </Col>
          </Row>
          <Row className="mx-2">
            <Col className="mx-0 my-3">
              <Demographics stats={this.props.stats} showGraphs={this.state.showEpidemiologicalGraphs} />
            </Col>
          </Row>
          <Row className="mx-2">
            <Col className="mx-0 my-3">
              <ExposureSummary stats={this.props.stats} showGraphs={this.state.showEpidemiologicalGraphs} />
            </Col>
          </Row>
          <Row className="mx-2">
            <Col className="mx-0 my-3">
              <MonitoreesByEventDate stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="mx-2">
            <Col className="mx-0 my-3">
              <GeographicSummary stats={this.props.stats} />
            </Col>
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
