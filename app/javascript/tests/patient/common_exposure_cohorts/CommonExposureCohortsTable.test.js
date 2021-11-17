import React from 'react';
import { shallow } from 'enzyme';

import CommonExposureCohortTable from '../../../components/patient/common_exposure_cohorts/CommonExposureCohortsTable';

import { mockCommonExposureCohort1, mockCommonExposureCohort2 } from '../../mocks/mockCommonExposureCohorts';

const onEditCohortMock = jest.fn();
const onDeleteCohortMock = jest.fn();

const cohorts = [mockCommonExposureCohort1, mockCommonExposureCohort2];

function getWrapper(isEditable) {
  return shallow(<CommonExposureCohortTable common_exposure_cohorts={cohorts} isEditable={isEditable} onEditCohort={onEditCohortMock} onDeleteCohort={onDeleteCohortMock} />);
}

describe('CommonExposureCohortsTable', () => {
  it('Properly renders common exposure cohorts', () => {
    const wrapper = getWrapper(false);
    cohorts.forEach((cohort, index) => {
      expect(wrapper.find(`#common-exposure-cohort-edit-button-${index}`).exists()).toBe(false);
      expect(wrapper.find(`#common-exposure-cohort-delete-button-${index}`).exists()).toBe(false);
      ['cohort_type', 'cohort_name', 'cohort_location'].forEach(field => {
        expect(wrapper.text()).toContain(cohort[String(field)]);
      });
    });
  });

  it('Properly renders edit and cancel buttons when appropriate', () => {
    const wrapper = getWrapper(true);
    cohorts.forEach((_, index) => {
      expect(wrapper.find(`#common-exposure-cohort-edit-button-${index}`).exists()).toBe(true);
      expect(wrapper.find(`#common-exposure-cohort-delete-button-${index}`).exists()).toBe(true);
    });
  });

  it('Clicking "edit" calls the onEditCohort method with the correct index', () => {
    const wrapper = getWrapper(true);
    const index = 0;
    wrapper.find(`#common-exposure-cohort-edit-button-${index}`).simulate('click');
    expect(onEditCohortMock).toHaveBeenCalledWith(index);
  });

  it('Clicking "delete" calls the onCohortDelete method with the correct index', () => {
    const wrapper = getWrapper(true);
    const index = 0;
    wrapper.find(`#common-exposure-cohort-delete-button-${index}`).simulate('click');
    expect(onDeleteCohortMock).toHaveBeenCalledWith(index);
  });
});
