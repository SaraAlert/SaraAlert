# frozen_string_literal: true

require 'test_case'

class SubjectTest < ActiveSupport::TestCase
  def setup
    @test_subject = Patient.new
    @test_subject.responder = @test_subject
    @test_subject.jurisdiction = Jurisdiction.new
    test_user = User.new(email: 'test@example.com', password: 'abc1234')
    @test_subject.creator = test_user
  end

  test 'Subject validation does not allow string fields to exceed 200 characters' do
    str_just_long_enough = '0' * 200
    @test_subject.first_name = str_just_long_enough
    # No string length violations, should save without error
    assert @test_subject.save!

    str_too_long = '0' * 201
    @test_subject.first_name = str_too_long
    # String length too long for first name, should throw exception
    exception = assert_raises(Exception) { @test_subject.save! }
    assert_equal('Validation failed: First name is too long (maximum is 200 characters)', exception.message)
  end

  test 'Subject validation does not allow text fields to exceed 2000 characters' do
    str_just_long_enough = '0' * 2000
    @test_subject.travel_related_notes = str_just_long_enough
    # No string length violations, should save without error
    assert @test_subject.save!

    str_too_long = '0' * 2001
    @test_subject.travel_related_notes = str_too_long
    # String length too long for first name, should throw exception
    exception = assert_raises(Exception) { @test_subject.save! }
    assert_equal('Validation failed: Travel related notes is too long (maximum is 2000 characters)', exception.message)
  end
end
