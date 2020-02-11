require 'test_helper'

class AssessmentTest < ActiveSupport::TestCase
  def setup
    test_subject = Patient.new
    test_subject.responder = test_subject
    test_user = User.new(email: "test@example.com", password: "abc1234")
    test_subject.creator = test_user
    test_subject.jurisdiction = Jurisdiction.new
    @test_assessment = Assessment.new
    @test_assessment.patient = test_subject
  end

  test "Assessment validation does not allow string fields to exceed 200 characters" do
    str_just_long_enough = "0" * 200
    @test_assessment.temperature = str_just_long_enough
    # No string length violations, should save without error
    assert @test_assessment.save!
    str_too_long = "0" * 201
    @test_assessment.temperature = str_too_long
    # String length too long for first name, should throw exception
    exception = assert_raises(Exception) { @test_assessment.save!}
    assert_equal( "Validation failed: Temperature is too long (maximum is 200 characters)", exception.message )
  end
end
