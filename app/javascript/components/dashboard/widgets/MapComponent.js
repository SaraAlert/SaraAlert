import React from 'react';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import { totalMonitoreesMap, symptomaticMonitoreesMap, stateOptions } from '../../data';
import CdcMap from 'cdc-map';
import 'cdc-map/build/static/css/index.css';

class MapComponent extends React.Component {
  constructor(props) {
    super(props);
    this.updateMapWithDay = this.updateMapWithDay.bind(this);
    this.monitoreesMap = this.props.variant === 'Total' ? _.cloneDeep(totalMonitoreesMap) : _.cloneDeep(symptomaticMonitoreesMap);
    this.selectedDateIndex = 0;

    this.state = {
      // All this does is translate`{'Kansas' : 5}` to `{'KA' : 5}` for all states
      mappedPatientsCountByStateAndDay: this.props.patientInfo.map(x => {
        let mappedValues = {};
        mappedValues['day'] = x.day;
        _.forIn(_.omit(x, 'day'), (value, key) => {
          let abbreviation = stateOptions.find(state => state.name === key)?.abbrv;
          if (abbreviation) {
            mappedValues[String(abbreviation)] = value;
          } else {
            if (!mappedValues['UKN']) {
              mappedValues['UKN'] = value;
            } else {
              mappedValues['UKN'] += value;
            }
          }
        });
        return mappedValues;
      }),
      updateKey: false, // a boolean that we will flip to force React to render the CDCMaps component
    };
    this.updateMapWithDay(0);
  }

  componentDidUpdate(prevProps) {
    if (this.props.selectedDate !== prevProps.selectedDate) {
      this.updateMapWithDay(this.props.selectedDate);
      this.setState({ updateKey: !this.state.updateKey });
    }
  }

  updateMapWithDay(dateIndex) {
    let data = _.omit(this.state.mappedPatientsCountByStateAndDay[String(dateIndex)], 'day');
    this.monitoreesMap.data = [];
    // Add "Unknown" in here so we can display on map but don't need to include it in state dropdowns
    stateOptions.push({ name: 'Unknown', abbrv: 'UKN' });
    stateOptions.forEach(stateName => {
      let newVal = { State: stateName['abbrv'] };
      newVal[this.props.variant] = data[stateName['abbrv']] ? data[stateName['abbrv']] : 0;
      this.monitoreesMap.data.push(newVal);
    });
    this.monitoreesMap.data.push({ State: null });

    let uniqueCount = _.uniq(this.monitoreesMap.data.map(x => x[`${this.props.variant}`]));
    uniqueCount = uniqueCount.filter(x => x).length;
    this.monitoreesMap.legend.numberOfItems = uniqueCount < 4 ? uniqueCount + 1 : 4;
  }

  render() {
    return (
      <React.Fragment>
        <CdcMap key={this.state.updateKey} config={this.monitoreesMap} />
      </React.Fragment>
    );
  }
}

MapComponent.propTypes = {
  patientInfo: PropTypes.array,
  variant: PropTypes.string, // Will be "Symptomatic" for the Symptomatic Map, and "Total" for the Total Map
  selectedDate: PropTypes.number,
};

export default MapComponent;
