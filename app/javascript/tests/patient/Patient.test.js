import React from 'react';
import { shallow } from 'enzyme';
import { Button, Col, Collapse, Row } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';

import Patient from '../../components/patient/Patient';
import FollowUpFlagPanel from '../../components/patient/follow_up_flag/FollowUpFlagPanel';
import CommonExposureCohortTable from '../../components/patient/common_exposure_cohorts/CommonExposureCohortsTable';
import InfoTooltip from '../../components/util/InfoTooltip';
import BadgeHoH from '../../components/patient/icons/BadgeHoH';
import { Heading } from '../../utils/Heading';
import { mockUser1 } from '../mocks/mockUsers';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5, mockPatient6, blankIsolationMockPatient, blankExposureMockPatient } from '../mocks/mockPatients';
import { mockJurisdictionPaths } from '../mocks/mockJurisdiction';
import { formatName, formatDate, formatRace, convertCommonLanguageCodeToName } from '../helpers';

const goToMock = jest.fn();
const identificationLabels = ['DOB', 'Age', 'Language', 'Sara Alert ID', 'State/Local ID', 'CDC ID', 'NNDSS ID', 'Birth Sex', 'Gender Identity', 'Sexual Orientation', 'Race', 'Ethnicity', 'Nationality'];
const identificationFields = ['date_of_birth', 'age', 'primary_language', 'id', 'user_defined_id_statelocal', 'user_defined_id_cdc', 'user_defined_id_nndss', 'sex', 'gender_identity', 'sexual_orientation', 'race', 'ethnicity', 'nationality'];
const contactLabels = ['Contact Name', 'Contact Relationship', 'Phone', 'Preferred Contact Time', 'Primary Telephone Type', 'Email', 'Preferred Reporting Method'];
const contactFields = ['contact_name', 'contact_type', 'primary_telephone', 'preferred_contact_time', 'primary_telephone_type', 'email', 'preferred_contact_method'];
const selfContactLabels = _.filter(contactLabels, l => l !== 'Contact Name');
const selfContactFields = _.filter(contactFields, l => l !== 'contact_name');
const secondaryContactLabels = ['Secondary Phone', 'Secondary Phone Type', 'International Phone'];
const secondaryContactFields = ['secondary_telephone', 'secondary_telephone_type', 'international_telephone'];
const alternateContactLabels = ['Contact Name', 'Contact Relationship', 'Phone', 'Preferred Contact Time', 'Primary Telephone Type', 'Email', 'Preferred Contact Method'];
const alternateContactFields = contactFields.map(field => `alternate_${field}`);
const alternateSecondaryContactLabels = secondaryContactLabels;
const alternateSecondaryContactFields = secondaryContactFields.map(field => `alternate_${field}`);
const domesticAddressLabels = ['Address 1', 'Address 2', 'Town/City', 'State', 'Zip', 'County'];
const domesticAddressFields = ['address_line_1', 'address_line_2', 'address_city', 'address_state', 'address_zip', 'address_county'];
const foreignAddressLabels = ['Address 1', 'Address 2', 'Address 3', 'Town/City', 'State', 'Zip', 'Country'];
const foreignAddressFields = ['foreign_address_line_1', 'foreign_address_line_2', 'foreign_address_line_3', 'foreign_address_city', 'foreign_address_state', 'foreign_address_zip', 'foreign_address_country'];
const monitoringAddressLabels = domesticAddressLabels;
const monitoringAddressFields = ['monitored_address_line_1', 'monitored_address_line_2', 'monitored_address_city', 'monitored_address_state', 'monitored_address_zip', 'monitored_address_county'];
const plannedTravelLabels = ['Type', 'Place', 'Port of Departure', 'Start Date', 'End Date'];
const plannedTravelFields = ['additional_planned_travel_type', ['additional_planned_travel_destination_country', 'additional_planned_travel_destination_state'], 'additional_planned_travel_port_of_departure', 'additional_planned_travel_start_date', 'additional_planned_travel_end_date'];
const riskFactors = [
  { key: 'Close Contact with a Known Case', val: mockPatient2.contact_of_known_case_id },
  { key: 'Travel from Affected Country or Area', val: null },
  { key: 'Was in Healthcare Facility with Known Cases', val: mockPatient2.was_in_health_care_facility_with_known_cases_facility_name },
  { key: 'Laboratory Personnel', val: mockPatient2.laboratory_personnel_facility_name },
  { key: 'Healthcare Personnel', val: mockPatient2.healthcare_personnel_facility_name },
  { key: 'Crew on Passenger or Cargo Flight', val: null },
  { key: 'Member of a Common Exposure Cohort', val: null },
];

function getWrapper(additionalProps) {
  return shallow(<Patient current_user={mockUser1} collapse={true} edit_mode={false} jurisdiction_paths={mockJurisdictionPaths} other_household_members={[]} can_modify_subject_status={true} workflow="global" headingLevel={2} {...additionalProps} />);
}

describe('Patient', () => {
  it('Properly renders all main components when not in edit mode', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('#monitoree-details-header').exists()).toBe(true);
    expect(wrapper.find('#monitoree-details-header').find(Heading).find('span').text()).toEqual(formatName(mockPatient1));
    expect(wrapper.find('#monitoree-details-header').find(Heading).find(BadgeHoH).exists()).toBe(true);
    expect(wrapper.find(FollowUpFlagPanel).exists()).toBe(false);
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBe(true);
    expect(wrapper.find('.jurisdiction-user-box').exists()).toBe(true);
    expect(wrapper.find('#jurisdiction-path').text()).toEqual('Assigned Jurisdiction: USA, State 1, County 2');
    expect(wrapper.find('#assigned-user').text()).toEqual('Assigned User: ' + mockPatient1.assigned_user);
    expect(wrapper.find('#identification').exists()).toBe(true);
    expect(wrapper.find('#contact-information').exists()).toBe(true);
    expect(wrapper.find('.details-expander').exists()).toBe(true);
    expect(wrapper.find('#address').exists()).toBe(true);
    expect(wrapper.find('#arrival-information').exists()).toBe(true);
    expect(wrapper.find('#planned-travel').exists()).toBe(true);
    expect(wrapper.find('#potential-exposure-information').exists()).toBe(true);
    expect(wrapper.find('#exposure-notes').exists()).toBe(true);
    expect(wrapper.find('#case-information').exists()).toBe(true);
  });

  it('Properly renders all main components when in edit mode', () => {
    const additionalProps = { details: mockPatient4, goto: goToMock, edit_mode: true };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('#monitoree-details-header').exists()).toBe(true);
    expect(wrapper.find('#monitoree-details-header').find(Heading).find('span').text()).toEqual(formatName(mockPatient4));
    expect(wrapper.find('#monitoree-details-header').find(Heading).find(BadgeHoH).exists()).toBe(false);
    expect(wrapper.find(FollowUpFlagPanel).exists()).toBe(false);
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBe(false);
    expect(wrapper.find('.jurisdiction-user-box').exists()).toBe(true);
    expect(wrapper.find('#jurisdiction-path').text()).toEqual('Assigned Jurisdiction: USA, State 1, County 2');
    expect(wrapper.find('#assigned-user').text()).toEqual('Assigned User: ' + mockPatient4.assigned_user);
    expect(wrapper.find('#identification').exists()).toBe(true);
    expect(wrapper.find('#contact-information').exists()).toBe(true);
    expect(wrapper.find('.details-expander').exists()).toBe(false);
    expect(wrapper.find('#address').exists()).toBe(true);
    expect(wrapper.find('#arrival-information').exists()).toBe(true);
    expect(wrapper.find('#planned-travel').exists()).toBe(true);
    expect(wrapper.find('#potential-exposure-information').exists()).toBe(true);
    expect(wrapper.find('#exposure-notes').exists()).toBe(true);
    expect(wrapper.find('#case-information').exists()).toBe(true);
  });

  it('Properly renders identification section', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#identification');
    expect(section.find(Heading).children().text()).toEqual('Identification');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient1.id + '/edit?step=0&nav=global');
    expect(section.find('.text-danger').exists()).toBe(false);

    section
      .find('.item-group')
      .children()
      .forEach((item, index) => {
        let value = mockPatient1[identificationFields[parseInt(index)]];
        value = identificationFields[parseInt(index)].includes('date') ? formatDate(value) : value;
        value = identificationFields[parseInt(index)].includes('language') ? convertCommonLanguageCodeToName(value) : value;
        value = identificationFields[parseInt(index)] === 'race' ? formatRace(mockPatient1) : value;
        expect(item.find('b').text()).toEqual(identificationLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(String(value) || '--');
      });
  });

  it('Properly renders identification section when patient is a minor', () => {
    const additionalProps = { details: mockPatient5, hoh: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#identification');
    expect(section.find(Heading).children().text()).toEqual('Identification');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('.item-group').children().at(0).text()).toEqual(`DOB: ${formatDate(mockPatient5.date_of_birth)} (Minor)`);
    expect(section.find('.text-danger').exists()).toBe(true);
    expect(section.find('.text-danger').text()).toEqual(' (Minor)');
  });

  it('Properly renders contact information section without alternate contact', () => {
    const additionalProps = { details: mockPatient2 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#contact-information');
    expect(section.find(Heading).children().text()).toEqual('Contact Information');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient2.id + '/edit?step=2&nav=global');
    expect(section.find('.text-danger').exists()).toBe(false);
    expect(section.children().find(Col).length).toEqual(1);

    // primary contact information
    section
      .find('.item-group')
      .at(0)
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(selfContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient2[selfContactFields[parseInt(index)]] || '--');
      });

    // secondary contact information
    section
      .find('.item-group')
      .at(1)
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(secondaryContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient2[secondaryContactFields[parseInt(index)]] || '--');
      });
  });

  it('Properly renders contact information section with alternate contact', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#contact-information');
    expect(section.find(Heading).children().text()).toEqual('Contact Information');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient1.id + '/edit?step=2&nav=global');
    expect(section.find('.text-danger').exists()).toBe(false);
    expect(section.children().find(Col).length).toEqual(2);

    // primary contact information
    section
      .children()
      .find(Col)
      .at(0)
      .find('.item-group')
      .at(0)
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(selfContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient1[selfContactFields[parseInt(index)]] || '--');
      });

    // secondary contact information
    section
      .children()
      .find(Col)
      .at(0)
      .find('.item-group')
      .at(1)
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(secondaryContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient1[secondaryContactFields[parseInt(index)]] || '--');
      });

    // alternate contact information
    section
      .children()
      .find(Col)
      .at(1)
      .find('.item-group')
      .at(0)
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(alternateContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient1[alternateContactFields[parseInt(index)]] || '--');
      });

    // alternate secondary contact information
    section
      .children()
      .find(Col)
      .at(1)
      .find('.item-group')
      .at(1)
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(alternateSecondaryContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient1[alternateSecondaryContactFields[parseInt(index)]] || '--');
      });
  });

  it('Hides secondary contact info if it is not defined', () => {
    const additionalProps = { details: mockPatient3 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#contact-information');
    expect(section.find(Heading).children().text()).toEqual('Contact Information');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient3.id + '/edit?step=2&nav=global');
    expect(section.find('.text-danger').exists()).toBe(false);
    expect(section.children().find(Col).length).toEqual(2);

    // primary contact information
    expect(section.children().find(Col).at(0).find('.item-group').length).toEqual(1);
    section
      .children()
      .find(Col)
      .at(0)
      .find('.item-group')
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(contactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient3[contactFields[parseInt(index)]] || '--');
      });

    // alternate contact information
    expect(section.children().find(Col).at(1).find('.item-group').length).toEqual(1);
    section
      .children()
      .find(Col)
      .at(1)
      .find('.item-group')
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(alternateContactLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient3[alternateContactFields[parseInt(index)]] || '--');
      });
  });

  it('Properly renders contact information section if SMS is blocked', () => {
    const additionalProps = { details: { ...mockPatient6, blocked_sms: true } };
    const wrapper = getWrapper(additionalProps);
    const primaryPhone = wrapper.find('#contact-information').find('.item-group').children().find('div').at(2);
    const preferredContactMethod = wrapper.find('#contact-information').find('.item-group').children().find('div').at(6);

    expect(primaryPhone.find('b').text()).toEqual('Phone:');
    expect(primaryPhone.find('span').at(0).text()).toEqual(mockPatient6.primary_telephone);
    expect(primaryPhone.find('span').at(1).text()).toContain('SMS Blocked');
    expect(primaryPhone.find(InfoTooltip).exists()).toBe(true);
    expect(primaryPhone.find(InfoTooltip).prop('tooltipTextKey')).toEqual('blockedSMS');
    expect(preferredContactMethod.find('b').text()).toEqual('Preferred Reporting Method:');
    expect(preferredContactMethod.find('span').text()).toContain('SMS Texted Weblink');
    expect(preferredContactMethod.find(InfoTooltip).exists()).toBe(true);
    expect(preferredContactMethod.find(InfoTooltip).prop('tooltipTextKey')).toEqual('blockedSMSContactMethod');
  });

  it('Properly renders contact information section when patient is a minor where primary contact type is "Self"', () => {
    const additionalProps = { details: mockPatient4, hoh: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const primaryContactSection = wrapper.find('#contact-information').children().find(Col).at(0);
    const alternateContactSection = wrapper.find('#contact-information').children().find(Col).at(1);

    expect(primaryContactSection.find('.minor-info').exists()).toBe(true);
    expect(primaryContactSection.find('.text-danger').exists()).toBe(true);
    expect(primaryContactSection.find('.text-danger').text()).toEqual('Monitoree is a minor');
    expect(primaryContactSection.find('.minor-info').find('a').exists()).toBe(true);
    expect(primaryContactSection.find('.minor-info').children().at(1).text()).toEqual(`Reporting responsibility is handled by: ${mockPatient1.first_name} ${mockPatient1.middle_name} ${mockPatient1.last_name}`);
    expect(primaryContactSection.find('.minor-info').find('a').prop('href')).toContain('patients/' + mockPatient1.id);
    expect(primaryContactSection.find('.minor-info').find('a').text()).toEqual(mockPatient1.first_name + ' ' + mockPatient1.middle_name + ' ' + mockPatient1.last_name);
    expect(alternateContactSection.find('.minor-info').exists()).toBe(false);
  });

  it('Properly renders contact information section when patient is a minor where alternate contact type is "Self"', () => {
    const additionalProps = { details: mockPatient5, hoh: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const primaryContactSection = wrapper.find('#contact-information').children().find(Col).at(0);
    const alternateContactSection = wrapper.find('#contact-information').children().find(Col).at(1);

    expect(primaryContactSection.find('.minor-info').exists()).toBe(false);
    expect(alternateContactSection.find('.minor-info').exists()).toBe(true);
    expect(alternateContactSection.find('.text-danger').exists()).toBe(true);
    expect(alternateContactSection.find('.text-danger').text()).toEqual('Monitoree is a minor');
    expect(alternateContactSection.find('.minor-info').find('a').exists()).toBe(false);
  });

  it('Properly renders show/hide divider when props.collapse is true', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('.details-expander').exists()).toBe(true);
    expect(wrapper.find('#details-expander-link').exists()).toBe(true);
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).exists()).toBe(true);
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).hasClass('chevron-closed')).toBe(true);
    expect(wrapper.find('#details-expander-link').find('span').text()).toEqual('Show address, travel, exposure, and case information');
    expect(wrapper.find('.details-expander').find('span').at(1).hasClass('dashed-line')).toBe(true);
  });

  it('Properly renders show/hide divider when props.collapse is false', () => {
    const additionalProps = { details: mockPatient1, collapse: false };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('.details-expander').exists()).toBe(true);
    expect(wrapper.find('#details-expander-link').exists()).toBe(true);
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).exists()).toBe(true);
    expect(wrapper.find('.details-expander').find(FontAwesomeIcon).hasClass('chevron-opened')).toBe(true);
    expect(wrapper.find('#details-expander-link').find('span').text()).toEqual('Hide address, travel, exposure, and case information');
    expect(wrapper.find('.details-expander').find('span').at(1).hasClass('dashed-line')).toBe(true);
  });

  it('Clicking show/hide divider updates label and expands or collapses details', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find(Collapse).prop('in')).toBe(false);
    expect(wrapper.state('expanded')).toBe(false);
    wrapper.find('#details-expander-link').simulate('click');
    expect(wrapper.find(Collapse).prop('in')).toBe(true);
    expect(wrapper.state('expanded')).toBe(true);
    wrapper.find('#details-expander-link').simulate('click');
    expect(wrapper.find(Collapse).prop('in')).toBe(false);
    expect(wrapper.state('expanded')).toBe(false);
  });

  it('Properly renders address section for domestic address with no monitoring address', () => {
    const additionalProps = { details: mockPatient2 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#address');
    expect(section.find(Heading).children().text()).toEqual('Address');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient2.id + '/edit?step=1&nav=global');
    expect(section.find('.item-group').length).toEqual(1);
    expect(section.find('.item-group').prop('sm')).toEqual(24);
    expect(section.find('.item-group').find('p').text()).toEqual('Home Address (USA)');
    section
      .find('.item-group')
      .children()
      .filter('div')
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(domesticAddressLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient2[domesticAddressFields[parseInt(index)]] || '--');
      });
  });

  it('Properly renders address section for domestic address and monitoring address', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#address');
    expect(section.find(Heading).children().text()).toEqual('Address');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient1.id + '/edit?step=1&nav=global');
    expect(section.find('.item-group').length).toEqual(2);

    const domesticAddressColumn = section.find('.item-group').at(0);
    expect(domesticAddressColumn.prop('sm')).toEqual(12);
    expect(domesticAddressColumn.find('p').text()).toEqual('Home Address (USA)');
    domesticAddressColumn
      .children()
      .filter('div')
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(domesticAddressLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient1[domesticAddressFields[parseInt(index)]] || '--');
      });

    const monitoringAddressColumn = section.find('.item-group').at(1);
    expect(monitoringAddressColumn.prop('sm')).toEqual(12);
    expect(monitoringAddressColumn.find('p').text()).toEqual('Monitoring Address');
    monitoringAddressColumn
      .children()
      .filter('div')
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(monitoringAddressLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient1[monitoringAddressFields[parseInt(index)]] || '--');
      });
  });

  it('Properly renders address section for foreign address with no monitoring address', () => {
    const additionalProps = { details: mockPatient5 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#address');
    expect(section.find(Heading).children().text()).toEqual('Address');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient5.id + '/edit?step=1&nav=global');
    expect(section.find('.item-group').length).toEqual(1);
    expect(section.find('.item-group').prop('sm')).toEqual(24);
    expect(section.find('.item-group').find('p').text()).toEqual('Home Address (Foreign)');
    section
      .find('.item-group')
      .children()
      .filter('div')
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(foreignAddressLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient5[foreignAddressFields[parseInt(index)]] || '--');
      });
  });

  it('Properly renders address section for foreign address and monitoring address', () => {
    const additionalProps = { details: mockPatient4 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#address');
    expect(section.find(Heading).children().text()).toEqual('Address');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient4.id + '/edit?step=1&nav=global');
    expect(section.find('.item-group').length).toEqual(2);

    const foreignAddressColumn = section.find('.item-group').at(0);
    expect(foreignAddressColumn.prop('sm')).toEqual(12);
    expect(foreignAddressColumn.find('p').text()).toEqual('Home Address (Foreign)');
    foreignAddressColumn
      .children()
      .filter('div')
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(foreignAddressLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient4[foreignAddressFields[parseInt(index)]] || '--');
      });

    const monitoringAddressColumn = section.find('.item-group').at(1);
    expect(monitoringAddressColumn.prop('sm')).toEqual(12);
    expect(monitoringAddressColumn.find('p').text()).toEqual('Monitoring Address');
    monitoringAddressColumn
      .children()
      .filter('div')
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(monitoringAddressLabels[parseInt(index)] + ':');
        expect(item.find('span').text()).toEqual(mockPatient4[`foreign_${monitoringAddressFields[parseInt(index)]}`] || '--');
      });
  });

  it('Properly renders arrival information section', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#arrival-information');
    expect(section.find(Heading).children().text()).toEqual('Arrival Information');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient1.id + '/edit?step=3&nav=global');
    expect(section.find('.none-text').exists()).toBe(false);
    const departedColumn = section.find(Row).find(Col).at(0);
    const arrivalColumn = section.find(Row).find(Col).at(1);
    const transportationColumn = section.find(Row).find(Col).at(2);
    expect(departedColumn.find('p').text()).toEqual('Departed');
    expect(departedColumn.find('b').at(0).text()).toEqual('Port of Origin:');
    expect(departedColumn.find('span').at(0).text()).toEqual(mockPatient1.port_of_origin);
    expect(departedColumn.find('b').at(1).text()).toEqual('Date of Departure:');
    expect(departedColumn.find('span').at(1).text()).toEqual(formatDate(mockPatient1.date_of_departure));
    expect(arrivalColumn.find('p').text()).toEqual('Arrival');
    expect(arrivalColumn.find('b').at(0).text()).toEqual('Port of Entry:');
    expect(arrivalColumn.find('span').at(0).text()).toEqual(mockPatient1.port_of_entry_into_usa);
    expect(arrivalColumn.find('b').at(1).text()).toEqual('Date of Arrival:');
    expect(arrivalColumn.find('span').at(1).text()).toEqual(formatDate(mockPatient1.date_of_arrival));
    expect(transportationColumn.find('b').at(0).text()).toEqual('Carrier:');
    expect(transportationColumn.find('span').at(0).text()).toEqual(mockPatient1.flight_or_vessel_carrier);
    expect(transportationColumn.find('b').at(1).text()).toEqual('Flight or Vessel #:');
    expect(transportationColumn.find('span').at(1).text()).toEqual(mockPatient1.flight_or_vessel_number);
    expect(section.find('.notes-section').exists()).toBe(true);
    expect(wrapper.find('.notes-section').find(Button).exists()).toBe(false);
    expect(section.find('.notes-section').find('p').text()).toEqual('Notes');
    expect(section.find('.notes-text').text()).toEqual(mockPatient1.travel_related_notes);
  });

  it('Collapses/expands travel related notes if longer than 400 characters', () => {
    const additionalProps = { details: mockPatient3 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).exists()).toBe(true);
    expect(wrapper.state('expandArrivalNotes')).toBe(false);
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#arrival-information').find('.notes-section').find('.notes-text').find('div').text()).toEqual(mockPatient3.travel_related_notes.slice(0, 400) + ' ...');
    wrapper.find('#arrival-information').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandArrivalNotes')).toBe(true);
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('#arrival-information').find('.notes-section').find('.notes-text').find('div').text()).toEqual(mockPatient3.travel_related_notes);
    wrapper.find('#arrival-information').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandArrivalNotes')).toBe(false);
    expect(wrapper.find('#arrival-information').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#arrival-information').find('.notes-section').find('.notes-text').find('div').text()).toEqual(mockPatient3.travel_related_notes.slice(0, 400) + ' ...');
  });

  it('Displays "None" if arrival information has no information', () => {
    const additionalProps = { details: blankIsolationMockPatient };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#arrival-information');
    expect(section.exists()).toBe(true);
    expect(section.find('.none-text').exists()).toBe(true);
    expect(section.find('.none-text').text()).toEqual('None');
  });

  it('Properly renders planned travel section', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#planned-travel');
    expect(section.find(Heading).children().find('span').text()).toEqual('Additional ');
    expect(section.find(Heading).children().at(1).text()).toEqual('Planned Travel');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient1.id + '/edit?step=4&nav=global');
    expect(section.find('.none-text').exists()).toBe(false);
    section
      .find('.item-group')
      .children()
      .forEach((item, index) => {
        expect(item.find('b').text()).toEqual(plannedTravelLabels[parseInt(index)] + ':');
        let value;
        if (_.isArray(plannedTravelFields[parseInt(index)])) {
          let arrayValues = [];
          plannedTravelFields[parseInt(index)].forEach(field => arrayValues.push(mockPatient1[`${field}`]));
          value = arrayValues.join(' ');
        } else {
          value = plannedTravelFields[parseInt(index)].includes('date') ? formatDate(mockPatient1[plannedTravelFields[parseInt(index)]]) : mockPatient1[plannedTravelFields[parseInt(index)]];
        }
        expect(item.find('span').text()).toEqual(value || '--');
      });
    expect(section.find('.notes-section').exists()).toBe(true);
    expect(wrapper.find('.notes-section').find(Button).exists()).toBe(false);
    expect(section.find('.notes-section').find('p').text()).toEqual('Notes');
    expect(section.find('.notes-text').text()).toEqual(mockPatient1.additional_planned_travel_related_notes);
  });

  it('Collapses/expands additional planned travel notes if longer than 400 characters', () => {
    const additionalProps = { details: mockPatient3 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).exists()).toBe(true);
    expect(wrapper.state('expandPlannedTravelNotes')).toBe(false);
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#planned-travel').find('.notes-section').find('.notes-text').find('div').text()).toEqual(mockPatient3.additional_planned_travel_related_notes.slice(0, 400) + ' ...');
    wrapper.find('#planned-travel').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandPlannedTravelNotes')).toBe(true);
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('#planned-travel').find('.notes-section').find('.notes-text').find('div').text()).toEqual(mockPatient3.additional_planned_travel_related_notes);
    wrapper.find('#planned-travel').find('.notes-section').find(Button).simulate('click');
    expect(wrapper.state('expandPlannedTravelNotes')).toBe(false);
    expect(wrapper.find('#planned-travel').find('.notes-section').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('#planned-travel').find('.notes-section').find('.notes-text').find('div').text()).toEqual(mockPatient3.additional_planned_travel_related_notes.slice(0, 400) + ' ...');
  });

  it('Displays "None" if planned travel has no information', () => {
    const additionalProps = { details: blankIsolationMockPatient };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#planned-travel');
    expect(section.exists()).toBe(true);
    expect(section.find('.none-text').exists()).toBe(true);
    expect(section.find('.none-text').text()).toEqual('None');
  });

  it('Properly renders potential exposure information section', () => {
    const additionalProps = { details: mockPatient2 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#potential-exposure-information');
    expect(section.find(Heading).children().at(0).text()).toEqual('Potential Exposure');
    expect(section.find(Heading).children().find('span').text()).toEqual(' Information');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient2.id + '/edit?step=5&nav=global');
    expect(section.find('.item-group').exists()).toBe(true);
    expect(section.find('.item-group').find('b').at(0).text()).toEqual('Last Date of Exposure:');
    expect(section.find('.item-group').find('span').at(0).text()).toEqual(formatDate(mockPatient2.last_date_of_exposure));
    expect(section.find('.item-group').find('b').at(1).text()).toEqual('Exposure Location:');
    expect(section.find('.item-group').find('span').at(1).text()).toEqual(mockPatient2.potential_exposure_location);
    expect(section.find('.item-group').find('b').at(2).text()).toEqual('Exposure Country:');
    expect(section.find('.item-group').find('span').at(2).text()).toEqual(mockPatient2.potential_exposure_country);
    expect(section.find('.risk-factors').exists()).toBe(true);
    riskFactors.forEach((field, index) => {
      expect(section.find('li').at(index).find('.risk-factor').text()).toEqual(field.key);
      if (field.val) {
        expect(section.find('li').at(index).find('.risk-val').text()).toEqual(field.val);
      } else {
        expect(section.find('li').at(index).find('.risk-val').exists()).toBe(false);
      }
    });
    expect(section.find(CommonExposureCohortTable).exists()).toBe(true);
  });

  it('Displays "None specified" if there are no risk factors', () => {
    const additionalProps = { details: blankExposureMockPatient };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#potential-exposure-information');
    expect(section.exists()).toBe(true);
    expect(section.find('.item-group').exists()).toBe(true);
    expect(section.find('.risk-factors').exists()).toBe(false);
    expect(section.find('.none-text').exists()).toBe(true);
    expect(section.find('.none-text').text()).toEqual('None specified');
  });

  it('Properly renders case information section', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#case-information');
    expect(section.find(Heading).children().text()).toEqual('Case Information');
    expect(section.find('.edit-link').exists()).toBe(true);
    expect(section.find('a').prop('href')).toEqual(window.BASE_PATH + '/patients/' + mockPatient1.id + '/edit?step=6&nav=global');
    expect(section.find('b').at(0).text()).toEqual('Case Status: ');
    expect(section.find('span').at(0).text()).toEqual(mockPatient1.case_status);
    expect(section.find('b').at(1).text()).toEqual('First Positive Lab Collected: ');
    expect(section.find('span').at(1).text()).toEqual(formatDate(mockPatient1.first_positive_lab_at));
    expect(section.find('b').at(2).text()).toEqual('Symptom Onset: ');
    expect(section.find('span').at(2).text()).toEqual(formatDate(mockPatient1.symptom_onset));
  });

  it('Hides case information section when monitoree is in the exposure workflow', () => {
    const additionalProps = { details: mockPatient2 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('#case-information').exists()).toBe(false);
  });

  it('Properly renders notes section', () => {
    const additionalProps = { details: mockPatient1 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#exposure-notes');
    expect(section.find(Heading).children().text()).toEqual('Notes');
    expect(section.find('.none-text').exists()).toBe(false);
    expect(section.find('.notes-text').exists()).toBe(true);
    expect(section.find('.notes-text').text()).toEqual(mockPatient1.exposure_notes);
    expect(section.find(Button).exists()).toBe(false);
  });

  it('Collapses/expands exposure notes if longer than 400 characters', () => {
    const additionalProps = { details: mockPatient3 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('#exposure-notes').find(Button).exists()).toBe(true);
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
    const additionalProps = { details: mockPatient4 };
    const wrapper = getWrapper(additionalProps);
    const section = wrapper.find('#exposure-notes');
    expect(section.exists()).toBe(true);
    expect(section.find('.none-text').exists()).toBe(true);
    expect(section.find('.none-text').text()).toEqual('None');
    expect(section.find('.notes-text').exists()).toBe(false);
    expect(section.find(Button).exists()).toBe(false);
  });

  it('Properly renders no details message', () => {
    const additionalProps = { details: null };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.text()).toEqual('No monitoree details to show.');
  });

  it('Renders edit buttons if props.goto is defined in exposure', () => {
    const additionalProps = { details: mockPatient2, edit_mode: true, workflow: 'exposure', goto: goToMock };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('.edit-link').find(Button).length).toEqual(7);
    expect(wrapper.find('.edit-link').find('a').exists()).toBe(false);
    wrapper
      .find('.edit-link')
      .find(Button)
      .forEach(btn => {
        expect(btn.text()).toEqual('Edit');
      });
  });

  it('Renders edit buttons if props.goto is defined in isolation', () => {
    const additionalProps = { details: mockPatient1, edit_mode: true, workflow: 'isolation', goto: goToMock };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('.edit-link').find(Button).length).toEqual(8);
    expect(wrapper.find('.edit-link').find('a').exists()).toBe(false);
    wrapper
      .find('.edit-link')
      .find(Button)
      .forEach(btn => {
        expect(btn.text()).toEqual('Edit');
      });
  });

  it('Renders edit hrefs if props.goto is not defined in exposure', () => {
    const stepIds = [0, 2, 1, 3, 4, 5, 5];
    const additionalProps = { details: mockPatient2, edit_mode: true, workflow: 'exposure' };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('.edit-link').find(Button).exists()).toBe(false);
    expect(wrapper.find('.edit-link').find('a').length).toEqual(7);
    wrapper
      .find('.edit-link')
      .find('a')
      .forEach((link, index) => {
        expect(link.text()).toEqual('Edit');
        expect(link.prop('href')).toEqual(`${window.BASE_PATH}/patients/${mockPatient2.id}/edit?step=${stepIds[Number(index)]}&nav=exposure`);
      });
  });

  it('Renders edit hrefs if props.goto is not defined in isolation', () => {
    const stepIds = [0, 2, 1, 3, 4, 5, 6, 6];
    const additionalProps = { details: mockPatient1, edit_mode: true, workflow: 'isolation' };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find('.edit-link').find(Button).exists()).toBe(false);
    expect(wrapper.find('.edit-link').find('a').length).toEqual(8);
    wrapper
      .find('.edit-link')
      .find('a')
      .forEach((link, index) => {
        expect(link.text()).toEqual('Edit');
        expect(link.prop('href')).toEqual(`${window.BASE_PATH}/patients/${mockPatient1.id}/edit?step=${stepIds[Number(index)]}&nav=isolation`);
      });
  });

  it('Calls props goto method when the edit buttons are clicked', () => {
    const additionalProps = { details: mockPatient1, edit_mode: true, goto: goToMock };
    const wrapper = getWrapper(additionalProps);
    expect(goToMock).toHaveBeenCalledTimes(0);
    wrapper
      .find('.edit-link')
      .find(Button)
      .forEach((btn, index) => {
        btn.simulate('click');
        expect(goToMock).toHaveBeenCalledTimes(index + 1);
      });
  });

  it('Displays the Follow up Flag panel when a monitoree has a follow up flag set', () => {
    const additionalProps = { details: mockPatient3 };
    const wrapper = getWrapper(additionalProps);
    expect(wrapper.find(FollowUpFlagPanel).exists()).toBe(true);
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBe(false);
  });
});
