import React from 'react'
import { shallow } from 'enzyme';
import { Button, Col } from 'react-bootstrap';
import Switch from 'react-switch';
import ReactTooltip from 'react-tooltip';
import PublicHealthAnalytics from '../../components/analytics/PublicHealthAnalytics.js'
import MonitoreeFlow from '../../components/analytics/widgets/MonitoreeFlow';
import PreferredReportingMethod from '../../components/analytics/widgets/PreferredReportingMethod';
import Demographics from '../../components/analytics/widgets/Demographics';
import ExposureSummary from '../../components/analytics/widgets/ExposureSummary';
import MonitoreesByEventDate from '../../components/analytics/widgets/MonitoreesByEventDate';
import GeographicSummary from '../../components/analytics/widgets/GeographicSummary';
import { mockUser1 } from '../mocks/mockUsers'
import mockAnalyticsData from '../mocks/mockAnalytics'
import { analyticsDateFormatter } from '../util.js'

function getWrapper(stats) {
  return shallow(<PublicHealthAnalytics current_user={mockUser1} stats={stats} />);
}

describe('PublicHealthAnalytics', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockAnalyticsData);
    expect(wrapper.find('.sr-only').text().includes('Analytics')).toBeTruthy();
    expect(wrapper.find(Col).at(0).find('i').hasClass('fa-info-circle')).toBeTruthy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(Col).at(0).text().includes('Last Updated At')).toBeTruthy();
    expect(wrapper.find(Col).at(0).text().includes(analyticsDateFormatter(mockAnalyticsData.last_updated_at))).toBeTruthy();
    expect(wrapper.find('.export-png').exists()).toBeTruthy();
    expect(wrapper.find('.export-png').find('i').hasClass('fa-download')).toBeTruthy();
    expect(wrapper.find('.export-png').text().includes('EXPORT ANALYSIS AS PNG')).toBeTruthy();
    expect(wrapper.find(MonitoreeFlow).exists()).toBeTruthy();
    expect(wrapper.find(PreferredReportingMethod).exists()).toBeTruthy();
    expect(wrapper.find('.display-5').text()).toEqual('Epidemiological Summary');
    expect(wrapper.find(Switch).exists()).toBeTruthy();
    expect(wrapper.find('.h5').at(0).text()).toEqual('Among Those Currently Under Active Monitoring');
    expect(wrapper.find('.h5').at(1).text()).toEqual('View Data as Graph');
    expect(wrapper.find(Demographics).exists()).toBeTruthy();
    expect(wrapper.find(ExposureSummary).exists()).toBeTruthy();
    expect(wrapper.find(MonitoreesByEventDate).exists()).toBeTruthy();
    expect(wrapper.find(GeographicSummary).exists()).toBeTruthy();
  });

  it('Properly renders error message if stats is not provided', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('.sr-only').text().includes('Analytics')).toBeTruthy();
    expect(wrapper.find('.h5').at(0).text()).toEqual('We are still crunching the latest numbers.');
    expect(wrapper.find('.h5').at(1).text()).toEqual('Please check back later...');
    expect(wrapper.find(MonitoreeFlow).exists()).toBeFalsy();
    expect(wrapper.find(PreferredReportingMethod).exists()).toBeFalsy();
    expect(wrapper.find(Demographics).exists()).toBeFalsy();
    expect(wrapper.find(ExposureSummary).exists()).toBeFalsy();
    expect(wrapper.find(MonitoreesByEventDate).exists()).toBeFalsy();
    expect(wrapper.find(GeographicSummary).exists()).toBeFalsy();
  });

  it('Clicking "Export PNG" button calls exportAsPNG method', () => {
    const wrapper = getWrapper(mockAnalyticsData);
    const exportSpy = jest.spyOn(wrapper.instance(), 'exportAsPNG');
    expect(exportSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(exportSpy).toHaveBeenCalled();
  });

  it('Clicking "Epidemiological Summary" switch updates state.showEpidemiologicalGraphs', () => {
    const wrapper = getWrapper(mockAnalyticsData);
    expect(wrapper.state('showEpidemiologicalGraphs')).toBeFalsy();
    wrapper.find(Switch).simulate('change', true);
    expect(wrapper.state('showEpidemiologicalGraphs')).toBeTruthy();
    wrapper.find(Switch).simulate('change', false);
    expect(wrapper.state('showEpidemiologicalGraphs')).toBeFalsy();
  });
});
