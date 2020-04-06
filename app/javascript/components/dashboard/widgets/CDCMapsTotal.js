import React from 'react';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import { totalMonitoreesMap, stateOptions } from '../../data';
import CdcMap from 'cdc-map';
import 'cdc-map/build/static/css/index.css';

class CDCMapsTotal extends React.Component {
  constructor(props) {
    super(props);
    this.updateMapWithDay = this.updateMapWithDay.bind(this);
    this.monitoreesMap = _.cloneDeep(totalMonitoreesMap);
    this.selectedDateIndex = 0;
    this.state = {
      // All this does is translate`{'Kansas' : 5}` to `{'KA' : 5}` for all states
      mappedTotalPatientCountByStateAndDay: this.props.stats.total_patient_count_by_state_and_day.map(x => {
        let mappedValues = {};
        mappedValues['day'] = x.day;
        _.forIn(_.omit(x, 'day'), (value, key) => {
          let abbreviation = stateOptions.find(state => state.name === key)?.abbrv;
          if (abbreviation) {
            mappedValues[String(abbreviation)] = value;
          }
        });
        return mappedValues;
      }),
    };
    this.updateMapWithDay(0);
  }

  componentDidUpdate(prevProps) {
    if (this.props.selectedDate !== prevProps.selectedDate) {
      this.updateMapWithDay(this.props.selectedDate);
    }
  }

  updateMapWithDay(dateIndex) {
    let data = _.omit(this.state.mappedTotalPatientCountByStateAndDay[String(dateIndex)], 'day');
    this.monitoreesMap.data = [];
    stateOptions.forEach(stateName =>
      this.monitoreesMap.data.push({ State: stateName['abbrv'], Total: data[stateName['abbrv']] ? data[stateName['abbrv']] : 0 })
    );
    this.monitoreesMap.data.push({ State: null });
  }

  render() {
    return (
      <React.Fragment>
        <CdcMap key={this.props.selectedDate} config={this.monitoreesMap} />
      </React.Fragment>
    );
  }
}

CDCMapsTotal.propTypes = {
  stats: PropTypes.object,
  selectedDate: PropTypes.number,
};

export default CDCMapsTotal;
