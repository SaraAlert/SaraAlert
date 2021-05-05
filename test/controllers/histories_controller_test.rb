# frozen_string_literal: true

require 'test_case'

class HistoriesControllerTest < ActionController::TestCase
  test 'successfully create comment' do
    user = users(:usa_super_user)
    sign_in user

    comment = 'test comment'

    post :create, params: {
      patient_id: patients(:patient_20).id,
      comment: comment,
      history_type: History::HISTORY_TYPES[:comment]
    }

    assert_response :success
    assert patients(:patient_20).histories.where(comment: comment).exists?

    new_history = History.last
    assert_equal new_history.id, new_history.original_comment_id
    assert_equal user.email, new_history.created_by
    assert_equal comment, new_history.comment
    assert_equal History::HISTORY_TYPES[:comment], new_history.history_type
  end

  test 'successfully edit comment' do
    user = users(:usa_super_user)
    sign_in user

    comment = 'test comment edit'
    history = histories(:public_health_action_patient_20_comment_2)

    post :edit, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      comment: comment
    }

    assert_response :success
    assert patients(:patient_20).histories.where(original_comment_id: history.id, comment: comment).exists?
    assert_equal 2, patients(:patient_20).histories.where(original_comment_id: history.id).length

    new_history = History.last
    assert_equal history.id, new_history.original_comment_id
    assert_equal user.email, new_history.created_by
    assert_equal comment, new_history.comment
    assert_equal History::HISTORY_TYPES[:comment], new_history.history_type

    old_history = History.find_by(id: new_history.original_comment_id)
    assert_equal history.original_comment_id, old_history.original_comment_id
    assert_equal history.created_by, old_history.created_by
    assert_equal history.comment, old_history.comment
    assert_equal History::HISTORY_TYPES[:comment], old_history.history_type
  end

  test 'successfully deletes comment with no edits' do
    user = users(:usa_super_user)
    sign_in user

    history = histories(:public_health_action_patient_20_comment_2)
    delete_reason = 'test delete reason'

    post :delete, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      delete_reason: delete_reason
    }

    assert_response :success

    deleted_history = History.find_by(id: history.id)
    assert_equal user.email, deleted_history.deleted_by
    assert_equal delete_reason, deleted_history.delete_reason
  end

  test 'successfully delete comment with edits' do
    user = users(:usa_super_user)
    sign_in user

    history = histories(:public_health_action_patient_20_comment_1)
    delete_reason = 'test delete reason'

    post :delete, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      delete_reason: delete_reason
    }

    assert_response :success

    deleted_histories = History.where(original_comment_id: history.id)
    assert_equal 3, deleted_histories.length
    deleted_histories.each do |h|
      assert_equal user.email, h.deleted_by
      assert_equal delete_reason, h.delete_reason
    end
  end
end
