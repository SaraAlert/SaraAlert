import React from 'react';
import axios from 'axios';
import _ from 'lodash';
import { PropTypes } from 'prop-types';
import { Row, Col, Button, DropdownButton, Dropdown } from 'react-bootstrap';
import moment from 'moment';
import Slider from 'rc-slider/lib/Slider';
import 'rc-slider/assets/index.css';
import { stateOptions, customTerritories } from '../../data';
import CountyLevelMaps from './CountyLevelMaps';

const MAX_DAYS_OF_HISTORY = 10; // only allow the user to scrub back N days from today
const INITIAL_SELECTED_DATE_INDEX = 0; // Maybe at some point, we would want to show the latest day initially
const STATES_NOT_IN_USE = [];

class GeographicSummary extends React.Component {
  constructor(props) {
    super(props);
    // We will load each state individually, as required, but the data for the entire country is always loaded
    // omit `day` from these, because they index-match the `dateSubset`. Makes parsing easier later (no need to remove the `day` flag)
    this.totalFullCountryDataByStateAndDay = _.takeRight(this.props.stats.total_patient_count_by_state_and_day, MAX_DAYS_OF_HISTORY).map(x => _.omit(x, 'day'));
    this.symptomaticFullCountryDataByStateAndDay = _.takeRight(this.props.stats.symptomatic_patient_count_by_state_and_day, MAX_DAYS_OF_HISTORY).map(x =>
      _.omit(x, 'day')
    );

    let statesInUse = _.uniq(_.flatten(this.totalFullCountryDataByStateAndDay.map(x => Object.keys(_.omit(x, 'day')))));
    stateOptions.map(state => {
      if (!statesInUse.includes(state.name)) {
        STATES_NOT_IN_USE.push(`US-${state.abbrv}`);
      }
    });

    this.state = {
      selectedDateIndex: INITIAL_SELECTED_DATE_INDEX,
      showBackButton: false,
      jurisdictionToShow: {
        category: 'fullCountry',
        name: 'USA',
        eventValue: null,
      },
      mapObject: null,
      showSpinner: false,
      totalJurisdictionData: this.totalFullCountryDataByStateAndDay[Number(INITIAL_SELECTED_DATE_INDEX)],
      symptomaticJurisdictionData: this.symptomaticFullCountryDataByStateAndDay[Number(INITIAL_SELECTED_DATE_INDEX)],
    };

    // A lot of times, the CountyLevelMaps functions will take time to render some new jurisdiction map.
    // We want the Spinner to spin until they report back that they're done. Therefore, we set spinnerState to 2
    // and subtract 1 every time they report back. When they each report back, 2 - 1 - 1 = 0 then we set `showSpinner` to false
    // Because calls to setState are asynchronous, this value must be on the component itself
    this.spinnerState = 0;

    this.dateSubset = _.takeRight(this.props.stats.total_patient_count_by_state_and_day, MAX_DAYS_OF_HISTORY);
    this.dateRange = this.getDateRange();
    console.log(this.props.stats);
  }

  decrementSpinnerCount = () => {
    console.log(`decrement ${this.spinnerState}`);
    if (this.spinnerState > 0) {
      if (this.spinnerState === 1) {
        this.setState({
          showSpinner: false,
        });
        this.spinnerState = 0;
      } else {
        this.spinnerState--;
      }
    }
  };

  renderSpinner = () =>
    this.state.showSpinner ? (
      <div className="county-maps-loading">
        <span className="fa-stack fa-2x">
          <i className="fas fa-circle fa-stack-2x" style={{ color: '#305473' }}></i>
          <i className="fas fa-spinner fa-spin fa-stack-1x fa-inverse"></i>
        </span>
      </div>
    ) : null;

  getDateRange = () => {
    let retVal = {};
    let dates = this.dateSubset.map(x => x.day);
    dates.forEach((day, index) => {
      retVal[parseInt(index)] = moment(day).format('MM/DD');
    });
    return retVal;
  };

  handleDateRangeChange = value => {
    if (this.state.jurisdictionToShow.category === 'fullCountry') {
      (this.spinnerState = 2),
        this.setState(
          {
            selectedDateIndex: value,
            showSpinner: true,
          },
          () => {
            // The CountyLevelMaps components hang when re-rendering, so we first want to
            // show the spinner and update the date value to provide responsive UI
            setTimeout(() => {
              this.setState({
                totalJurisdictionData: this.totalFullCountryDataByStateAndDay[Number(value)],
                symptomaticJurisdictionData: this.symptomaticFullCountryDataByStateAndDay[Number(value)],
              });
            }, 25);
          }
        );
    } else if (this.state.jurisdictionToShow.category === 'state') {
      (this.spinnerState = 2),
        this.setState(
          {
            selectedDateIndex: value,
          },
          () => {
            console.log('I need to make a request for STATE DATA');
          }
        );
    } else if (this.state.jurisdictionToShow.category === 'territory') {
      console.log('Need to make a request for a TERRITORY DATA');
    } else {
      console.error('THIS SHOULD NEVER HAPPEN');
    }
  };

  backToFullCountryMap = () => {
    this.spinnerState = 2;
    this.setState(
      {
        showSpinner: true,
      },
      () => {
        this.handleJurisdictionChange('USA');
      }
    );
  };

  handleJurisdictionChange = jurisdiction => {
    console.log(`GeographicSummary: handleJurisdictionChange`);
    this.spinnerState = 2;
    if (jurisdiction === 'USA') {
      this.setState({
        showBackButton: false,
        jurisdictionToShow: {
          category: 'fullCountry',
          name: 'USA',
          eventValue: null,
        },
        totalJurisdictionData: this.totalFullCountryDataByStateAndDay[this.state.selectedDateIndex],
        symptomaticJurisdictionData: this.symptomaticFullCountryDataByStateAndDay[this.state.selectedDateIndex],
        mapObject: null,
      });
    } else if (_.some(customTerritories, c => _.isEqual(c, jurisdiction))) {
      // THIS IS TERRITORY CODE
      this.setState({ showBackButton: true, showSpinner: true });
      console.log(`Loading: ${jurisdiction} mapFile`);
      this.loadJurisdictionData(jurisdiction.mapFile, jurisdiction.name, jurisdictionData => {
        this.setState({
          showBackButton: true,
          jurisdictionToShow: {
            category: 'territory',
            name: jurisdiction.name,
            eventValue: null,
          },
          totalJurisdictionData: jurisdictionData.totalJurisdictionData,
          symptomaticJurisdictionData: jurisdictionData.symptomaticJurisdictionData,
          mapObject: jurisdictionData.mapObject,
        });
      });
    } else {
      // THIS IS STATE CODE
      this.setState({ showBackButton: true, showSpinner: true });
      console.log(`Loading: ${jurisdiction.target.dataItem.dataContext.map} mapFile`);
      this.loadJurisdictionData(jurisdiction.target.dataItem.dataContext.map, jurisdiction.target.dataItem.dataContext.name, jurisdictionData => {
        this.setState({
          showBackButton: true,
          jurisdictionToShow: {
            category: 'state',
            name: jurisdiction.target.dataItem.dataContext.name,
            eventValue: jurisdiction, // this is actually an eventObject from am4Charts
          },
          totalJurisdictionData: jurisdictionData.totalJurisdictionData,
          symptomaticJurisdictionData: jurisdictionData.symptomaticJurisdictionData,
          mapObject: jurisdictionData.mapObject,
        });
      });
    }
  };

  loadJurisdictionData = async (jurisdictionFileName, jurisdictionName, callback) => {
    console.log(`GeographicSummary: loadJurisdictionData`);
    const loadJurisdictionMapData = () => axios.get(`${window.location.origin}/county_level_maps/${jurisdictionFileName}`).then(res => res.data);
    // IS THIS EVEN THE CORRECT WAY TO USE MULTIPLE GET Parameters? Should it be ?val1=x&val2=y
    // TODO later
    const loadJurisdictionMonitoreeData = () =>
      axios.get(`${window.location.origin}/county_level_data/${jurisdictionName}/${this.state.selectedDateIndex}`).then(res => res.data);

    const [jurisdictionMapData, jurisdictionMonitoreeData] = await Promise.all([loadJurisdictionMapData(), loadJurisdictionMonitoreeData()]);

    callback({
      mapObject: jurisdictionMapData,
      totalJurisdictionData: jurisdictionMonitoreeData.total,
      symptomaticJurisdictionData: jurisdictionMonitoreeData.symptomatic,
    });
  };

  render() {
    console.log('GeographicSummary - render');
    let backButton = this.state.showBackButton && (
      <Button variant="primary" size="md" className="ml-auto btn-square" onClick={() => this.backToFullCountryMap()}>
        <i className="fas fa-arrow-left mr-2"> </i>
        Back to Country View
      </Button>
    );
    return (
      <div style={{ width: '100%' }}>
        <Row className="mb-4 mx-2 px-0">
          <Col md="24">
            <div className="text-center display-5 mb-1 mt-1 pb-4">{moment(this.dateSubset[this.state.selectedDateIndex].day).format('MMMM DD, YYYY')}</div>
            <div className="mx-5 mb-4 pb-2">
              <Slider
                max={MAX_DAYS_OF_HISTORY - 1}
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
        <div style={{ width: '100%', height: '450px' }}>
          <div className="map-panel-mount-point">
            {this.renderSpinner()}
            <Row>
              <Col md="12" className="pr-0">
                <div className="map-title text-center">All Monitorees By Location Over Time</div>
                <CountyLevelMaps
                  style={{ borderRight: '1px solid #dcdcdc' }}
                  jurisdictionToShow={this.state.jurisdictionToShow}
                  jurisdictionData={this.state.totalJurisdictionData}
                  mapObject={this.state.mapObject}
                  handleJurisdictionChange={this.handleJurisdictionChange}
                  decrementSpinnerCount={this.decrementSpinnerCount}
                  statesNotInUse={STATES_NOT_IN_USE}
                />
              </Col>
              <Col md="12" className="pl-0">
                <div className="map-title text-center">Symptomatic Monitorees By Location Over Time</div>
                <CountyLevelMaps
                  jurisdictionToShow={this.state.jurisdictionToShow}
                  jurisdictionData={this.state.symptomaticJurisdictionData}
                  mapObject={this.state.mapObject}
                  handleJurisdictionChange={this.handleJurisdictionChange}
                  decrementSpinnerCount={this.decrementSpinnerCount}
                  statesNotInUse={STATES_NOT_IN_USE}
                />
              </Col>
            </Row>
          </div>
          {/* <CountyLevelMaps
            monitoreeInfo={this.props.stats.total_patient_count_by_state_and_day}
            selectedDateIndex={this.state.selectedDateIndex}
            showBackButton={this.state.showBackButton}
          />
          <CountyLevelMaps
            monitoreeInfo={this.props.stats.symptomatic_patient_count_by_state_and_day}
            selectedDateIndex={this.state.selectedDateIndex}
            showBackButton={this.state.showBackButton}
          /> */}
          <Row className="mx-0 map-panel-controls">
            <DropdownButton variant="primary" size="md" drop="up" className="mr-auto btn-square" title="View Other Jurisdiction">
              {customTerritories.map((territory, index) => (
                <Dropdown.Item key={index} onClick={() => this.handleJurisdictionChange(territory)}>
                  {territory.name}
                </Dropdown.Item>
              ))}
            </DropdownButton>
            {backButton}
          </Row>
        </div>
      </div>
    );
  }
}

GeographicSummary.propTypes = {
  stats: PropTypes.object,
};

export default GeographicSummary;
