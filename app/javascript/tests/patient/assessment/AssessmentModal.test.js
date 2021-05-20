import React from 'react';
import { shallow, mount } from 'enzyme';
import { CloseButton, Modal } from 'react-bootstrap';
import AssessmentModal from '../../../components/patient/assessment/AssessmentModal';
import Assessment from '../../../components/patient/assessment/Assessment';
import { mockPatient1 } from '../../mocks/mockPatients';
import { mockAssessment1 } from '../../mocks/mockAssessments';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockTranslations } from '../../mocks/mockTranslations';

const onCloseMock = jest.fn();
const mockToken = 'testMockTokenString12345';

function getWrapper(showModal) {
  return shallow(<AssessmentModal show={showModal} onClose={onCloseMock} current_user={mockUser1} patient={mockPatient1} calculated_age={76} patient_initials={'MM'} assessment={mockAssessment1} symptoms={mockAssessment1.symptoms} threshold_condition_hash={mockAssessment1.threshold_condition_hash} translations={mockTranslations} updateId={13} idPre={'13'} authenticity_token={mockToken} />);
}

function getMountedWrapper() {
  return mount(<AssessmentModal show={true} onClose={onCloseMock} current_user={mockUser1} patient={mockPatient1} calculated_age={76} patient_initials={'MM'} report={mockAssessment1} symptoms={mockAssessment1.symptoms} threshold_condition_hash={mockAssessment1.threshold_condition_hash} translations={mockTranslations} updateId={13} idPre={'13'} authenticity_token={mockToken} />);
}

describe('AssessmentModal', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).prop('show')).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).prop('closeButton')).toBeTruthy();
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Assessment).exists()).toBeTruthy();
  });

  it('Hides modal when props.show is false', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).prop('show')).toBeFalsy();
  });

  it('Clicking the close button calls onClose', () => {
    const wrapper = getMountedWrapper();
    expect(onCloseMock).toHaveBeenCalledTimes(0);
    wrapper.find(CloseButton).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });
});
