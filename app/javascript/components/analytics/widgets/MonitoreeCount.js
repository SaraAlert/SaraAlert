import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import _ from 'lodash';

class MonitoreeCount extends React.Component {
  constructor(props) {
    super(props);
    let totalSymptomaticToday = 0;
    let totalMonitoreesToday = 0;
    let totalSymptomaticYesterday = 0;
    let totalMonitoreesYesterday = 0;
    let symptomaticRef = this.props.stats.symptomatic_patient_count_by_state_and_day;
    let totalRef = this.props.stats.total_patient_count_by_state_and_day;
    _.valuesIn(_.omit(_.last(symptomaticRef), 'day')).forEach(x => (totalSymptomaticToday += x));
    _.valuesIn(_.omit(_.last(totalRef), 'day')).forEach(x => (totalMonitoreesToday += x));
    _.valuesIn(_.omit(symptomaticRef[symptomaticRef.length - 2], 'day')).forEach(x => (totalSymptomaticYesterday += x));
    _.valuesIn(_.omit(totalRef[totalRef.length - 2], 'day')).forEach(x => (totalMonitoreesYesterday += x));
    this.state = {
      system_symptomatic_today: totalSymptomaticToday,
      system_total_monitorees_today: totalMonitoreesToday,
      percentSymptomaticToday: ((totalSymptomaticToday / totalMonitoreesToday) * 100).toFixed(2),
      system_symptomatic_yesterday: totalSymptomaticYesterday,
      system_total_monitorees_yesterday: totalMonitoreesYesterday,
    };
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header className="text-left h5">System Statistics</Card.Header>
          <Card.Body>
            <div className="display-6">
              {' '}
              <u> Symptomatic Monitorees </u>{' '}
            </div>
            <div style={{ textAlign: 'center' }} className="text-center display-5 mt-3">
              {this.state.system_symptomatic_today}
              <span className="display-5 text-secondary"> / </span>
              {this.state.system_total_monitorees_today}
            </div>
            <div className="display-6 text-secondary"> ({this.state.percentSymptomaticToday}%) </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoreeCount.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreeCount;
