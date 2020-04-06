import React from 'react';
import ReactDOM from 'react-dom';
import moment from 'moment';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import { totalMonitoreesMap, stateOptions } from '../../data';
import CdcMap from 'cdc-map';
import 'cdc-map/build/static/css/index.css';
import Slider from 'rc-slider/lib/Slider';
import 'rc-slider/assets/index.css';

class CDCMapsTotal extends React.Component {
  constructor(props) {
    super(props);
    this.renderSlider = this.renderSlider.bind(this);
    this.addSlider = this.addSlider.bind(this);
    this.updateMapWithDay = this.updateMapWithDay.bind(this);
    this.monitoreesMap = _.cloneDeep(totalMonitoreesMap);
    this.selectedDateIndex = 0;
    this.canChangeDate = true;
    this.firstUpdate = true; // the init logic locks the semaphore so we need a separate variable
    this.state = {
      // As far as I can tell, the CDC Map cannot have its data changed (it wont re-render and re-generate the colorschemes).
      // React will re-generate/render a component if its KEY is changed. So we use this boolean as a key, and flip it every time
      // we want to re-render the CDC Map
      updateKey: true,
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
  }

  getDateRange() {
    let retVal = {};
    this.state.mappedTotalPatientCountByStateAndDay.forEach((dayData, index) => {
      retVal[parseInt(index)] = moment(dayData.day).format('DD');
    });
    return retVal;
  }

  componentDidMount() {
    this.addSlider();
    setTimeout(() => {
      // Here's another oddity. I think comes from setState not being entirely synchronous
      // But a promise fails if this is called synchronously after this.addSlider()
      // So delay it by a neglible amount of time
      this.updateMapWithDay(0);
    }, 100);
  }

  componentDidUpdate() {
    // When the component updates, and the Map remounts, our HTML injection goes away
    // so we must re-inject the slider
    this.addSlider();
  }

  addSlider() {
    // This isnt the best way to do this, but because we dont have access to the CDC Maps component
    // we have to inject our component at an anchor point we create
    let newNode = document.createElement('div');
    newNode.innerHTML = '<div id="sliderTotal"> </div>';

    let referenceNode1 = document.querySelector('.total-cdc-map').querySelector('.map-container');
    referenceNode1.parentNode.insertBefore(newNode, referenceNode1.nextSibling);
    ReactDOM.render(this.renderSlider(), document.querySelector('#sliderTotal'));

    let referenceNode2 = document.querySelector('.total-cdc-map').querySelector('.full-container');
    referenceNode2.style.cssText = 'border: 1px solid #dedede';
  }

  updateMapWithDay(dateIndex) {
    // There was a wierd bug, where this function was getting called twice incorrectly (the second time, with the max value).
    // By using `canChangeDate` as a semaphore and locking/unlocking it in `onAfterChange`, that bug is fixed.
    // In theory, this semaphore should not be required, as the Slider should unmount and not call its own
    // onChange() function. But it is ¯\_(ツ)_/¯
    let highestValue = 0;
    if (this.canChangeDate) {
      this.selectedDateIndex = dateIndex;
      if (!this.firstUpdate) {
        this.canChangeDate = !this.canChangeDate;
      } else {
        this.firstUpdate = false;
      }
      let data2 = _.omit(this.state.mappedTotalPatientCountByStateAndDay[String(dateIndex)], 'day');
      this.monitoreesMap.data = this.monitoreesMap.data.map(x => {
        x['Total'] = Object.prototype.hasOwnProperty.call(data2, x.STATE) ? data2[String(x.STATE)] : 0;
        if (x['Total'] > highestValue) highestValue = x['Total'];
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
      this.setState({ updateKey: !this.state.updateKey });
    }
  }

  renderSlider() {
    const selectedDay = this.state.mappedTotalPatientCountByStateAndDay[parseInt(this.selectedDateIndex)].day;
    return (
      <div style={{ width: '50%', marginLeft: '25%' }}>
        <Slider
          max={this.state.mappedTotalPatientCountByStateAndDay.length - 1}
          marks={this.getDateRange()}
          defaultValue={0}
          value={this.selectedDateIndex}
          railStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
          trackStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
          handleStyle={{ border: '2px solid #595959', height: '15px', width: '15px', backgroundColor: 'white', marginTop: '-5px', marginLeft: '2px' }}
          dotStyle={{ border: '2px solid #333', backgroundColor: 'white' }}
          onChange={this.updateMapWithDay}
          onAfterChange={() => {
            this.canChangeDate = true;
          }}
        />
        <div className="mt-4 text-center font-weight-bold" style={{ fontSize: '20px' }}>
          {' '}
          {moment(selectedDay).format('MM - DD - YYYY')}
        </div>
      </div>
    );
  }

  render() {
    return (
      <React.Fragment>
        <div className="total-cdc-map">
          <CdcMap key={this.state.updateKey} config={this.monitoreesMap} />
        </div>
      </React.Fragment>
    );
  }
}

CDCMapsTotal.propTypes = {
  stats: PropTypes.object,
};

export default CDCMapsTotal;
