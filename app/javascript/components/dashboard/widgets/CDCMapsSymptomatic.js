import React from 'react';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import { symptomaticMonitoreesMap, stateOptions } from '../../data';
import CdcMap from 'cdc-map';
import 'cdc-map/build/static/css/index.css';

class CDCMapsSymptomatic extends React.Component {
  constructor(props) {
    super(props);
    this.updateMapWithDay = this.updateMapWithDay.bind(this);
    this.monitoreesMap = _.cloneDeep(symptomaticMonitoreesMap);
    this.selectedDateIndex = 0;
    this.state = {
      // All this does is translate`{'Kansas' : 5}` to `{'KA' : 5}` for all states
      mappedSymptomaticPatientCountByStateAndDay: this.props.stats.symptomatic_patient_count_by_state_and_day.map(x => {
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
    let highestValue = 0;

    let data = _.omit(this.state.mappedSymptomaticPatientCountByStateAndDay[String(dateIndex)], 'day');
    this.monitoreesMap.data = this.monitoreesMap.data.map(x => {
      x['Symptomatic'] = Object.prototype.hasOwnProperty.call(data, x.STATE) ? data[String(x.STATE)] : 0;
      if (x['Symptomatic'] > highestValue) highestValue = x['Symptomatic'];
      return x;
    });
    // These are pretty much arbitrary and can (maybe should) be changed
    // (They count the number of entries in the legend)
    if (highestValue <= 1) {
      this.monitoreesMap.legend.numberOfItems = 1;
    } else if (highestValue < 10) {
      this.monitoreesMap.legend.numberOfItems = 2;
    } else if (highestValue < 30) {
      this.monitoreesMap.legend.numberOfItems = 3;
    } else {
      this.monitoreesMap.legend.numberOfItems = 4;
    }
  }

  render() {
    return (
      <React.Fragment>
        <CdcMap key={this.props.selectedDate} config={this.monitoreesMap} />
      </React.Fragment>
    );
  }
}

CDCMapsSymptomatic.propTypes = {
  stats: PropTypes.object,
  selectedDate: PropTypes.number,
};

export default CDCMapsSymptomatic;
