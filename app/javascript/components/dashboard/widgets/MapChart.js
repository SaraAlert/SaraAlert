import React from 'react';
import { Card } from 'react-bootstrap';
import { ComposableMap, Geographies, Geography, ZoomableGroup } from 'react-simple-maps';
import ReactTooltip from 'react-tooltip';
import { scaleQuantize } from 'd3-scale';
import moment from 'moment';
import _ from 'lodash';
import { USAMap, stateOptions } from '../../data';
import { PropTypes } from 'prop-types';
import Slider from 'rc-slider/lib/Slider';
import 'rc-slider/assets/index.css';

class MapChart extends React.Component {
  constructor(props) {
    super(props);
    this.handleLeave = this.handleLeave.bind(this);
    this.handleZoomIn = this.handleZoomIn.bind(this);
    this.handleZoomOut = this.handleZoomOut.bind(this);
    this.setTooltipContent = this.setTooltipContent.bind(this);
    this.getSymptomaticSize = this.getSymptomaticSize.bind(this);
    this.handleDateRangeChange = this.handleDateRangeChange.bind(this);
    this.getDateRange = this.getDateRange.bind(this);
    this.state = {
      highlighted: '',
      hovered: false,
      content: '',
      zoom: 1,
      selectedDateData: {},
      selectedDay: null,
      // All this `map` does is to translate `{'Kansas' : 5}` to `{'KA' : 5}` for all states
      mappedTotalPatientCountByStateAndDay: this.props.stats.total_patient_count_by_state_and_day.map(x => {
        let mappedValues = {};
        mappedValues['day'] = x.day;
        _.forIn(_.omit(x, 'day'), (value, key) => {
          let abbreviation = stateOptions.find(state => state.name === key).abbrv;
          mappedValues[abbreviation] = value;
        });
        return mappedValues;
      }),
    };
  }
  componentDidMount() {
    this.setState({ selectedDay: _.head(this.state.mappedTotalPatientCountByStateAndDay).day });
    this.setState({ selectedDateData: this.state.mappedTotalPatientCountByStateAndDay[0] });
  }

  handleMove(geo) {
    if (this.state.hovered) return;
    this.setState({
      hovered: true,
      highlighted: geo.properties.CONTINENT,
    });
  }

  handleLeave() {
    this.setState({
      highlighted: '',
      hovered: false,
    });
  }

  handleZoomIn() {
    if (this.state.zoom >= 4) return;
    this.setState({ zoom: this.state.zoom * 2 });
  }

  handleZoomOut() {
    if (this.state.zoom <= 1) return;
    this.setState({ zoom: this.state.zoom / 2 });
  }

  setTooltipContent(stateName, data) {
    const symptomatic = this.getSymptomaticSize(stateName, data);
    this.setState({
      content: stateName ? `${stateName} - ${symptomatic}` : '',
    });
  }

  getSymptomaticSize(stateName, data) {
    const state = stateOptions.find(obj => {
      return obj.name == stateName;
    });
    const stateAbvr = state ? state.abbrv : '';
    return data && data[stateAbvr] ? data[stateAbvr] : 0;
  }

  getDateRange() {
    let retVal = {};
    this.state.mappedTotalPatientCountByStateAndDay.forEach((dayData, index) => {
      retVal[index] = moment(dayData.day).format('DD');
    });
    return retVal;
  }

  handleDateRangeChange(value) {
    this.setState({ selectedDateData: _.omit(this.state.mappedTotalPatientCountByStateAndDay[value], 'day') });
    this.setState({ selectedDay: this.state.mappedTotalPatientCountByStateAndDay[value].day });
  }

  render() {
    const colorScale = scaleQuantize()
      .domain([
        0,
        Math.max(...Object.values(this.state.mappedTotalPatientCountByStateAndDay.map(x => _.omit(x, 'day'))).map(x => Math.max(...Object.values(x)))),
      ])
      .range(['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', '#fc4e2a', '#e31a1c', '#bd0026', '#800026']);

    return (
      <React.Fragment>
        <ReactTooltip>{this.state.content}</ReactTooltip>
        <Card className="card-square">
          <Card.Header as="h5">Total Monitorees Over Time</Card.Header>
          <Card.Body>
            <ComposableMap data-tip="" projection="geoAlbersUsa">
              <ZoomableGroup center={[-97, 40]} zoom={this.state.zoom}>
                <Geographies geography={USAMap}>
                  {({ geographies }) =>
                    geographies.map(geo => (
                      <Geography
                        key={geo.rsmKey}
                        geography={geo}
                        stroke="white"
                        fill={
                          this.getSymptomaticSize(geo.properties.name, this.state.selectedDateData) != 0
                            ? colorScale(this.getSymptomaticSize(geo.properties.name, this.state.selectedDateData))
                            : '#39CC7D'
                        }
                        onMouseEnter={() => {
                          this.setTooltipContent(`${geo.properties.name}`, this.state.selectedDateData);
                        }}
                        onMouseLeave={() => {
                          this.setTooltipContent('', this.state.selectedDateData);
                        }}
                        style={{
                          hover: {
                            fill: '#b3b3b3',
                            outline: 'none',
                          },
                          pressed: {
                            fill: '#808080',
                            outline: 'none',
                          },
                        }}
                      />
                    ))
                  }
                </Geographies>
              </ZoomableGroup>
            </ComposableMap>
            <div className="mx-5 mt-4">
              <Slider
                max={this.state.mappedTotalPatientCountByStateAndDay.length - 1}
                marks={this.getDateRange()}
                railStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
                trackStyle={{ backgroundColor: '#666', height: '3px', borderRadius: '10px' }}
                handleStyle={{ borderColor: '#595959', backgroundColor: 'white' }}
                dotStyle={{ borderColor: '#333', backgroundColor: 'white' }}
                onChange={this.handleDateRangeChange}
              />
              <div className="mt-5 text-center display-6 font-weight-bold"> {moment(this.state.selectedDay).format('MM - DD - YYYY')}</div>
            </div>
            <div className="controls">
              <button className="btn btn-outline-primary" onClick={this.handleZoomIn}>
                <svg width="24" height="24" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="3">
                  <line x1="12" y1="5" x2="12" y2="19" />
                  <line x1="5" y1="12" x2="19" y2="12" />
                </svg>
              </button>
              <button className="btn btn-outline-primary" onClick={this.handleZoomOut}>
                <svg width="24" height="24" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="3">
                  <line x1="5" y1="12" x2="19" y2="12" />
                </svg>
              </button>
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MapChart.propTypes = {
  stats: PropTypes.object,
};

export default MapChart;
