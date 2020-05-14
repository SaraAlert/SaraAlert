import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Button, Card } from 'react-bootstrap';
import RiskStratificationTable from './widgets/RiskStratificationTable';
import MonitoreeFlow from './widgets/MonitoreeFlow';
import Demographics from './widgets/Demographics';
import RiskFactors from './widgets/RiskFactors';
import MonitoreesByDateOfExposure from './widgets/MonitoreesByDateOfExposure';
import MapComponent from './widgets/MapComponent';
import moment from 'moment';
import Slider from 'rc-slider/lib/Slider';
import 'rc-slider/assets/index.css';
import domtoimage from 'dom-to-image';

class MonitorAnalytics extends React.Component {
  constructor(props) {
    super(props);
    this.exportAsPNG = this.exportAsPNG.bind(this);
    this.getDateRange = this.getDateRange.bind(this);
    this.handleDateRangeChange = this.handleDateRangeChange.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
    this.dateRange = this.getDateRange();
    this.state = {
      checked: false,
      viewTotal: false,
      selectedDateIndex: 0,
    };
  }

  getDateRange() {
    let retVal = {};
    let dates = this.props.stats.total_patient_count_by_state_and_day.map(x => x.day);
    dates.forEach((day, index) => {
      retVal[parseInt(index)] = moment(day).format('MM/DD');
    });
    return retVal;
  }

  handleDateRangeChange(value) {
    this.setState({ selectedDateIndex: value });
  }

  exportAsPNG() {
    // The two datatables in the cdc-maps cause the export to fail
    // remove them before the export then reload the page so that they come back
    document.getElementsByClassName('data-table')[0].outerHTML = '';
    document.getElementsByClassName('data-table')[0].outerHTML = '';
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
        location.reload();
      })
      .catch(error => {
        alert('An error occured.');
        console.error(error);
        location.reload();
      });
  }

  toggleBetweenActiveAndTotal = viewTotal => this.setState({ viewTotal });

  render() {
    const selectedDay = this.props.stats.total_patient_count_by_state_and_day[parseInt(this.state.selectedDateIndex)].day;
    return (
      <React.Fragment>
        <Row className="mb-2 mx-0 px-0 pt-2">
          <Col md="24" className="mx-2 px-0">
            <Button variant="primary" className="btn-square" onClick={this.exportAsPNG}>
              <i className="fas fa-download"></i>&nbsp;&nbsp;EXPORT ANALYSIS AS PNG
            </Button>
          </Col>
        </Row>
        <Row className="mb-2 mx-0 px-0 pt-4 pb-2">
          <Col md="24" className="mx-2 px-0">
            <p className="display-6">
              <i className="fas fa-info-circle mr-1"></i> Analytics are generated using data from both exposure and isolation workflows. Last Updated At{' '}
              {moment(this.props.stats.last_updated_at).format('YYYY-MM-DD HH:mm:ss')} UTC.
            </p>
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
        <Row className="mb-4 mx-2 px-0">
          <Col md="24" className="mx-0 px-0">
            <MonitoreesByDateOfExposure stats={this.props.stats} />
          </Col>
        </Row>
        <Row className="mb-4 mx-2 px-0 pt-4">
          <Col md="24" className="mx-0 px-0">
            <span className="display-5">Geographic Summary</span>
            <Card className="card-square mt-4">
              <Card.Header as="h5">Maps</Card.Header>
              <Card.Body>
                <Row className="mb-4 mx-2 px-0">
                  <Col md="24">
                    <div className="text-center display-5 mb-1 mt-1 pb-4">{moment(selectedDay).format('MMMM DD, YYYY')}</div>
                    <div className="mx-5 mb-4 pb-2">
                      <Slider
                        max={this.props.stats.total_patient_count_by_state_and_day.length - 1}
                        marks={this.dateRange}
                        railStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
                        trackStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
                        handleStyle={{ borderColor: '#595959', backgroundColor: 'white' }}
                        dotStyle={{ borderColor: '#333', backgroundColor: 'white' }}
                        onChange={this.handleDateRangeChange}
                      />
                    </div>
                  </Col>
                </Row>
                <Row className="mb-4 mx-2 px-0">
                  <Col>
                    <MapComponent
                      selectedDate={this.state.selectedDateIndex}
                      variant="Total"
                      patientInfo={this.props.stats.total_patient_count_by_state_and_day}
                    />
                  </Col>
                  <Col>
                    <MapComponent
                      selectedDate={this.state.selectedDateIndex}
                      variant="Symptomatic"
                      patientInfo={this.props.stats.symptomatic_patient_count_by_state_and_day}
                    />
                  </Col>
                </Row>
              </Card.Body>
            </Card>
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
