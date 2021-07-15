import React from 'react';
import { mount } from 'enzyme';
import Identification from '../../../components/enrollment/steps/Identification';
import { blankIsolationMockPatient, mockPatient1, mockPatient2 } from '../../mocks/mockPatients';

const newEnrollmentState = {
  isolation: false,
  patient: blankIsolationMockPatient,
  propagatedFields: {},
};

const requiredStrings = ['WORKFLOW *', 'FIRST NAME *', 'MIDDLE NAME(S)', 'LAST NAME *', 'DATE OF BIRTH *', 'AGE', 'SEX AT BIRTH', 'GENDER IDENTITY', 'SEXUAL ORIENTATION', 'RACE (SELECT ALL THAT APPLY)', 'ETHNICITY', 'PRIMARY LANGUAGE', 'SECONDARY LANGUAGE', 'NATIONALITY', 'STATE/LOCAL ID', 'CDC ID', 'NNDSS LOC. REC. ID/CASE ID'];

const race_options = {
  non_exclusive: [
    { race: 'white', label: 'WHITE' },
    { race: 'black_or_african_american', label: 'BLACK OR AFRICAN AMERICAN' },
    { race: 'american_indian_or_alaska_native', label: 'AMERICAN INDIAN OR ALASKA NATIVE' },
    { race: 'asian', label: 'ASIAN' },
    { race: 'native_hawaiian_or_other_pacific_islander', label: 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' },
    { race: 'race_other', label: 'OTHER' },
  ],
  exclusive: [
    { race: 'race_unknown', label: 'UNKNOWN' },
    { race: 'race_refused_to_answer', label: 'REFUSED TO ANSWER' },
  ],
};

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
  { name: 'global', label: 'Global' },
];

describe('Identification', () => {
  it('Properly renders all main components', () => {
    const aw = available_workflows;
    const wrapper = mount(<Identification goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} race_options={race_options} available_workflows={aw} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    });
  });

  it('Properly allows setting of all identification information', () => {
    const aw = available_workflows;
    const wrapper = mount(<Identification goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} race_options={race_options} available_workflows={aw} />);
    expect(wrapper.find('#first_name').instance().value).toEqual('');
    expect(wrapper.find('#middle_name').instance().value).toEqual('');
    expect(wrapper.find('#last_name').instance().value).toEqual('');
    expect(wrapper.find('#age').instance().value).toEqual('0');
    expect(wrapper.find('#sex').instance().value).toEqual('');
    expect(wrapper.find('#gender_identity').instance().value).toEqual('');
    expect(wrapper.find('#sexual_orientation').instance().value).toEqual('');
    expect(wrapper.find('#ethnicity').instance().value).toEqual('');
    expect(wrapper.find('#nationality').instance().value).toEqual('');
    expect(wrapper.find('#user_defined_id_statelocal').instance().value).toEqual('');
    expect(wrapper.find('#user_defined_id_cdc').instance().value).toEqual('');
    expect(wrapper.find('#user_defined_id_nndss').instance().value).toEqual('');
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#first_name').instance().value).toEqual(mockPatient1.first_name);
      expect(wrapper.find('#middle_name').instance().value).toEqual(mockPatient1.middle_name);
      expect(wrapper.find('#last_name').instance().value).toEqual(mockPatient1.last_name);
      expect(wrapper.find('#age').instance().value).toEqual(mockPatient1.age.toString()); // the input casts it to a string
      expect(wrapper.find('#sex').instance().value).toEqual(mockPatient1.sex);
      expect(wrapper.find('#gender_identity').instance().value).toEqual(mockPatient1.gender_identity);
      expect(wrapper.find('#sexual_orientation').instance().value).toEqual(mockPatient1.sexual_orientation);
      expect(wrapper.find('#ethnicity').instance().value).toEqual(mockPatient1.ethnicity);
      expect(wrapper.find('#nationality').instance().value).toEqual(mockPatient1.nationality);
      expect(wrapper.find('#user_defined_id_statelocal').instance().value).toEqual(mockPatient1.user_defined_id_statelocal);
      expect(wrapper.find('#user_defined_id_cdc').instance().value).toEqual(mockPatient1.user_defined_id_cdc);
      expect(wrapper.find('#user_defined_id_nndss').instance().value).toEqual(mockPatient1.user_defined_id_nndss);
    });
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#first_name').instance().value).toEqual(mockPatient2.first_name);
      expect(wrapper.find('#middle_name').instance().value).toEqual(mockPatient2.middle_name);
      expect(wrapper.find('#last_name').instance().value).toEqual(mockPatient2.last_name);
      expect(wrapper.find('#age').instance().value).toEqual(mockPatient2.age.toString()); // the input casts it to a string
      expect(wrapper.find('#sex').instance().value).toEqual(mockPatient2.sex);
      expect(wrapper.find('#gender_identity').instance().value).toEqual('');
      expect(wrapper.find('#sexual_orientation').instance().value).toEqual('');
      expect(wrapper.find('#ethnicity').instance().value).toEqual(mockPatient2.ethnicity);
      expect(wrapper.find('#nationality').instance().value).toEqual(mockPatient2.nationality);
      expect(wrapper.find('#user_defined_id_statelocal').instance().value).toEqual(mockPatient2.user_defined_id_statelocal);
      expect(wrapper.find('#user_defined_id_cdc').instance().value).toEqual(mockPatient2.user_defined_id_cdc);
      expect(wrapper.find('#user_defined_id_nndss').instance().value).toEqual(mockPatient2.user_defined_id_nndss);
    });
  });
});
