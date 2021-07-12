import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Row, Table } from 'react-bootstrap';
import Slider from 'rc-slider/lib/Slider';
import 'rc-slider/assets/index.css';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import { insularAreas } from '../maps/mapData';
import { stateOptions } from '../../../../data/stateOptions';
import CountyLevelMaps from '../maps/CountyLevelMaps';

const TERRITORY_GEOJSON_FILE = 'usaTerritories.json';

class GeographicSummary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { loading: true };
  }

  componentDidMount() {
    axios.get('/analytics/monitoree_maps').then(response => {
      const maxDaysOfHistory = response.data.monitoree_maps.length;
      const selectedDateIndex = maxDaysOfHistory - 1;
      const analyticsData = this.parseAnalyticsStatistics(response.data.monitoree_maps, maxDaysOfHistory);
      if (analyticsData.exposure[Number(selectedDateIndex)]) {
        this.setState({
          analyticsData,
          jurisdictionsPermittedToView: this.obtainJurisdictionsPermittedToView(response.data.monitoree_maps, maxDaysOfHistory),
          jurisdictionsNotInUse: this.obtainJurisdictionsNotInUse(response.data.monitoree_maps, maxDaysOfHistory),
          selectedDateIndex: maxDaysOfHistory - 1,
          showBackButton: false,
          jurisdictionToShow: {
            category: 'fullCountry',
            name: 'USA',
            eventValue: null,
          },
          mapObject: null,
          showSpinner: false,
          viewMapTable: false,
          exposureMapData: analyticsData.exposure[maxDaysOfHistory - 1].value,
          isolationMapData: analyticsData.isolation[maxDaysOfHistory - 1].value,
          dateSubset: analyticsData.exposure.map(x => x.date),
          dateRange: analyticsData.exposure.map(x => moment(x.date).format('MM/DD')),
          maxDaysOfHistory,
          loading: false,
        });

        // A lot of times, the CountyLevelMaps functions will take time to render some new jurisdiction map.
        // We want the Spinner to spin until they report back that they're done. Therefore, we set spinnerState to 2
        // and subtract 1 every time they report back. When they each report back, 2 - 1 - 1 = 0 then we set `showSpinner` to false
        // Because calls to setState are asynchronous, this value must be on the component itself
        this.spinnerState = 0;
      } else {
        this.setState({ hasError: true, loading: false });
      }
    });
  }

  parseAnalyticsStatistics = (monitoree_maps, maxDaysOfHistory) => {
    // internal function for parsing the two workflow types
    const obtainAnalyticsValue = (values, workflowType) => {
      let returnVal = {
        stateData: {},
        countyData: {},
      };
      stateOptions.forEach(jurisdiction => {
        let jurisdictionValue = 0;
        let countyList = [];
        values.forEach(value => {
          if (value.workflow === workflowType && value.state === jurisdiction.name) {
            if (value.level === 'State') {
              jurisdictionValue = value.total;
            } else if (value.level === 'County') {
              countyList.push({ countyName: value.county || 'Unknown', value: value.total });
            }
          }
        });
        returnVal.stateData[jurisdiction.isoCode] = jurisdictionValue;
        returnVal.countyData[jurisdiction.isoCode] = countyList;
      });

      let valWhereStateNull = values.find(val => val.workflow === workflowType && val.level === 'State' && val.state === null);
      if (valWhereStateNull) {
        returnVal.stateData['Unknown'] = valWhereStateNull.total;
      }

      return returnVal;
    };

    let analyticsObject = {
      exposure: [],
      isolation: [],
    };

    _.takeRight(
      monitoree_maps.sort((a, b) => b.day - a.day),
      maxDaysOfHistory
    ).forEach(dayMapsPair => {
      analyticsObject.exposure.push({ date: dayMapsPair.day, value: obtainAnalyticsValue(dayMapsPair.maps, 'Exposure') });
      analyticsObject.isolation.push({ date: dayMapsPair.day, value: obtainAnalyticsValue(dayMapsPair.maps, 'Isolation') });
    });
    return analyticsObject;
  };

  obtainJurisdictionsPermittedToView = (monitoree_maps, maxDaysOfHistory) => {
    // This function iterates over monitoree_maps and pulls out all the state names where counties are referenced
    // This is used to determine what the user has permission to view (as the server only provides the data they are able to view)
    // For example, an epi in Virgina will only be served county-level data for virginia (and possibly bordering states depending on what `address_state` is set)
    // and this epi will not be able to zoom in on Arizona's data for example
    // The function then returns the isoCode for each state the current_user is allowed to expand
    let dateSubset = _.takeRight(
      monitoree_maps.sort((a, b) => b.day - a.day),
      maxDaysOfHistory
    );
    let statesWhereCountyReferenced = _.uniq(
      _.flatten(
        dateSubset.map(x =>
          x.maps
            .filter(data => data.level === 'County')
            .map(x => x.state)
            .filter(x => x)
        )
      )
    );
    return statesWhereCountyReferenced.map(x => stateOptions.find(y => y.name?.toLowerCase() === x?.toLowerCase())?.isoCode);
  };

  obtainJurisdictionsNotInUse = (monitoree_maps, maxDaysOfHistory) => {
    // Go through all the monitoree_maps and if a state or territory is NEVER referenced then it must not be in use
    // If it does have data, but just no county-data for it, then the current_user must just not have permission to zoom in on it
    let dateSubset = _.takeRight(
      monitoree_maps.sort((a, b) => b.day - a.day),
      maxDaysOfHistory
    );
    let statesReferenced = _.uniq(
      _.flatten(
        dateSubset.map(x =>
          x.maps
            .filter(data => data.level === 'State')
            .map(x => x.state)
            .filter(x => x)
        )
      )
    );
    const statesNotInUse = stateOptions
      .map(x => (statesReferenced.includes(x.name) && !insularAreas.includes(x.name) ? null : x))
      .filter(x => x)
      .map(x => x.isoCode);
    const insularAreasNotInUse = insularAreas
      .map(x => (statesReferenced.includes(x.name) ? null : x))
      .filter(x => x)
      .map(x => x.isoCode);
    return { states: statesNotInUse, insularAreas: insularAreasNotInUse };
  };

  decrementSpinnerCount = () => {
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
    this.state.showSpinner && (
      <div className="county-maps-loading">
        <span className="fa-stack fa-2x">
          <i className="fas fa-circle fa-stack-2x" style={{ color: '#305473' }}></i>
          <i className="fas fa-spinner fa-spin fa-stack-1x fa-inverse"></i>
        </span>
      </div>
    );

  handleDateRangeChange = value => {
    this.spinnerState = 2;
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
            exposureMapData: this.state.analyticsData.exposure[Number(value)].value,
            isolationMapData: this.state.analyticsData.isolation[Number(value)].value,
          });
        }, 25);
      }
    );
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

  showMapTable = () => {
    this.setState({ viewMapTable: !this.state.viewMapTable }, () => {
      setTimeout(() => {
        window.scrollBy(0, 150);
      }, 250);
    });
  };

  handleJurisdictionChange = jurisdiction => {
    this.spinnerState = 2;
    if (jurisdiction === 'USA') {
      this.setState({
        showBackButton: false,
        jurisdictionToShow: {
          category: 'fullCountry',
          name: 'USA',
          eventValue: null,
        },
        exposureMapData: this.state.analyticsData.exposure[Number(this.state.selectedDateIndex)].value,
        isolationMapData: this.state.analyticsData.isolation[Number(this.state.selectedDateIndex)].value,
        mapObject: null,
      });
    } else if (jurisdiction === 'territory') {
      this.setState({ showBackButton: true, showSpinner: true });
      let mapFile = TERRITORY_GEOJSON_FILE;
      this.loadJurisdictionData(mapFile, jurisdictionData => {
        this.setState({
          showBackButton: true,
          jurisdictionToShow: {
            category: 'territory',
            name: jurisdiction.name,
            eventValue: null,
          },
          exposureMapData: this.state.analyticsData.exposure[Number(this.state.selectedDateIndex)].value,
          isolationMapData: this.state.analyticsData.isolation[Number(this.state.selectedDateIndex)].value,
          mapObject: jurisdictionData.mapObject,
        });
      });
    } else {
      this.setState({ showBackButton: true, showSpinner: true });
      this.loadJurisdictionData(jurisdiction.target.dataItem.dataContext.map, jurisdictionData => {
        this.setState({
          showBackButton: true,
          jurisdictionToShow: {
            category: 'state',
            name: jurisdiction.target.dataItem.dataContext.name,
            eventValue: jurisdiction, // this is actually an eventObject from am4Charts
          },
          exposureMapData: this.state.analyticsData.exposure[Number(this.state.selectedDateIndex)].value,
          isolationMapData: this.state.analyticsData.isolation[Number(this.state.selectedDateIndex)].value,
          mapObject: jurisdictionData.mapObject,
        });
      });
    }
  };

  loadJurisdictionData = async (jurisdictionFileName, callback) => {
    callback({
      mapObject: await axios.get(`${window.BASE_PATH}/county_level_maps/${jurisdictionFileName}`).then(res => res.data),
    });
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="text-center" style={{ width: '100%' }}>
          <div className="h5">No Geographic Analytics Data could be shown</div>
        </div>
      );
    }
    if (this.state.loading) {
      return (
        <div className="text-center mt-4" style={{ width: '100%' }}>
          <div className="h5">Loading Geographic Analytics Data...</div>
        </div>
      );
    }
    let backButton = this.state.showBackButton && (
      <Button variant="primary" size="md" className="ml-auto btn-square" onClick={() => this.backToFullCountryMap()}>
        <i className="fas fa-arrow-left mr-2"> </i>
        Back to Country View
      </Button>
    );
    return (
      <div style={{ width: '96%', marginLeft: '2%' }}>
        <Row className="mb-4 mx-2 px-0">
          <Col md="24">
            <div className="text-center display-5 mb-1 mt-1 pb-4">{moment(this.state.dateSubset[this.state.selectedDateIndex]).format('MMMM DD, YYYY')}</div>
            <div className="mx-5 mb-4 pb-2">
              <Slider
                max={this.state.maxDaysOfHistory - 1}
                marks={this.state.dateRange}
                value={this.state.selectedDateIndex}
                railStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
                trackStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
                handleStyle={{ borderColor: '#595959', backgroundColor: 'white' }}
                dotStyle={{ borderColor: '#333', backgroundColor: 'white' }}
                onChange={this.handleDateRangeChange}
              />
            </div>
          </Col>
        </Row>
        <div>
          <div className="map-panel-mount-point">
            {this.renderSpinner()}
            <Row>
              <Col md="12" className="pr-0">
                <div className="map-title text-center">Active Records in Exposure Workflow</div>
                <CountyLevelMaps
                  id={1} // Some code requires a specific id (e.g. which div to mount the chart on)
                  style={{ borderRight: '1px solid #dcdcdc' }}
                  jurisdictionToShow={this.state.jurisdictionToShow}
                  jurisdictionData={this.state.exposureMapData}
                  mapObject={this.state.mapObject}
                  handleJurisdictionChange={this.handleJurisdictionChange}
                  decrementSpinnerCount={this.decrementSpinnerCount}
                  jurisdictionsNotInUse={this.state.jurisdictionsNotInUse}
                  jurisdictionsPermittedToView={this.state.jurisdictionsPermittedToView}
                />
              </Col>
              <Col md="12" className="pl-0">
                <div className="map-title text-center">Active Records in Isolation Workflow</div>
                <CountyLevelMaps
                  id={2}
                  jurisdictionToShow={this.state.jurisdictionToShow}
                  jurisdictionData={this.state.isolationMapData}
                  mapObject={this.state.mapObject}
                  handleJurisdictionChange={this.handleJurisdictionChange}
                  decrementSpinnerCount={this.decrementSpinnerCount}
                  jurisdictionsNotInUse={this.state.jurisdictionsNotInUse}
                  jurisdictionsPermittedToView={this.state.jurisdictionsPermittedToView}
                />
              </Col>
            </Row>
          </div>
          <Row className="mx-0 map-panel-controls">
            <Button
              variant="primary"
              size="md"
              className="mr-auto btn-square"
              disabled={this.state.jurisdictionToShow.category === 'territory'}
              title="View Insular Jurisdictions"
              onClick={() => this.handleJurisdictionChange('territory')}
              style={{ cursor: this.state.jurisdictionToShow.category === 'territory' ? 'not-allowed' : 'pointer' }}>
              View Insular Areas
              <i className="fas fa-search-location ml-2"> </i>
            </Button>
            {backButton}
          </Row>
          <div>
            <Button
              variant="primary"
              size="md"
              className="mr-auto btn-square mt-2"
              title={this.state.viewMapTable ? 'Collapse Tabular View of Map Data' : 'Expand Map Data in Tabular Form'}
              onClick={() => this.showMapTable()}>
              {this.state.viewMapTable ? 'Collapse Tabular View of Map Data' : 'Expand Map Data in Tabular Form'}
              <i className="fas fa-table ml-2"> </i>
            </Button>
            {this.state.viewMapTable && (
              <Table striped hover className="border">
                <thead>
                  <tr>
                    <th></th>
                    <th>Exposure Workflow</th>
                    <th>Isolation Workflow</th>
                  </tr>
                </thead>
                <tbody>
                  {stateOptions.map((jurisdiction, jurisdictionIndex) => (
                    <tr key={jurisdictionIndex}>
                      <td className="font-weight-bold">{jurisdiction.name}</td>
                      <td>{this.state.exposureMapData.stateData[jurisdiction.isoCode]}</td>
                      <td>{this.state.isolationMapData.stateData[jurisdiction.isoCode]}</td>
                    </tr>
                  ))}
                  {Object.prototype.hasOwnProperty.call(this.state.isolationMapData.stateData, 'Unknown') && (
                    <tr>
                      <td className="font-weight-bold">Unknown</td>
                      <td>{this.state.exposureMapData.stateData['Unknown']}</td>
                      <td>{this.state.isolationMapData.stateData['Unknown']}</td>
                    </tr>
                  )}
                </tbody>
              </Table>
            )}
          </div>
        </div>
      </div>
    );
  }
}

GeographicSummary.propTypes = {
  stats: PropTypes.object,
};

export default GeographicSummary;
