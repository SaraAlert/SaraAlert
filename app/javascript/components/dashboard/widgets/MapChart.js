import React from 'react';
import { Card } from 'react-bootstrap';
import { ComposableMap, Geographies, Geography, ZoomableGroup } from 'react-simple-maps';
import ReactTooltip from 'react-tooltip';
import { scaleQuantize } from 'd3-scale';
import { USAMap, stateOptions } from '../../data';
import { PropTypes } from 'prop-types';

class MapChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      highlighted: '',
      hovered: false,
      content: '',
      zoom: 1,
    };
    this.handleLeave = this.handleLeave.bind(this);
    this.handleZoomIn = this.handleZoomIn.bind(this);
    this.handleZoomOut = this.handleZoomOut.bind(this);
    this.setTooltipContent = this.setTooltipContent.bind(this);
    this.getSymptomaticSize = this.getSymptomaticSize.bind(this);
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

  render() {
    const data = this.props.stats.monitoring_distribution_by_state;
    const colorScale = scaleQuantize()
      .domain([Math.min.apply(null, Object.values(data)), Math.max.apply(null, Object.values(data))])
      .range(['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', '#fc4e2a', '#e31a1c', '#bd0026', '#800026']);

    return (
      <React.Fragment>
        <ReactTooltip>{this.state.content}</ReactTooltip>
        <Card className="card-square">
          <Card.Header as="h5">Location of Symptomatic Subjects</Card.Header>
          <Card.Body>
            <ComposableMap data-tip="" projection="geoAlbersUsa">
              <ZoomableGroup center={[-97, 40]} zoom={this.state.zoom}>
                <Geographies geography={USAMap}>
                  {({ geographies }) =>
                    geographies.map(geo => (
                      <Geography
                        key={geo.rsmKey}
                        geography={geo}
                        stroke="#FFF"
                        fill={
                          this.getSymptomaticSize(geo.properties.name, data) != 0 ? colorScale(this.getSymptomaticSize(geo.properties.name, data)) : '#50C878'
                        }
                        onMouseEnter={() => {
                          this.setTooltipContent(`${geo.properties.name}`, data);
                        }}
                        onMouseLeave={() => {
                          this.setTooltipContent('', data);
                        }}
                        style={{
                          default: {
                            outline: '#none',
                          },
                          hover: {
                            fill: '#F53',
                            outline: 'none',
                          },
                          pressed: {
                            fill: '#E42',
                            outline: 'none',
                          },
                        }}
                      />
                    ))
                  }
                </Geographies>
              </ZoomableGroup>
            </ComposableMap>
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
