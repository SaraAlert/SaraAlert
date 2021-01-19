import React from 'react';
import { PropTypes } from 'prop-types';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import * as am4maps from '@amcharts/amcharts4/maps';
import * as am4core from '@amcharts/amcharts4/core';
import am4themes_animated from '@amcharts/amcharts4/themes/animated';
import usaLow from '@amcharts/amcharts4-geodata/usaLow.js';

import { insularAreas } from '../mapData';
import { stateOptions } from '../../../data/stateOptions';
import separatorLines from '../../assets/separatorLines.js';
import usaTerritories2High from '../../assets/usaTerritories.json';

// There are no GEOJSON files provided by AMCHARTS for these Territories
// (It does have files for `US-PR` and `US-AS` but those aren't implemented yet)
const NON_ZOOMABLE_INSULAR_TERRITORIES = ['US-PR', 'US-AS', 'US-FM', 'US-GU', 'MH', 'US-MP', 'PW', 'US-VI'];
am4core.useTheme(am4themes_animated);

class CountyLevelMaps extends React.Component {
  constructor(props) {
    super(props);
    this.chart = null;
    this.territoryChart = null;
    this.usaSeries = null;
    this.usaPolygon = null;
    this.usaSeriesNotInUse = null;
    this.usaPolygonNotInUse = null;
    this.jurisdictionSeries = null;
    this.jurisdictionPolygon = null;
    this.territorySeries = null;
    this.territoryPolygon = null;
    this.territorySeriesNotInUse = null;
    this.territoryPolygonNotInUse = null;
    this.heatLegend = null;
    this.territoryHeatLegend = null;
    this.countiesNotFound = null;

    this.state = {
      showTerritory: false,
      countiesNotFound: false,
      showStateTooltip: false,
      showCountyTooltip: false,
    };
  }

  componentDidMount = () => {
    this.chart = am4core.create(`chartdiv-${this.props.id}`, am4maps.MapChart);
    this.chart.projection = new am4maps.projections.AlbersUsa();
    this.chart.seriesContainer.draggable = true;
    this.chart.seriesContainer.resizable = true;
    this.chart.seriesContainer.wheelable = true;
    this.chart.maxZoomLevel = 10;
    this.heatLegend = this.chart.createChild(am4maps.HeatLegend);

    this.usaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    this.usaSeries.useGeodata = true;
    this.usaSeries.geodata = usaLow;
    this.usaSeries.exclude = this.props.jurisdictionsNotInUse.states;

    this.usaPolygon = this.usaSeries.mapPolygons.template;
    this.usaPolygon.tooltipPosition = 'fixed';
    this.usaPolygon.adapter.add('tooltipText', (text, target) => {
      if (this.props.jurisdictionsPermittedToView.includes(target.tooltipDataItem.dataContext.id)) {
        return '{name} : {value}';
      } else {
        return `{name}: {value}
          [font-style: italic; font-size: 10px;]zoom not available[/]`;
      }
    });

    this.usaPolygon.nonScalingStroke = true;
    this.usaPolygon.fill = am4core.color('#3e6887');
    this.usaPolygon.propertyFields.fill = 'color';

    this.usaSeries.heatRules.push({
      property: 'fill',
      target: this.usaSeries.mapPolygons.template,
      min: am4core.color('#E89005').lighten(0.5),
      max: am4core.color('#A62639').brighten(0.5),
    });

    this.usaPolygon.events.on('hit', ev => {
      if (this.props.jurisdictionsPermittedToView.includes(ev.target.dataItem.dataContext.id)) {
        this.props.handleJurisdictionChange(ev);
      }
    });

    this.usaSeriesNotInUse = this.chart.series.push(new am4maps.MapPolygonSeries());
    this.usaSeriesNotInUse.useGeodata = true;
    this.usaSeriesNotInUse.geodata = usaLow;
    this.usaSeriesNotInUse.include = this.props.jurisdictionsNotInUse.states;
    this.usaSeriesNotInUse.tooltip.getFillFromObject = false;
    this.usaSeriesNotInUse.tooltip.background.fill = am4core.color('#333');

    this.usaPolygonNotInUse = this.usaSeriesNotInUse.mapPolygons.template;
    this.usaPolygonNotInUse.tooltipPosition = 'fixed';
    this.usaPolygonNotInUse.tooltipText = 'Sara Alert Not In Use';
    this.usaPolygonNotInUse.nonScalingStroke = true;
    this.usaPolygonNotInUse.fill = am4core.color('#a5a5a5');

    this.jurisdictionSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    this.jurisdictionSeries.useGeodata = true;
    this.jurisdictionSeries.hide();
    this.jurisdictionSeries.heatRules.push({
      property: 'fill',
      target: this.jurisdictionSeries.mapPolygons.template,
      min: am4core.color('#E89005').lighten(0.5),
      max: am4core.color('#A62639').brighten(0.5),
    });

    this.jurisdictionPolygon = this.jurisdictionSeries.mapPolygons.template;
    this.jurisdictionPolygon.tooltipText = '{name} : {value}';
    this.jurisdictionPolygon.nonScalingStroke = true;
    this.jurisdictionPolygon.fill = am4core.color('#f06a6d');

    this.territoryChart = am4core.create(`territorydiv-${this.props.id}`, am4maps.MapChart);
    this.territoryChart.projection = new am4maps.projections.Miller();
    this.territoryChart.seriesContainer.draggable = true;
    this.territoryChart.seriesContainer.resizable = true;
    this.territoryChart.seriesContainer.wheelable = true;
    this.territoryChart.maxZoomLevel = 10;

    // It appears the separatorLines must be mounted on the chart instance (as opposed to a Series)
    this.territoryChart.geodata = separatorLines;
    var separatorSeries = this.territoryChart.series.push(new am4maps.MapLineSeries());
    separatorSeries.useGeodata = true;
    separatorSeries.mapLines.template.stroke = am4core.color('#ccc');
    separatorSeries.mapLines.template.strokeWidth = 0.025;

    this.territoryHeatLegend = this.territoryChart.createChild(am4maps.HeatLegend);

    this.territorySeries = this.territoryChart.series.push(new am4maps.MapPolygonSeries());
    this.territorySeries.useGeodata = true;
    this.territorySeries.geodata = usaTerritories2High;
    this.territorySeries.exclude = this.props.jurisdictionsNotInUse.insularAreas;

    this.territoryPolygon = this.territorySeries.mapPolygons.template;
    this.territoryPolygon.tooltipText = '{name}: {value}';
    this.territoryPolygon.strokeWidth = 1;
    this.territoryPolygon.stroke = am4core.color('#333');
    this.territoryPolygon.fill = am4core.color('#3e6887');
    this.territoryPolygon.propertyFields.fill = 'color';

    this.territoryPolygon.adapter.add('tooltipText', (text, target) => {
      if (NON_ZOOMABLE_INSULAR_TERRITORIES.includes(target.tooltipDataItem.dataContext.id)) {
        return `{name}: {value}
          [font-style: italic; font-size: 10px;]zoom not available[/]`;
      } else {
        return '{name} : {value}';
      }
    });

    const labelSeries = this.territoryChart.series.push(new am4maps.MapImageSeries());
    const labelTemplate = labelSeries.mapImages.template.createChild(am4core.Label);
    labelTemplate.horizontalCenter = 'left';
    labelTemplate.verticalCenter = 'top';
    labelTemplate.valign = true;
    labelTemplate.fontSize = 14;
    labelTemplate.fontFamily = 'Arial';
    labelTemplate.interactionsEnabled = false;
    labelTemplate.nonScaling = true;

    this.territorySeriesNotInUse = this.territoryChart.series.push(new am4maps.MapPolygonSeries());
    this.territorySeriesNotInUse.useGeodata = true;
    this.territorySeriesNotInUse.geodata = usaTerritories2High;
    this.territorySeriesNotInUse.tooltip.getFillFromObject = false;
    this.territorySeriesNotInUse.tooltip.background.fill = am4core.color('#333');
    this.territorySeriesNotInUse.include = this.props.jurisdictionsNotInUse.insularAreas;

    this.territoryPolygonNotInUse = this.territorySeriesNotInUse.mapPolygons.template;
    this.territoryPolygonNotInUse.tooltipPosition = 'fixed';
    this.territoryPolygonNotInUse.tooltipText = '{name} : Sara Alert Not In Use';
    this.territoryPolygonNotInUse.nonScalingStroke = true;
    this.territoryPolygonNotInUse.strokeWidth = 1;
    this.territoryPolygonNotInUse.stroke = am4core.color('#333');
    this.territoryPolygonNotInUse.fill = am4core.color('#a5a5a5');

    this.territorySeries.heatRules.push({
      property: 'fill',
      target: this.territorySeries.mapPolygons.template,
      min: am4core.color('#E89005').lighten(0.5),
      max: am4core.color('#A62639').brighten(0.5),
    });

    this.territoryPolygon.events.on('inited', () => {
      insularAreas.map(insularArea => {
        const polygon = this.territorySeries.getPolygonById(insularArea.isoCode) || this.territorySeriesNotInUse.getPolygonById(insularArea.isoCode);
        if (polygon) {
          let label = labelSeries.mapImages.create();
          const territoryName = polygon.dataItem.dataContext.id.split('-').pop();
          // This next line is the hackiest line.
          // Essentially, I know where the GEOJSON points lie for this GEOJSON file so I manually
          // position the upper and lower labels with tried-and-tested values (22.5 and 30)
          label.latitude = polygon.north < 25 ? 22.5 : 30;
          label.longitude = polygon.visualLongitude - 0.5;
          label.children.getIndex(0).text = territoryName;
        }
      });
    });

    this.territorySeries.include = insularAreas.map(customTerritory => customTerritory.isoCode);

    this.territorySeries.hide();

    // Assign the hover colors to the jurisdictionPolygons and usaPolygons
    var hoverColor = this.usaPolygon.states.create('hover');
    hoverColor.properties.fill = this.chart.colors.getIndex(1);

    hoverColor = this.jurisdictionPolygon.states.create('hover');
    hoverColor.properties.fill = this.chart.colors.getIndex(1);

    hoverColor = this.territoryPolygon.states.create('hover');
    hoverColor.properties.fill = this.territoryChart.colors.getIndex(1);

    this.updateJurisdictionData();
  };

  hideUSAMap = () => {
    this.usaSeries.hide();
    this.usaSeriesNotInUse.hide();
  };

  showUSAMap = () => {
    this.usaSeries.show();
    this.usaSeriesNotInUse.show();
  };

  renderHeatLegend = dataSeries => {
    let heatLegendReference = this.props.jurisdictionToShow.category === 'territory' ? this.territoryHeatLegend : this.heatLegend;
    heatLegendReference.id = 'heatLegend';
    heatLegendReference.series = dataSeries;
    heatLegendReference.align = 'right';
    heatLegendReference.valign = 'bottom';
    heatLegendReference.marginRight = '7px';
    heatLegendReference.background.fill = am4core.color('#fff');
    heatLegendReference.background.fillOpacity = 0.05;
    // For Insular Areas, we still want a Horizontal Legend, but for the 50-states we want a vertical legend
    // so it doesnt sit over and obstruct Florida
    if (this.props.jurisdictionToShow.category === 'territory') {
      heatLegendReference.width = am4core.percent(25);
      heatLegendReference.padding(5, 5, 5, 5);
    } else {
      heatLegendReference.width = '50px';
      heatLegendReference.padding(10, 10, 10, 0);
      heatLegendReference.orientation = 'vertical';
    }

    let minRange = heatLegendReference.valueAxis.axisRanges.create();
    minRange.label.horizontalCenter = 'left';

    let maxRange = heatLegendReference.valueAxis.axisRanges.create();
    maxRange.label.horizontalCenter = 'right';

    heatLegendReference.valueAxis.renderer.labels.template.adapter.add('text', () => ``);

    dataSeries.events.on('datavalidated', () => {
      let min = heatLegendReference.series.dataItem.values.value.low;
      let minRange = heatLegendReference.valueAxis.axisRanges.getIndex(0);
      minRange.value = min;
      minRange.label.text = '' + heatLegendReference.numberFormatter.format(min);
      let max = heatLegendReference.series.dataItem.values.value.high;
      let maxRange = heatLegendReference.valueAxis.axisRanges.getIndex(1);
      maxRange.value = max;
      maxRange.label.text = '' + heatLegendReference.numberFormatter.format(max);
    });
  };

  componentDidUpdate = prevProps => {
    // The ordering of these two if statements is important
    // If a new jurisdiction is specified, then transition to the new jurisdiction
    // Else if JUST the data has updated, then just update the data
    if (prevProps.jurisdictionToShow.name !== this.props.jurisdictionToShow.name) {
      this.transitionJurisdiction();
    } else if (prevProps.jurisdictionData !== this.props.jurisdictionData) {
      this.updateJurisdictionData();
    }
  };

  transitionJurisdiction = () => {
    this.setState({ showCountyTooltip: false, showStateTooltip: false }, () => {
      if (this.props.jurisdictionToShow.category === 'fullCountry') {
        this.setState({ showTerritory: false }, () => {
          this.jurisdictionSeries.hide();
          this.showUSAMap();
          this.chart.maxZoomLevel = 32;
          this.chart.goHome();
          setTimeout(() => {
            this.chart.maxZoomLevel = 10;
            this.updateJurisdictionData();
            this.props.decrementSpinnerCount();
          }, 1050);
        });
      } else if (this.props.jurisdictionToShow.category === 'territory') {
        this.hideUSAMap();
        if (this.territorySeries.isHidden) this.territorySeries.show();
        this.territorySeries.geodata = this.props.mapObject;
        this.setState({ showTerritory: true }, () => {
          setTimeout(() => {
            this.updateJurisdictionData();
            this.territoryChart.goHome();
            this.props.decrementSpinnerCount();
          }, 1050);
        });
      } else if (this.props.jurisdictionToShow.category === 'state') {
        this.setState({ showTerritory: false }, () => {
          let ev = this.props.jurisdictionToShow.eventValue;
          this.chart.maxZoomLevel = 32;
          this.chart.zoomToMapObject(ev.target);
          // Rendering the Territory Level Chart causes the UI to hang
          // And if that hang comes during the zoom animation, it looks really choppy
          // Delaying the render by 1.05 seconds makes the UI feel more responsive
          setTimeout(() => {
            this.hideUSAMap();
            this.jurisdictionSeries.geodata = this.props.mapObject;
            this.jurisdictionSeries.show();
            this.updateJurisdictionData();
            this.props.decrementSpinnerCount();
          }, 1050);
        });
      }
    });
  };

  updateJurisdictionData = () => {
    let data = [];
    if (this.props.jurisdictionToShow.category === 'fullCountry') {
      let nonCustomJurisdictions = stateOptions.filter(jurisdiction => !_.some(insularAreas, v => v.name === jurisdiction.name));
      nonCustomJurisdictions.forEach(region => {
        data.push({
          id: region.isoCode,
          map: region.mapFile,
          value: this.props.jurisdictionData.stateData[region.isoCode],
        });
      });
      this.setState({ showStateTooltip: Object.prototype.hasOwnProperty.call(this.props.jurisdictionData.stateData, 'Unknown') });

      this.usaSeries.data = data;
      this.renderHeatLegend(this.usaSeries);
      this.props.decrementSpinnerCount();
    } else if (this.props.jurisdictionToShow.category === 'territory') {
      insularAreas.forEach(insularArea => {
        data.push({
          id: `${insularArea.isoCode}`,
          value: this.props.jurisdictionData.stateData[String(insularArea.isoCode)],
        });
      });
      this.territorySeries.data = data;
      this.renderHeatLegend(this.territorySeries);
      this.props.decrementSpinnerCount();
    } else if (this.props.jurisdictionToShow.category === 'state') {
      let stateIsoCode = stateOptions.find(state => state.name === this.props.jurisdictionToShow.name).isoCode;
      let counties = this.jurisdictionSeries.geodata.features;
      counties.forEach(county => {
        let countyRef = this.props.jurisdictionData.countyData[String(stateIsoCode)].find(
          countyData => _.trim(countyData.countyName).toLowerCase() === _.trim(county.properties.name).toLowerCase()
        );
        let countyValue = countyRef ? countyRef.value : 0;
        data.push({
          id: `${county.id}`,
          color: am4core.color('#3B9CD9'),
          value: countyValue,
        });
      });
      const countyNames = this.jurisdictionSeries.geodata.features.map(county => county.properties.name);
      // We want to report to the user if there were values in the DB that couldnt be matched to real counties
      // The most believable and common instance of this will be `Unknown` which is when a county is not entered
      // However, the county field for patients is not validated so it is possible for unknown county names to be present in the data
      // By reporting this to the user in a little popup, we cover all bases
      this.countiesNotFound = this.props.jurisdictionData.countyData[String(stateIsoCode)]
        .map(cd => (countyNames.includes(cd.countyName) ? null : cd))
        .filter(x => x);
      this.setState({ showCountyTooltip: !_.isEmpty(this.countiesNotFound) });
      this.jurisdictionSeries.data = data;
      this.renderHeatLegend(this.jurisdictionSeries);
      this.props.decrementSpinnerCount();
    }
  };

  renderStateTooltip = () => {
    return (
      this.state.showStateTooltip && (
        <span>
          <span data-for={`state-tooltip-${this.props.id}`} data-tip="" className="clm-tooltip" style={{ paddingLeft: this.props.id === 1 ? '20px' : '5px' }}>
            <i className="fas fa-exclamation-circle" style={{ fontSize: '20px' }}></i>
          </span>
          <ReactTooltip id={`state-tooltip-${this.props.id}`} multiline={true} place="right" type="dark" effect="solid" className="clm-tooltip-container">
            <span>Could not map {this.props.jurisdictionData.stateData['Unknown']} records to a specific state</span>
            <div>
              This most likely means <b></b>Home Address State was left blank
            </div>
          </ReactTooltip>
        </span>
      )
    );
  };

  renderCountyTooltip = () => {
    const NUMBER_OF_COUNTIES_TO_SHOW = 10;
    // We can't control what users type in for COUNTY so it's possible this list could be very long
    // Therefore only show the top NUMBER_OF_COUNTIES_TO_SHOW or so and tell the user that there are more (if that's the case)
    const countiesToShow = _.take(this.countiesNotFound, NUMBER_OF_COUNTIES_TO_SHOW);
    return (
      this.state.showCountyTooltip && (
        <span key={this.countiesNotFound}>
          <span data-for={`county-tooltip-${this.props.id}`} data-tip="" className="clm-tooltip" style={{ paddingLeft: this.props.id === 1 ? '20px' : '5px' }}>
            <i className="fas fa-exclamation-circle" style={{ fontSize: '20px' }}></i>
          </span>
          <ReactTooltip id={`county-tooltip-${this.props.id}`} multiline={true} place="right" type="dark" effect="solid" className="clm-tooltip-container">
            <span>
              Could not map the following data to any counties in this jurisdiction:
              {countiesToShow.map((county, index) => {
                return (
                  <li key={index}>
                    {' '}
                    {county.countyName} : {county.value}{' '}
                  </li>
                );
              })}
              {this.countiesNotFound.length > NUMBER_OF_COUNTIES_TO_SHOW && (
                <li>And {this.countiesNotFound.length - NUMBER_OF_COUNTIES_TO_SHOW} counties more...</li>
              )}
              {countiesToShow.find(x => x.countyName === 'Unknown') && (
                <i>
                  <b>Unknown</b> most likely means that <b>County</b> is missing
                </i>
              )}
            </span>
          </ReactTooltip>
        </span>
      )
    );
  };

  render() {
    return (
      <div className="map-panel-contaianer">
        <div id={`chartdiv-${this.props.id}`} className={this.state.showTerritory ? 'hidden-map-container' : 'visible-map-container'}></div>
        <div id={`territorydiv-${this.props.id}`} className={this.state.showTerritory ? 'visible-map-container' : 'hidden-map-container'}></div>
        {this.renderCountyTooltip()}
        {this.renderStateTooltip()}
      </div>
    );
  }
}

CountyLevelMaps.propTypes = {
  id: PropTypes.number,
  jurisdictionToShow: PropTypes.object,
  jurisdictionData: PropTypes.object,
  mapObject: PropTypes.object,
  handleJurisdictionChange: PropTypes.func,
  decrementSpinnerCount: PropTypes.func,
  jurisdictionsNotInUse: PropTypes.object,
  jurisdictionsPermittedToView: PropTypes.array,
};

export default CountyLevelMaps;
