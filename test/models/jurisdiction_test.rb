# frozen_string_literal: true

require 'test_case'

class JurisdictionTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create jurisdiction' do
    assert create(:jurisdiction)
  end

  # transferred_out_patients tests

  test 'transferred out patients should not include purged' do
    # Create not purged patient that is then transferred and verify it IS included in transferred_out_patients
    patient = create(:patient, purged: false)
    old_jurisdiction = patient.jurisdiction
    new_jurisdiction = Jurisdiction.find(5)
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(1, old_jurisdiction.transferred_out_patients.where(id: patient.id).count)

    # Create purged patient that is then transferred and verify it is not included in transferred_out_patients
    patient = create(:patient, purged: true)
    old_jurisdiction = patient.jurisdiction
    new_jurisdiction = Jurisdiction.find(5)
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(0, old_jurisdiction.transferred_out_patients.where(id: patient.id).count)
  end

  test 'transferred out patients should not include transfers from jurisdictions outside of its jurisdiction hierarchy' do
    curr_jur = Jurisdiction.find_by(name: 'State 1')

    # Create patient that is from jurisdiction in hierarchy
    old_jurisdiction = curr_jur
    patient = create(:patient, jurisdiction: old_jurisdiction)
    # Make sure you are not transferring back into the jurisdiction's hierarchy
    new_jurisdiction = Jurisdiction.find_by(name: 'USA')
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(1, curr_jur.transferred_out_patients.where(id: patient.id).count)

    # Create patient that is from jurisdiction outside of hierarchy
    old_jurisdiction = Jurisdiction.find_by(name: 'USA')
    patient = create(:patient, jurisdiction: old_jurisdiction)
    new_jurisdiction = Jurisdiction.find(5)
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(0, curr_jur.transferred_out_patients.where(id: patient.id).count)
  end

  test 'transferred out patients should include transfers from subjurisdictions' do
    curr_jur = Jurisdiction.find_by(name: 'State 1')

    # Create patient that is from jurisdiction in hierarchy
    old_jurisdiction = Jurisdiction.find_by(name: 'County 1')
    patient = create(:patient, jurisdiction: old_jurisdiction)
    # Make sure you are not transferring back into the jurisdiction's hierarchy
    new_jurisdiction = Jurisdiction.find_by(name: 'USA')
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(1, curr_jur.transferred_out_patients.where(id: patient.id).count)
  end

  # transferred_in_patients tests

  test 'transferred in patients should not include purged' do
    # Create not purged patient that is then transferred in and verify it IS included in transferred_in_patients
    patient = create(:patient, purged: false)
    old_jurisdiction = patient.jurisdiction
    new_jurisdiction = Jurisdiction.find(5)
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(1, new_jurisdiction.transferred_in_patients.where(id: patient.id).count)

    # Create purged patient that is then transferred in and verify it is not included in transferred_in_patients
    patient = create(:patient, purged: true)
    old_jurisdiction = patient.jurisdiction
    new_jurisdiction = Jurisdiction.find(5)
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(0, new_jurisdiction.transferred_in_patients.where(id: patient.id).count)
  end

  test 'transferred in patients should not include transfers into jurisdictions outside of its jurisdiction hierarchy' do
    curr_jur = Jurisdiction.find_by(name: 'State 1')

    # Create patient that is transferred to jurisdiction in hierarchy
    old_jurisdiction = Jurisdiction.find_by(name: 'USA')
    patient = create(:patient, jurisdiction: old_jurisdiction)
    new_jurisdiction = curr_jur
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(1, curr_jur.transferred_in_patients.where(id: patient.id).count)

    # Create patient that is transferred to jurisdiction outside of hierarchy
    old_jurisdiction = Jurisdiction.find_by(name: 'USA')
    patient = create(:patient, jurisdiction: old_jurisdiction)
    new_jurisdiction = Jurisdiction.find_by(name: 'State 2')
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(0, curr_jur.transferred_in_patients.where(id: patient.id).count)
  end

  test 'transferred in patients should include transfers into subjurisdictions' do
    curr_jur = Jurisdiction.find_by(name: 'State 1')

    # Create patient that is from jurisdiction in hierarchy
    # Make sure you are not transferring from the jurisdiction's hierarchy
    old_jurisdiction = Jurisdiction.find_by(name: 'USA')
    patient = create(:patient, jurisdiction: old_jurisdiction)
    new_jurisdiction = Jurisdiction.find_by(name: 'County 1')
    patient.update!(jurisdiction: new_jurisdiction)
    Transfer.create!(patient: patient, from_jurisdiction: old_jurisdiction, to_jurisdiction_id: new_jurisdiction.id, who: User.first)
    assert_equal(1, curr_jur.transferred_in_patients.where(id: patient.id).count)
  end
end
