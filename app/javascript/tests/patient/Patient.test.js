import React from 'react'
import { shallow } from 'enzyme';
import { Button, Col, Collapse, Row } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import Patient from '../../components/patient/Patient.js'
import BadgeHOH from '../../components/util/BadgeHOH';
import ChangeHOH from '../../components/subject/ChangeHOH';
import MoveToHousehold from '../../components/subject/MoveToHousehold';
import RemoveFromHousehold from '../../components/subject/RemoveFromHousehold';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5, blankMockPatient } from '../mocks/mockPatients'
import { nameFormatter, dateFormatter } from '../util.js'

const goToMock = jest.fn();
const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const hohTableHeaders = [ 'Name', 'Workflow', 'Monitoring Status', 'Continuous Exposure?' ];
const identificationFields = [ 'DOB', 'Age', 'Language', 'State/Local ID', 'CDC ID', 'NNDSS ID', 'Birth Sex', 'Gender Identity', 'Sexual Orientation', 'Race', 'Ethnicity', 'Nationality' ];
const contactFields = [ 'Phone', 'Preferred Contact Time', 'Primary Telephone Type', 'Email', 'Preferred Reporting Method' ];
const domesticAddressFields = [ 'Address 1', 'Address 2', 'Town/City', 'State', 'Zip', 'County'];
const foreignAddressFields = [ 'Address 1', 'Address 2', 'Address 3', 'Town/City', 'State', 'Zip', 'Country' ];
const additionalTravelFields = [ 'Type', 'Place', 'Port of Departure', 'Start Date', 'End Date' ];
const riskFactors = [
  { key: 'Close Contact with a Known Case', val: mockPatient2.contact_of_known_case_id },
  { key: 'Member of a Common Exposure Cohort', val: mockPatient2.member_of_a_common_exposure_cohort_type },
  { key: 'Travel from Affected Country or Area', val: null },
  { key: 'Was in Healthcare Facility with Known Cases', val: mockPatient2.was_in_health_care_facility_with_known_cases_facility_name },
  { key: 'Laboratory Personnel', val: mockPatient2.laboratory_personnel_facility_name },
  { key: 'Healthcare Personnel', val: mockPatient2.healthcare_personnel_facility_name },
  { key: 'Crew on Passenger or Cargo Flight', val: null },
];

describe('Patient', () => {
  it('Properly renders all main components when not in editMode', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2 ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#monitoree-details-header').exists()).toBeTruthy();
    expect(wrapper.find('#monitoree-details-header').find('h3').find('span').text()).toEqual(nameFormatter(mockPatient1));
    expect(wrapper.find('#monitoree-details-header').find(BadgeHOH).exists()).toBeTruthy();
    expect(wrapper.find('.jurisdiction-user-box').exists()).toBeTruthy();
    expect(wrapper.find('#jurisdiction-path').text()).toEqual('Assigned Jurisdiction: USA, State 1, County 2');
    expect(wrapper.find('#assigned-user').text()).toEqual('Assigned User: ' + mockPatient1.assigned_user);
    expect(wrapper.find('#identification').exists()).toBeTruthy();
    expect(wrapper.find('#contact-information').exists()).toBeTruthy();
    expect(wrapper.find('.details-expander').exists()).toBeTruthy();
    expect(wrapper.find('#address').exists()).toBeTruthy();
    expect(wrapper.find('#arrival-information').exists()).toBeTruthy();
    expect(wrapper.find('#planned-travel').exists()).toBeTruthy();
    expect(wrapper.find('#potential-exposure-information').exists()).toBeTruthy();
    expect(wrapper.find('#exposure-notes').exists()).toBeTruthy();
    expect(wrapper.find('#case-information').exists()).toBeTruthy();
    expect(wrapper.find('.household-info').exists()).toBeTruthy();
  });

  it('Properly renders all main components when in editMode', () => {
    const wrapper = shallow(<Patient details={mockPatient1} goto={goToMock} editMode={true}
      jurisdiction_path='USA, State 1, County 2'  />);
    expect(wrapper.find('#monitoree-details-header').exists()).toBeTruthy();
    expect(wrapper.find('#monitoree-details-header').find('h3').find('span').text()).toEqual(nameFormatter(mockPatient1));
    expect(wrapper.find('#monitoree-details-header').find(BadgeHOH).exists()).toBeFalsy();
    expect(wrapper.find('.jurisdiction-user-box').exists()).toBeTruthy();
    expect(wrapper.find('#jurisdiction-path').text()).toEqual('Assigned Jurisdiction: USA, State 1, County 2');
    expect(wrapper.find('#assigned-user').text()).toEqual('Assigned User: ' + mockPatient1.assigned_user);
    expect(wrapper.find('#identification').exists()).toBeTruthy();
    expect(wrapper.find('#contact-information').exists()).toBeTruthy();
    expect(wrapper.find('.details-expander').exists()).toBeFalsy();
    expect(wrapper.find('#address').exists()).toBeTruthy();
    expect(wrapper.find('#arrival-information').exists()).toBeTruthy();
    expect(wrapper.find('#planned-travel').exists()).toBeTruthy();
    expect(wrapper.find('#potential-exposure-information').exists()).toBeTruthy();
    expect(wrapper.find('#exposure-notes').exists()).toBeTruthy();
    expect(wrapper.find('#case-information').exists()).toBeTruthy();
    expect(wrapper.find('.household-info').exists()).toBeFalsy();
  });

  it('Properly renders identification section', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#identification');
    expect(section.find('h4').text()).toEqual('Identification');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    identificationFields.forEach(function(field, index) {
      expect(section.find('b').at(index).text()).toEqual(field + ':');
    });
  });

  it('Properly renders contact information section', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#contact-information');
    expect(section.find('h4').text()).toEqual('Contact Information');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    contactFields.forEach(function(field, index) {
      expect(section.find('b').at(index).text()).toEqual(field + ':');
    });
  });

  it('Properly renders show/hide divider when expanded is false', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2 ]} goto={goToMock} hideBody={true}
      editMode={false} jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('.details-expander').exists()).toBeTruthy();
    expect(wrapper.find('#details-expander-link').exists()).toBeTruthy();
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).exists()).toBeTruthy();
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).hasClass('chevron-closed')).toBeTruthy();
    expect(wrapper.find('#details-expander-link').find('span').text()).toEqual('Show address, travel, exposure, and case information');
    expect(wrapper.find('.details-expander').find('span').at(1).hasClass('dashed-line')).toBeTruthy();
  });

  it('Properly renders show/hide divider when expanded is true', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2 ]} goto={goToMock} hideBody={true}
      editMode={false} jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('.details-expander').exists()).toBeTruthy();
    expect(wrapper.find('#details-expander-link').exists()).toBeTruthy();
    wrapper.find('#details-expander-link').simulate('click');
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).exists()).toBeTruthy();
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).hasClass('chevron-opened')).toBeTruthy();
    expect(wrapper.find('#details-expander-link').find('span').text()).toEqual('Hide address, travel, exposure, and case information');
    expect(wrapper.find('.details-expander').find('span').at(1).hasClass('dashed-line')).toBeTruthy();
  });

  it('Clicking show/hide divider updates label and expands or collapses details', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2 ]} goto={goToMock} hideBody={true}
      editMode={false} jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find(Collapse).prop('in')).toBeFalsy();
    expect(wrapper.state('expanded')).toBeFalsy();
    wrapper.find('#details-expander-link').simulate('click');
    expect(wrapper.find(Collapse).prop('in')).toBeTruthy();
    expect(wrapper.state('expanded')).toBeTruthy();
    wrapper.find('#details-expander-link').simulate('click');
    expect(wrapper.find(Collapse).prop('in')).toBeFalsy();
    expect(wrapper.state('expanded')).toBeFalsy();
  });

  it('Properly renders address section for domestic address with no monitoring address', () => {
    const wrapper = shallow(<Patient details={mockPatient2} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#address');
    expect(section.find('h4').text()).toEqual('Address');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find(Row).find(Col).length).toEqual(1);
    const domesticAddressColumn = section.find(Row).find(Col);
    expect(domesticAddressColumn.prop('sm')).toEqual(24);
    expect(domesticAddressColumn.find('p').text()).toEqual('Home Address (USA)');
    domesticAddressFields.forEach(function(field, index) {
      expect(domesticAddressColumn.find('b').at(index).text()).toEqual(field + ':');
    });
  });

  it('Properly renders address section for domestic address and monitoring address', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#address');
    expect(section.find('h4').text()).toEqual('Address');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find(Row).find(Col).length).toEqual(2);
    const domesticAddressColumn = section.find(Row).find(Col).at(0);
    const monitoringAddressColumn = section.find(Row).find(Col).at(1);
    expect(domesticAddressColumn.prop('sm')).toEqual(12);
    expect(domesticAddressColumn.find('p').text()).toEqual('Home Address (USA)');
    domesticAddressFields.forEach(function(field, index) {
      expect(domesticAddressColumn.find('b').at(index).text()).toEqual(field + ':');
    });
    expect(monitoringAddressColumn.prop('sm')).toEqual(12);
    expect(monitoringAddressColumn.find('p').text()).toEqual('Monitoring Address');
    domesticAddressFields.forEach(function(field, index) {
      expect(monitoringAddressColumn.find('b').at(index).text()).toEqual(field + ':');
    });
  });

  it('Properly renders address section for foreign address with no monitoring address', () => {
    const wrapper = shallow(<Patient details={mockPatient5} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#address');
    expect(section.find('h4').text()).toEqual('Address');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find(Row).find(Col).length).toEqual(1);
    const foreignAddressColumn = section.find(Row).find(Col);
    expect(foreignAddressColumn.prop('sm')).toEqual(24);
    expect(foreignAddressColumn.find('p').text()).toEqual('Home Address (Foreign)');
    foreignAddressFields.forEach(function(field, index) {
      expect(foreignAddressColumn.find('b').at(index).text()).toEqual(field + ':');
    });
  });

  it('Properly renders address section for foreign address and monitoring address', () => {
    const wrapper = shallow(<Patient details={mockPatient4} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#address');
    expect(section.find('h4').text()).toEqual('Address');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find(Row).find(Col).length).toEqual(2);
    const foreignAddressColumn = section.find(Row).find(Col).at(0);
    const monitoringAddressColumn = section.find(Row).find(Col).at(1);
    expect(foreignAddressColumn.prop('sm')).toEqual(12);
    expect(foreignAddressColumn.find('p').text()).toEqual('Home Address (Foreign)');
    foreignAddressFields.forEach(function(field, index) {
      expect(foreignAddressColumn.find('b').at(index).text()).toEqual(field + ':');
    });
    expect(monitoringAddressColumn.prop('sm')).toEqual(12);
    expect(monitoringAddressColumn.find('p').text()).toEqual('Monitoring Address');
    domesticAddressFields.forEach(function(field, index) {
      expect(monitoringAddressColumn.find('b').at(index).text()).toEqual(field + ':');
    });
  });

  it('Properly renders arrival information section', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#arrival-information');
    expect(section.find('h4').text()).toEqual('Arrival Information');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find('.none-text').exists()).toBeFalsy();
    const departedColumn = section.find(Row).find(Col).at(0);
    const arrivalColumn = section.find(Row).find(Col).at(1);
    const transportationColumn = section.find(Row).find(Col).at(2);
    expect(departedColumn.find('p').text()).toEqual('Departed');
    expect(departedColumn.find('b').at(0).text()).toEqual('Port of Origin:');
    expect(departedColumn.find('span').at(0).text()).toEqual(mockPatient1.port_of_origin);
    expect(departedColumn.find('b').at(1).text()).toEqual('Date of Departure:');
    expect(departedColumn.find('span').at(1).text()).toEqual(dateFormatter(mockPatient1.date_of_departure));
    expect(arrivalColumn.find('p').text()).toEqual('Arrival');
    expect(arrivalColumn.find('b').at(0).text()).toEqual('Port of Entry:');
    expect(arrivalColumn.find('span').at(0).text()).toEqual(mockPatient1.port_of_entry_into_usa);
    expect(arrivalColumn.find('b').at(1).text()).toEqual('Date of Arrival:');
    expect(arrivalColumn.find('span').at(1).text()).toEqual(dateFormatter(mockPatient1.date_of_arrival));
    expect(transportationColumn.find('b').at(0).text()).toEqual('Carrier:');
    expect(transportationColumn.find('span').at(0).text()).toEqual(mockPatient1.flight_or_vessel_carrier);
    expect(transportationColumn.find('b').at(1).text()).toEqual('Flight or Vessel #:');
    expect(transportationColumn.find('span').at(1).text()).toEqual(mockPatient1.flight_or_vessel_number);
    expect(section.find('.notes-section').exists()).toBeTruthy();
    expect(wrapper.find('.notes-section').find(Button).exists()).toBeFalsy();
    expect(section.find('.notes-section').find('p').text()).toEqual('Notes');
    expect(section.find('.notes-text').text()).toEqual(mockPatient1.travel_related_notes);
  });

  it('Collapses/expands travel related notes if longer than 400 characters', () => {
    const wrapper = shallow(<Patient details={mockPatient3} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).exists()).toBeTruthy();
    expect(wrapper.state('expandArrivalNotes')).toBeFalsy();
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#arrival-information').find('.notes-section').find('.notes-text').find('div').text())
      .toEqual(mockPatient3.travel_related_notes.slice(0, 400) + ' ...');
    wrapper.find('#arrival-information').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandArrivalNotes')).toBeTruthy();
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('#arrival-information').find('.notes-section').find('.notes-text').find('div').text())
      .toEqual(mockPatient3.travel_related_notes);
    wrapper.find('#arrival-information').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandArrivalNotes')).toBeFalsy();
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#arrival-information').find('.notes-section').find('.notes-text').find('div').text())
      .toEqual(mockPatient3.travel_related_notes.slice(0, 400) + ' ...');
  });

  it('Displays "None" if arrival information has no information', () => {
    const wrapper = shallow(<Patient details={blankMockPatient} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#arrival-information');
    expect(section.exists()).toBeTruthy();
    expect(section.find('.none-text').exists()).toBeTruthy();
    expect(section.find('.none-text').text()).toEqual('None');
  });

  it('Properly renders planned travel section', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#planned-travel');
    expect(section.find('h4').text()).toEqual('Additional Planned Travel');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find('.none-text').exists()).toBeFalsy();
    additionalTravelFields.forEach(function(field, index) {
      expect(section.find('b').at(index).text()).toEqual(field + ':');
    });
    expect(section.find('.notes-section').exists()).toBeTruthy();
    expect(wrapper.find('.notes-section').find(Button).exists()).toBeFalsy();
    expect(section.find('.notes-section').find('p').text()).toEqual('Notes');
    expect(section.find('.notes-text').text()).toEqual(mockPatient1.additional_planned_travel_related_notes);
  });

  it('Collapses/expands additional planned travel notes if longer than 400 characters', () => {
    const wrapper = shallow(<Patient details={mockPatient3} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).exists()).toBeTruthy();
    expect(wrapper.state('expandPlannedTravelNotes')).toBeFalsy();
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#planned-travel').find('.notes-section').find('.notes-text').find('div').text())
      .toEqual(mockPatient3.additional_planned_travel_related_notes.slice(0, 400) + ' ...');
    wrapper.find('#planned-travel').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandPlannedTravelNotes')).toBeTruthy();
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('#planned-travel').find('.notes-section').find('.notes-text').find('div').text())
      .toEqual(mockPatient3.additional_planned_travel_related_notes);
    wrapper.find('#planned-travel').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandPlannedTravelNotes')).toBeFalsy();
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#planned-travel').find('.notes-section').find('.notes-text').find('div').text())
      .toEqual(mockPatient3.additional_planned_travel_related_notes.slice(0, 400) + ' ...');
  });

  it('Displays "None" if planned travel has no information', () => {
    const wrapper = shallow(<Patient details={blankMockPatient} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#planned-travel');
    expect(section.exists()).toBeTruthy();
    expect(section.find('.none-text').exists()).toBeTruthy();
    expect(section.find('.none-text').text()).toEqual('None');
  });

  it('Properly renders potential exposure information section', () => {
    const wrapper = shallow(<Patient details={mockPatient2} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#potential-exposure-information');
    expect(section.find('h4').text()).toEqual('Potential Exposure Information');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find('.item-group').exists()).toBeTruthy();
    expect(section.find('.item-group').find('b').at(0).text()).toEqual('Last Date of Exposure:');
    expect(section.find('.item-group').find('span').at(0).text()).toEqual(dateFormatter(mockPatient2.last_date_of_exposure));
    expect(section.find('.item-group').find('b').at(1).text()).toEqual('Exposure Location:');
    expect(section.find('.item-group').find('span').at(1).text()).toEqual(mockPatient2.potential_exposure_location);
    expect(section.find('.item-group').find('b').at(2).text()).toEqual('Exposure Country:');
    expect(section.find('.item-group').find('span').at(2).text()).toEqual(mockPatient2.potential_exposure_country);
    expect(section.find('.risk-factors').exists()).toBeTruthy();
    riskFactors.forEach(function(field, index) {
      expect(section.find('li').at(index).find('.risk-factor').text()).toEqual(field.key);
      if (field.val) {
        expect(section.find('li').at(index).find('.risk-val').text()).toEqual(field.val);
      } else {
        expect(section.find('li').at(index).find('.risk-val').exists()).toBeFalsy();
      }
    });
    expect(section.find('.notes-section').exists()).toBeFalsy();
  });

  it('Properly renders notes in potential exposure information section if the rest of the section is empty', () => {
    let newMockPatient5 = _.cloneDeep(mockPatient5);
    newMockPatient5.exposure_notes = 'new exposure note';
    const wrapper = shallow(<Patient details={newMockPatient5} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#potential-exposure-information');
    expect(section.find('.item-group').exists()).toBeFalsy();
    expect(section.find('.risk-factors').exists()).toBeFalsy();
    expect(section.find('.notes-section').exists()).toBeTruthy();
    expect(wrapper.find('.notes-section').find(Button).exists()).toBeFalsy();
    expect(section.find('.notes-section').find('p').text()).toEqual('Notes');
    expect(section.find('.notes-text').text()).toEqual(newMockPatient5.exposure_notes);
  });

  it('Collapses/expands exposure notes in potential exposure information section if longer than 400 characters', () => {
    const wrapper = shallow(<Patient details={mockPatient5} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#potential-exposure-information').find(Button).exists()).toBeTruthy();
    expect(wrapper.find('#potential-exposure-information').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#potential-exposure-information').find('.notes-text').text()).toEqual(mockPatient5.exposure_notes.slice(0, 400) + ' ...');
    wrapper.find('#potential-exposure-information').find(Button).simulate('click');
    expect(wrapper.find('#potential-exposure-information').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('#potential-exposure-information').find('.notes-text').text()).toEqual(mockPatient5.exposure_notes);
    wrapper.find('#potential-exposure-information').find(Button).simulate('click');
    expect(wrapper.find('#potential-exposure-information').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#potential-exposure-information').find('.notes-text').text()).toEqual(mockPatient5.exposure_notes.slice(0, 400) + ' ...');
  });

  it('Displays "None" if potential exposure information has no information', () => {
    const wrapper = shallow(<Patient details={blankMockPatient} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#potential-exposure-information');
    expect(section.exists()).toBeTruthy();
    expect(section.find('.none-text').exists()).toBeTruthy();
    expect(section.find('.none-text').text()).toEqual('None');
    expect(section.find('.item-group').exists()).toBeFalsy();
    expect(section.find('.risk-factors').exists()).toBeFalsy();
    expect(section.find('.notes-section').exists()).toBeFalsy();
  });

  it('Properly renders case information section', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#case-information');
    expect(section.find('h4').text()).toEqual('Case Information');
    expect(section.find('.edit-link').find(Button).exists()).toBeFalsy();
    expect(section.find('b').at(0).text()).toEqual('Symptom Onset:');
    expect(section.find('span').at(0).text()).toEqual(dateFormatter(mockPatient1.symptom_onset));
    expect(section.find('b').at(1).text()).toEqual('Case Status:');
    expect(section.find('span').at(1).text()).toEqual(mockPatient1.case_status);
  });

  it('Hides case information section when monitoree is in the exposure workflow', () => {
    const wrapper = shallow(<Patient details={mockPatient2} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />)
    expect(wrapper.find('#case-information').exists()).toBeFalsy();
  });

  it('Properly renders notes section', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#exposure-notes');
    expect(section.find('h4').text()).toEqual('Notes');
    expect(section.find('.none-text').exists()).toBeFalsy();
    expect(section.find('.notes-text').exists()).toBeTruthy();
    expect(section.find('.notes-text').text()).toEqual(mockPatient1.exposure_notes);
    expect(section.find(Button).exists()).toBeFalsy();
  });

  it('Collapses/expands exposure notes if longer than 400 characters', () => {
    const wrapper = shallow(<Patient details={mockPatient3} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#exposure-notes').find(Button).exists()).toBeTruthy();
    expect(wrapper.find('#exposure-notes').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#exposure-notes').find('.notes-text').text()).toEqual(mockPatient3.exposure_notes.slice(0, 400) + ' ...');
    wrapper.find('#exposure-notes').find(Button).simulate('click');
    expect(wrapper.find('#exposure-notes').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('#exposure-notes').find('.notes-text').text()).toEqual(mockPatient3.exposure_notes);
    wrapper.find('#exposure-notes').find(Button).simulate('click');
    expect(wrapper.find('#exposure-notes').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#exposure-notes').find('.notes-text').text()).toEqual(mockPatient3.exposure_notes.slice(0, 400) + ' ...');
  });

  it('Displays "None" if exposure notes is null', () => {
    const wrapper = shallow(<Patient details={mockPatient4} dependents={[ ]} hideBody={true} editMode={false}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    const section = wrapper.find('#exposure-notes');
    expect(section.exists()).toBeTruthy();
    expect(section.find('.none-text').exists()).toBeTruthy();
    expect(section.find('.none-text').text()).toEqual('None');
    expect(section.find('.notes-text').exists()).toBeFalsy();
    expect(section.find(Button).exists()).toBeFalsy();
  });

  it('Properly renders HoH section and name HoH badge', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2, blankMockPatient ]} goto={goToMock}
      hideBody={true} jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#monitoree-details-header').find(BadgeHOH).exists()).toBeTruthy();
    expect(wrapper.find('#head-of-household').exists()).toBeTruthy();
    expect(wrapper.find('#head-of-household').find(Row).at(1).text())
      .toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
    expect(wrapper.find(ChangeHOH).exists()).toBeTruthy();
    expect(wrapper.find(RemoveFromHousehold).exists()).toBeFalsy();
    expect(wrapper.find(MoveToHousehold).exists()).toBeFalsy();
    hohTableHeaders.forEach(function(header, index) {
      expect(wrapper.find('thead th').at(index).text()).toEqual(header);
    });
    expect(wrapper.find('tbody tr').length).toEqual(2);
  });

  it('Properly renders household member section and name HoH badge', () => {
    const wrapper = shallow(<Patient details={mockPatient2} dependents={[ ]} goto={goToMock} hideBody={true}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#monitoree-details-header').find(BadgeHOH).exists()).toBeFalsy();
    expect(wrapper.find('#household-member-not-hoh').exists()).toBeTruthy();
    expect(wrapper.find('#household-member-not-hoh').find(Row).first().text())
      .toEqual('The reporting responsibility for this monitoree is handled by another monitoree. Click here to view that monitoree.');
    expect(wrapper.find('#household-member-not-hoh a').prop('href')).toEqual('/patients/17');
    expect(wrapper.find(RemoveFromHousehold).exists()).toBeTruthy();
    expect(wrapper.find(MoveToHousehold).exists()).toBeFalsy();
    expect(wrapper.find(ChangeHOH).exists()).toBeFalsy();
  });

  it('Properly renders single member (not in household) section and name HoH badge', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ ]} goto={goToMock} hideBody={true}
      jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('#monitoree-details-header').find(BadgeHOH).exists()).toBeFalsy();
    expect(wrapper.find('#no-household').exists()).toBeTruthy();
    expect(wrapper.find('#no-household').find(Row).at(1).text()).toEqual('This monitoree is not a member of a household:');
    expect(wrapper.find(MoveToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(ChangeHOH).exists()).toBeFalsy();
    expect(wrapper.find(RemoveFromHousehold).exists()).toBeFalsy();
  });

  it('Properly renders no details message', () => {
    const blankWrapper = shallow(<Patient />);
    expect(blankWrapper.text()).toEqual('No monitoree details to show.');
  });

  it('Renders edit buttons if props.goto is defined', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2 ]} goto={goToMock} hideBody={false}
      editMode={true} jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(wrapper.find('.edit-link').find(Button).length).toEqual(7);
    wrapper.find('.edit-link').find(Button).forEach(function(btn) {
      expect(btn.text()).toEqual('Edit');
    });
  });

  it('Calls props goto method when the edit buttons are clicked', () => {
    const wrapper = shallow(<Patient details={mockPatient1} dependents={[ mockPatient2 ]} goto={goToMock} hideBody={false}
      editMode={true} jurisdiction_path='USA, State 1, County 2' authenticity_token={authyToken} />);
    expect(goToMock).toHaveBeenCalledTimes(0);
    wrapper.find('.edit-link').find(Button).forEach(function(btn, index) {
      btn.simulate('click');
      expect(goToMock).toHaveBeenCalledTimes(index+1);
    });
  });
});
