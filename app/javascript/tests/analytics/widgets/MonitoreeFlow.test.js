import React from 'react'
import { shallow } from 'enzyme';
import MonitoreeFlow from '../../../components/analytics/widgets/MonitoreeFlow.js'
import mockMonitoreeSnapshot from '../../mocks/mockSnapshot'

const mocked_stats = {
  monitoree_snapshots: mockMonitoreeSnapshot
}

const allExpectedDomStrings = ['Last 24 Hours', 'Last 14 Days', 'Total', 'INCOMING', 'NEW ENROLLMENTS',
  'TRANSFERRED IN', 'OUTGOING', 'CLOSED', 'TRANSFERRED OUT'];

const allExpectedDomValues = {
  'total_closed': 14,
  'total_new_enrollments': 425,
  'total_transferred_in':  42,
  'total_transferred_out': 57,
  'last_14_days_closed': 10,
  'last_14_days_new_enrollments': 351,
  'last_14_days_transferred_in':  36,
  'last_14_days_transferred_out': 45,
  'last_24_hours_closed': 5,
  'last_24_hours_new_enrollments': 115,
  'last_24_hours_transferred_in':  14,
  'last_24_hours_transferred_out': 25,
}

let wrapped = shallow(<MonitoreeFlow stats={mocked_stats}/>);

describe('MonitoreeFlow', () => {
  it('Properly renders', () => {
    expect(wrapped).toMatchSnapshot();
  });
});