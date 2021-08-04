import React from 'react';
import { shallow } from 'enzyme';
import moment from 'moment';

import MonitoringPeriod from '../../../../components/patient/assessment/actions/MonitoringPeriod';
import { mockPatient1, mockPatient2 } from '../../../mocks/mockPatients';

import SymptomOnset from '../../../../components/patient/assessment/actions/SymptomOnset';
import LastDateExposure from '../../../../components/patient/assessment/actions/LastDateExposure';
import ExtendedIsolation from '../../../../components/patient/assessment/actions/ExtendedIsolation';
import InfoTooltip from '../../../../components/util/InfoTooltip';

function getWrapper(patient) {
  return shallow(<MonitoringPeriod patient={patient} />);
}

describe('MonitoringPeriod', () => {
  it('Properly renders symptom onset and extended isolation when patient is in isolation workflow', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(SymptomOnset).exists()).toBe(true);
    expect(wrapper.find(LastDateExposure).exists()).toBe(false);
    expect(wrapper.find(ExtendedIsolation).exists()).toBe(true);
    expect(wrapper.find(InfoTooltip).exists()).toBe(false);
    expect(wrapper.find('#end_of_monitoring_date').exists()).toBe(false);
  });

  it('Properly renders symptom onset, last date of exposure, and end of monitoring when patient is in exposure workflow', () => {
    const wrapper = getWrapper(mockPatient2);
    expect(wrapper.find(SymptomOnset).exists()).toBe(true);
    expect(wrapper.find(LastDateExposure).exists()).toBe(true);
    expect(wrapper.find(ExtendedIsolation).exists()).toBe(false);
    expect(wrapper.find('.input-label').text()).toEqual('END OF MONITORING');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find('#end_of_monitoring_date').text()).toEqual(moment(mockPatient2.linelist.end_of_monitoring).format('MM/DD/YYYY'));
  });
});
