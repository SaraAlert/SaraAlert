import React from 'react';
import _ from 'lodash';
import * as am4core from '@amcharts/amcharts4/core';
import reportError from '../../util/ReportError';
import { PropTypes } from 'prop-types';
import { stateOptions, customTerritories } from '../../data';
import * as am4maps from '@amcharts/amcharts4/maps';
import am4themes_animated from '@amcharts/amcharts4/themes/animated';
import usaLow from '@amcharts/amcharts4-geodata/usaLow.js';

am4core.useTheme(am4themes_animated);

class CountyLevelMaps extends React.Component {
  constructor(props) {
    super(props);
    this.chart = null;
    this.usaSeries = null;
    this.usaPolygon = null;
    this.jurisdictionSeries = null;
    this.jurisdictionPolygon = null;
    this.heatLegend = null;
    // If multiple instances of the CLM Component exist on a page, amcharts4 cannnot find the correct
    // instance to mount the chart at. Therefore we generate custom string for each instance
    this.customID = this.makeid(10).substring(0, 6);
  }

  makeid = length => {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < length; ++i) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return result;
  };

  componentDidMount = () => {
    am4core.useTheme(am4themes_animated);

    this.chart = am4core.create(`chartdiv-${this.customID}`, am4maps.MapChart);
    this.chart.projection = new am4maps.projections.AlbersUsa();
    this.heatLegend = this.chart.createChild(am4maps.HeatLegend);

    this.usaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    this.usaSeries.useGeodata = true;
    this.usaSeries.geodata = usaLow;

    this.usaPolygon = this.usaSeries.mapPolygons.template;
    this.usaPolygon.tooltipText = '{name}: {value}';
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
      this.props.handleJurisdictionChange(ev);
    });

    this.jurisdictionSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    this.jurisdictionSeries.useGeodata = true;
    this.jurisdictionSeries.hide();

    this.jurisdictionSeries.geodataSource.events.onAll(ev => {
      console.log('Remove this at some point, but its interesting to see all events', ev);
    });
    this.jurisdictionSeries.geodataSource.events.on('done', () => {
      this.usaSeries.hide();
      this.jurisdictionSeries.show();
      this.updateJurisdictionData();
    });

    this.jurisdictionSeries.geodataSource.events.on('error', ev => {
      reportError(ev);
    });

    this.jurisdictionPolygon = this.jurisdictionSeries.mapPolygons.template;
    this.jurisdictionPolygon.tooltipText = '{name} : {value}';
    this.jurisdictionPolygon.nonScalingStroke = true;
    this.jurisdictionPolygon.fill = am4core.color('#f06a6d');
    this.jurisdictionSeries.heatRules.push({
      property: 'fill',
      target: this.jurisdictionSeries.mapPolygons.template,
      min: am4core.color('#E89005').lighten(0.5),
      max: am4core.color('#A62639').brighten(0.5),
    });

    // Assign the hover colors to the jurisdictionPolygons and usaPolygons
    var hoverColor = this.usaPolygon.states.create('hover');
    hoverColor.properties.fill = this.chart.colors.getIndex(1);

    hoverColor = this.jurisdictionPolygon.states.create('hover');
    hoverColor.properties.fill = this.chart.colors.getIndex(1);

    // selectedDateIndex will mostly likely be initialized as 0 (meaning the oldest date in our dataset)
    // this.updateDataWithNewDate(this.props.selectedDateIndex)
    this.updateJurisdictionData();
  };

  renderHeatLegend = dataSeries => {
    this.heatLegend.id = 'heatLegend';
    this.heatLegend.series = dataSeries;
    this.heatLegend.align = 'right';
    this.heatLegend.valign = 'bottom';
    this.heatLegend.width = am4core.percent(25);
    this.heatLegend.marginRight = am4core.percent(4);
    this.heatLegend.background.fill = am4core.color('#3c5bdc');
    this.heatLegend.background.fillOpacity = 0.05;
    this.heatLegend.padding(5, 5, 5, 5);

    let minRange = this.heatLegend.valueAxis.axisRanges.create();
    minRange.label.horizontalCenter = 'left';

    let maxRange = this.heatLegend.valueAxis.axisRanges.create();
    maxRange.label.horizontalCenter = 'right';

    this.heatLegend.valueAxis.renderer.labels.template.adapter.add('text', () => ``);

    dataSeries.events.on('datavalidated', ev => {
      this.heatLegend = ev.target.map.getKey('heatLegend');
      let min = this.heatLegend.series.dataItem.values.value.low;
      let minRange = this.heatLegend.valueAxis.axisRanges.getIndex(0);
      minRange.value = min;
      minRange.label.text = '' + this.heatLegend.numberFormatter.format(min);
      let max = this.heatLegend.series.dataItem.values.value.high;
      let maxRange = this.heatLegend.valueAxis.axisRanges.getIndex(1);
      maxRange.value = max;
      maxRange.label.text = '' + this.heatLegend.numberFormatter.format(max);
    });
  };

  componentDidUpdate = prevProps => {
    // The ordering of these two if statements is important
    // If a new jurisdiction is specified, then transition to the new jurisdiction
    // Else if JUST the data has updated, then just update the data
    if (prevProps.jurisdictionToShow.name !== this.props.jurisdictionToShow.name) {
      this.transitionJurisdiction()
    } else if (prevProps.jurisdictionData !== this.props.jurisdictionData) {
      this.updateJurisdictionData();
    }
  };

  transitionJurisdiction = () => {
    console.log(`CountyLevelMaps : transitionJurisdiction`);
    if (this.props.jurisdictionToShow.category === 'fullCountry') {
      this.jurisdictionSeries.hide();
      this.usaSeries.show();
      this.chart.goHome();
      setTimeout(() => {
        this.updateJurisdictionData();
        this.props.decrementSpinnerCount();
      }, 1050);
    } else if (this.props.jurisdictionToShow.category === 'state') {
      let ev = this.props.jurisdictionToShow.eventValue;
      this.chart.zoomToMapObject(ev.target);
      // Rendering the Territory Level Chart causes the UI to hang
      // And if that hang comes during the zoom animation, it looks really choppy
      // Delaying the render by 1.05 seconds (That's how long the zoom takes - I timed it)
      // makes the UI feel more responsive
      setTimeout(() => {
        this.usaSeries.hide();
        this.jurisdictionSeries.geodata = this.props.mapObject;
        this.jurisdictionSeries.show();
        this.updateJurisdictionData();
        this.props.decrementSpinnerCount();
      }, 1050);
    } else if (this.props.jurisdictionToShow.category === 'territory') {
      // Need to show a custom map
    } else {
      console.error('THIS SHOULD NEVER HAPPEN');
    }
  };

  updateJurisdictionData = () => {
    console.log('updateJurisdictionData');
    let data = [];
    if (this.props.jurisdictionToShow.category === 'fullCountry') {
      let nonCustomJurisdictions = stateOptions.filter(jurisdiction => !_.some(customTerritories, v => v.name === jurisdiction.name));
      nonCustomJurisdictions.forEach(region => {
        data.push({
          id: `US-${region.abbrv}`,
          map: region.mapFile,
          value: this.props.jurisdictionData[region.name] || 0,
        });
      });
      this.usaSeries.data = data;
      this.renderHeatLegend(this.usaSeries);
      this.props.decrementSpinnerCount();
    } else if (this.props.jurisdictionToShow.category === 'state') {
      console.log(this.jurisdictionSeries);
      let counties = this.jurisdictionSeries.geodata.features;
      counties.forEach(county => {
        data.push({
          id: `${county.id}`,
          color: am4core.color('#3B9CD9'),
          value: parseInt(Math.random() * 50),
        });
      });
      this.jurisdictionSeries.data = data;
      this.renderHeatLegend(this.jurisdictionSeries);
    } else if (this.props.jurisdictionToShow.category === 'territory') {
      // Need to show a custom map
    } else {
      console.error('THIS SHOULD NEVER HAPPEN');
    }
  };

  render() {
    console.log('CLM - render');
    return (
      <div className="map-panel-contaianer">
        <div id={`chartdiv-${this.customID}`} style={{ width: '100%', height: '400px' }}></div>
      </div>
    );
  }
}

CountyLevelMaps.propTypes = {
  jurisdictionToShow: PropTypes.object,
  jurisdictionData: PropTypes.object,
  mapObject: PropTypes.object,
  handleJurisdictionChange: PropTypes.func,
  decrementSpinnerCount: PropTypes.func,
};

export default CountyLevelMaps;
