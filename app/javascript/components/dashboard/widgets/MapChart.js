import React from "react";
import { Card } from 'react-bootstrap';
import { ComposableMap, Geographies, Geography } from "react-simple-maps";
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
    content: ""
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



  render () {

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
            </ComposableMap>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default MapChart