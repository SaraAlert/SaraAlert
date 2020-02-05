import React, { useState }  from "react";
import { Card } from 'react-bootstrap';
import { ComposableMap, Geographies, Geography, ZoomableGroup} from "react-simple-maps";
import ReactTooltip from 'react-tooltip';
import { scaleQuantize } from "d3-scale";
import { USAMap, stateOptions } from '../../data';

class MapChart extends React.Component {

  constructor(props) {
    super(props);
  }

  state = {
    highlighted: "",
    hovered: false,
    content: "",
    zoom: 1
  };
  stateOpts = stateOptions
  handleMove = geo => {
    if (this.state.hovered) return;
    this.setState({
      hovered: true,
      highlighted: geo.properties.CONTINENT
    });
  };
  handleLeave = () => {
    this.setState({
      highlighted: "",
      hovered: false
    });
  };

  projection = (width, height) => {
    const albersUsa = d3
      .geoAlbersUsa()
      .scale(1500)
      .translate([width / 2, height / 2]);
    albersUsa.rotate = function rotate(...args) {
      return args.length ? () => [width / 2, height / 2] : [0, 0, 0];
    };
    return albersUsa;
  };

  render () {

    const handleZoomIn = () => {
      if (this.state.zoom >= 4) return;
      this.setState({zoom: this.state.zoom * 2 })
    }
  
    const handleZoomOut = () => {
      if (this.state.zoom <= 1) return;
      this.setState({zoom: this.state.zoom / 2 })
    }

    const data = this.props.stats.monitoring_distribution_by_state;
    const colorScale = scaleQuantize()
    .domain([Math.min.apply(null,Object.values(data)),Math.max.apply(null,Object.values(data))])
    .range(["#ffffcc", "#ffeda0", "#fed976", "#feb24c", "#fd8d3c", "#fc4e2a", "#e31a1c", "#bd0026", "#800026"]);

    const setTooltipContent = (stateName) => {
      const symptomatic = getSymptomaticSize(stateName)
      this.setState({
        content: stateName ? `${stateName} - ${symptomatic}` : ""
      });
    };

    const getSymptomaticSize = (stateName) => {
      const stateAbvr = stateOptions.find(obj => {return obj.name == stateName})?.abbrv
      return data[stateAbvr]
    };

    return (
      <React.Fragment>
        <ReactTooltip>{this.state.content}</ReactTooltip>
          <Card className="card-square">
            <Card.Header as="h5">Location of Symptomatic Subjects</Card.Header>
              <Card.Body>
                <ComposableMap data-tip="" projection="geoAlbersUsa">>
                <ZoomableGroup center={[ -97, 40 ]} zoom={this.state.zoom}>
                  <Geographies geography={USAMap}>
                    {({ geographies }) =>
                      geographies.map(geo => (
                        <Geography
                          key={geo.rsmKey}
                          geography={geo}
                          stroke="#FFF"
                          fill={colorScale(geo ? getSymptomaticSize(geo.properties.name): "#EEE")}
                          onMouseEnter={() => {
                            setTooltipContent(`${geo.properties.name}`);
                          }}
                          onMouseLeave={() => {
                            setTooltipContent("");
                          }}
                          style={{
                            default: {
                              outline: "#none"
                            },
                            hover: {
                              fill: "#F53",
                              outline: "none"
                            },
                            pressed: {
                              fill: "#E42",
                              outline: "none"
                            }
                          }}
                        />
                      ))
                    }
              </Geographies>
              </ZoomableGroup>
            </ComposableMap>
            <div className="controls">
        <button class="btn btn-outline-primary" onClick={handleZoomIn}>
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth="3"
          >
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
        </button>
        <button class="btn btn-outline-primary" onClick={handleZoomOut}>
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth="3"
          >
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

export default MapChart