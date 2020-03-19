import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button } from 'react-bootstrap';
import RiskStratificationTable from './widgets/RevisedDashboard/RiskStratificationTable';
import MonitoreeFlow from './widgets/RevisedDashboard/MonitoreeFlow';
import AgeStratificationActive from './widgets/RevisedDashboard/AgeStratificationActive';
// import AgeStratificationTotal from './widgets/RevisedDashboard/AgeStratificationTotal';
import moment from 'moment';
import domtoimage from 'dom-to-image';

class RevisedMonitorAnalytics extends React.Component {
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
          let img = new Image();
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
      .catch(error => {
        console.error(error);
      });
  }
  render() {
    return (
      <React.Fragment>
        <Row className="text-left mb-4">
          <Col>
            <Button variant="primary" className="ml-2 btn-square" onClick={this.handleClick}>
              EXPORT ANALYSIS AS PNG
            </Button>
          </Col>
          <Col className="text-right">
            <span className="display-6 pt-3"> Last Updated At: {moment(this.props.stats.last_updated_at).format('YYYY-MM-DD HH:mm:ss')} </span>
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
        <h2> Epidemiological Summary </h2>
        <Row className="mb-4">
          <Col lg="14" md="24">
            <AgeStratificationActive stats={this.props.stats} />
          </Col>
          {/* <Col lg="12" md="24"> */}
          {/* <AgeStratificationTotal stats={this.props.stats} /> */}
          {/* </Col> */}
        </Row>
      </React.Fragment>
    );
  }
}

RevisedMonitorAnalytics.propTypes = {
  stats: PropTypes.object,
  current_user: PropTypes.object,
};

export default RevisedMonitorAnalytics;
