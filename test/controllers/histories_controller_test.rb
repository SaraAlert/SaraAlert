# frozen_string_literal: true

require 'test_case'

class HistoriesControllerTest < ActionController::TestCase
  test 'successfully create comment' do
    user = users(:usa_super_user)
    sign_in user

    comment = 'test comment'

    post :create, params: {
      patient_id: patients(:patient_20).id,
      created_by: user.email,
      comment: comment,
      history_type: History::HISTORY_TYPES[:comment]
    }

    assert_response :success
    assert patients(:patient_20).histories.where(comment: comment).exists?
  end

  test 'successfully edit comment' do
    user = users(:usa_super_user)
    sign_in user

    comment = 'test comment update'
    history = histories(:public_health_action_patient_20_comment_1)

    patch :update, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      created_by: user.email,
      comment: comment
    }

    assert_response :success
    assert patients(:patient_20).histories.where(original_comment_id: history.id, comment: comment).exists?
  end

  test 'successfully delete comment' do
    user = users(:usa_super_user)
    sign_in user

    history = histories(:public_health_action_patient_20_comment_1)
    delete_reason = 'test delete reason'

    delete :delete, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      created_by: user.email,
      delete_reason: delete_reason
    }

    assert_response :success
    History.where(original_comment_id: history.original_comment_id).each do |h|
      assert_equal user.email, h.deleted_by
      assert_equal delete_reason, h.delete_reason
    end
  end
end
