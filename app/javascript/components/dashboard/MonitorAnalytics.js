import React from 'react';
import { Row, Col, Button } from 'react-bootstrap';
import SystemStatisticsPie from './widgets/SystemStatisticsPie';
import moment from 'moment';
import MonitoringDistributionDay from './widgets/MonitoringDistributionDay';
// import AssessmentsDay from './widgets/AssessmentsDay';
import { PropTypes } from 'prop-types';
import MapChart from './widgets/MapChart';
import CumulativeMapChart from './widgets/CumulativeMapChart';
import CasesOverTime from './widgets/CasesOverTime';
import domtoimage from 'dom-to-image';

class MonitorAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.handleClick = this.handleClick.bind(this);
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
  render() {
    return (
      <React.Fragment>
        <Row className="text-left mb-3">
          <Col md="24">
            <Button variant="primary" className="ml-2 btn-square" onClick={this.handleClick}>
              EXPORT ANALYSIS AS PNG
            </Button>
          </Col>
          <Col md="24" className="mx-2 my-4">
            <h5>Last Updated At: {this.props.stats.last_updated_at}</h5>
          </Col>
        </Row>
        <div className="mx-2 pb-4">
          <Row>
            <Col md="12">
              <Row>
                <Col md="24">
                  <SystemStatisticsPie stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">
                  <CasesOverTime stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">
                  <MonitoringDistributionDay stats={this.props.stats} />
                </Col>
              </Row>
            </Col>
            <Col md="12">
              <Row>
                <Col md="24">
                  <CumulativeMapChart stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">
                  <MapChart stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">{/* <AssessmentsDay stats={this.props.stats} /> */}</Col>
              </Row>
            </Col>
          </Row>
        </div>
        <div className="pb-2"></div>
      </React.Fragment>
    );
  }
}

MonitorAnalytics.propTypes = {
  stats: PropTypes.object,
  current_user: PropTypes.object,
};

export default MonitorAnalytics;
