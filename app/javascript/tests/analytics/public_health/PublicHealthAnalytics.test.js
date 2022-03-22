import React from 'react';
import { shallow } from 'enzyme';
import { Button, Col } from 'react-bootstrap';
import Switch from 'react-switch';
import ReactTooltip from 'react-tooltip';
import PublicHealthAnalytics from '../../../components/analytics/public_health/PublicHealthAnalytics';
import MonitoreeFlow from '../../../components/analytics/public_health/charts/MonitoreeFlow';
import PreferredReportingMethod from '../../../components/analytics/public_health/charts/PreferredReportingMethod';
import Demographics from '../../../components/analytics/public_health/charts/Demographics';
import ExposureSummary from '../../../components/analytics/public_health/charts/ExposureSummary';
import MonitoreesByEventDate from '../../../components/analytics/public_health/charts/MonitoreesByEventDate';
import GeographicSummary from '../../../components/analytics/public_health/charts/GeographicSummary';
import { mockUser1 } from '../../mocks/mockUsers';
import mockAnalyticsData from '../../mocks/mockAnalytics';
import { formatTimestamp } from '../../helpers';

function getWrapper(stats) {
  return shallow(<PublicHealthAnalytics current_user={mockUser1} stats={stats} />);
}

describe('PublicHealthAnalytics', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockAnalyticsData);
    expect(wrapper.find('.sr-only').text()).toEqual('Analytics');
    expect(wrapper.find(Col).at(0).find('i').hasClass('fa-info-circle')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(Col).at(0).text()).toContain('Last Updated At');
    expect(wrapper.find(Col).at(0).text()).toContain(formatTimestamp(mockAnalyticsData.last_updated_at));
    expect(wrapper.find('.export-png').exists()).toBe(true);
    expect(wrapper.find('.export-png').find('i').hasClass('fa-download')).toBe(true);
    expect(wrapper.find('.export-png').text()).toContain('EXPORT ANALYSIS AS PNG');
    expect(wrapper.find(MonitoreeFlow).exists()).toBe(true);
    expect(wrapper.find(PreferredReportingMethod).exists()).toBe(true);
    expect(wrapper.find('.display-5').text()).toEqual('Epidemiological Summary');
    expect(wrapper.find(Switch).exists()).toBe(true);
    expect(wrapper.find('.h5').at(0).text()).toEqual('Among Those Currently Under Active Monitoring');
    expect(wrapper.find('.h5').at(1).text()).toEqual('View Data as Graph');
    expect(wrapper.find(Demographics).exists()).toBe(true);
    expect(wrapper.find(ExposureSummary).exists()).toBe(true);
    expect(wrapper.find(MonitoreesByEventDate).exists()).toBe(true);
    expect(wrapper.find(GeographicSummary).exists()).toBe(true);
  });

  it('Properly renders error message if stats is not provided', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('.sr-only').text()).toEqual('Analytics');
    expect(wrapper.find('.h5').at(0).text()).toEqual('We are still crunching the latest numbers.');
    expect(wrapper.find('.h5').at(1).text()).toEqual('Please check back later...');
    expect(wrapper.find(MonitoreeFlow).exists()).toBe(false);
    expect(wrapper.find(PreferredReportingMethod).exists()).toBe(false);
    expect(wrapper.find(Demographics).exists()).toBe(false);
    expect(wrapper.find(ExposureSummary).exists()).toBe(false);
    expect(wrapper.find(MonitoreesByEventDate).exists()).toBe(false);
    expect(wrapper.find(GeographicSummary).exists()).toBe(false);
  });

  it('Clicking "Export PNG" button calls exportAsPNG method', () => {
    const wrapper = getWrapper(mockAnalyticsData);
    const exportSpy = jest.spyOn(wrapper.instance(), 'exportAsPNG');
    expect(exportSpy).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(exportSpy).toHaveBeenCalled();
  });

  it('Clicking "Epidemiological Summary" switch updates state.showGraphs', () => {
    const wrapper = getWrapper(mockAnalyticsData);
    expect(wrapper.state('showGraphs')).toBe(false);
    wrapper.find(Switch).simulate('change', true);
    expect(wrapper.state('showGraphs')).toBe(true);
    wrapper.find(Switch).simulate('change', false);
    expect(wrapper.state('showGraphs')).toBe(false);
  });
});
