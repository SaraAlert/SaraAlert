import React from 'react'
import { shallow } from 'enzyme';
import { Badge } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import CurrentStatus from '../../components/subject/CurrentStatus.js'
import EligibilityTooltip from '../../components/util/EligibilityTooltip.js';

const reportEligibility = {
  eligible: false,
  household: false,
  reported: false,
  sent: false
}

function getWrapper(status, isolation) {
  return shallow(<CurrentStatus status={status} isolation={isolation} report_eligibility={reportEligibility} />);
}

describe('CurrentStatus', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper('exposure_symptomatic', false);
    expect(wrapper.find('h4').exists()).toBeTruthy();
    expect(wrapper.find('b').at(0).text().includes('Workflow:')).toBeTruthy();
    expect(wrapper.find(Badge).exists()).toBeTruthy();
    expect(wrapper.find('b').at(1).text().includes('Notification status is')).toBeTruthy();
    expect(wrapper.find(EligibilityTooltip).exists()).toBeTruthy();
  });

  it('Correctly renders exposure symptomatic status', () => {
    const wrapper = getWrapper('exposure_symptomatic', false);
    expect(wrapper.find('b').at(0).text().includes('Exposure Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('symptomatic');
    expect(wrapper.find(Badge).prop('variant')).toEqual('danger');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders exposure asymptomatic status', () => {
    const wrapper = getWrapper('exposure_asymptomatic', false);
    expect(wrapper.find('b').at(0).text().includes('Exposure Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('asymptomatic');
    expect(wrapper.find(Badge).prop('variant')).toEqual('success');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders exposure non-reporting status', () => {
    const wrapper = getWrapper('exposure_non_reporting', false);
    expect(wrapper.find('b').at(0).text().includes('Exposure Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('non-reporting');
    expect(wrapper.find(Badge).prop('variant')).toEqual('warning');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders exposure PUI status', () => {
    const wrapper = getWrapper('exposure_under_investigation', false);
    expect(wrapper.find('b').at(0).text().includes('Exposure Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('PUI');
    expect(wrapper.find(Badge).prop('variant')).toEqual('dark');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders purged status', () => {
    const wrapper = getWrapper('purged', false);
    expect(wrapper.find('b').at(0).text().includes('Exposure Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('purged');
    expect(wrapper.find(Badge).find('.badge-muted').exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders closed status', () => {
    const wrapper = getWrapper('closed', false);
    expect(wrapper.find('b').at(0).text().includes('Exposure Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('not currently being monitored');
    expect(wrapper.find(Badge).prop('variant')).toEqual('secondary');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders isolation requires review status', () => {
    const wrapper = getWrapper('isolation_requiring_review', true);
    expect(wrapper.find('b').at(0).text().includes('Isolation Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('requires review');
    expect(wrapper.find(Badge).prop('variant')).toEqual('danger');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders isolation requires review (symptomatic non test based) status', () => {
    const wrapper = getWrapper('isolation_symp_non_test_based', true);
    expect(wrapper.find('b').at(0).text().includes('Isolation Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('requires review (symptomatic non test based)');
    expect(wrapper.find(Badge).prop('variant')).toEqual('danger');
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('At least 10 days have passed since the symptom onset date and at least 24 hours have passed since the case last reported “Yes” for fever or use of fever-reducing medicine to the system. The system does not collect information on severity of symptoms. Public health will need to validate if other symptoms have improved.');
  });

  it('Correctly renders isolation requires review (asymptomatic non test based) status', () => {
    const wrapper = getWrapper('isolation_asymp_non_test_based', true);
    expect(wrapper.find('b').at(0).text().includes('Isolation Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('requires review (asymptomatic non test based)');
    expect(wrapper.find(Badge).prop('variant')).toEqual('danger');
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('At least 10 days have passed since the specimen collection date of a positive laboratory test and the monitoree has never reported symptoms.');
  });

  it('Correctly renders isolation requires review (test based) status', () => {
    const wrapper = getWrapper('isolation_test_based', true);
    expect(wrapper.find('b').at(0).text().includes('Isolation Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('requires review (test based)');
    expect(wrapper.find(Badge).prop('variant')).toEqual('danger');
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Two negative laboratory results have been documented and at least 24 hours have passed since the case last reported “Yes” for fever or use of fever-reducing medicine to the system. The system does not validate the type of test, time between specimen collection, or if the tests were consecutive. Public health will need to validate that the test results meet the latest guidance prior to discontinuing isolation. The system does not collect information on severity of symptoms. Public health will also need to validate if other symptoms have improved.');
  });

  it('Correctly renders isolation non-reporting status', () => {
    const wrapper = getWrapper('isolation_non_reporting', true);
    expect(wrapper.find('b').at(0).text().includes('Isolation Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('non-reporting');
    expect(wrapper.find(Badge).prop('variant')).toEqual('warning');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Correctly renders isolation reporting status', () => {
    const wrapper = getWrapper('isolation_reporting', true);
    expect(wrapper.find('b').at(0).text().includes('Isolation Workflow')).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('reporting');
    expect(wrapper.find(Badge).prop('variant')).toEqual('success');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Displays unknown status message if status is not valid', () => {
    const wrapper = getWrapper('fake_status', false);
    expect(wrapper.find(Badge).exists()).toBeFalsy();
    expect(wrapper.find('b').at(0).find('span').text()).toEqual('unknown');
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });
});
