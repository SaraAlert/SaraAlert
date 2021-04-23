# frozen_string_literal: true

require 'test_case'

class LanguagesControllerTest < ActionController::TestCase
  test 'language_data not authenticated' do
    get :language_data
    assert_redirected_to(new_user_session_path)
  end

  test 'language_date' do
    sign_in create(:user)
    get :language_data
    assert_response :success
    assert_equal(LANGUAGES.to_json, response.body)
  end

  test 'translate_language_codes not authenticated' do
    get :translate_language_codes, params: { language_codes: %w[spa eng] }
    assert_redirected_to(new_user_session_path)
  end

  test 'translate_language_codes' do
    sign_in create(:user)
    get :translate_language_codes, params: { language_codes: %w[oci tgk] }
    assert_response :success
    assert_equal(%w[Occitan Tajik], JSON.parse(response.body)['display_names'])

    assert_raises(ActionController::ParameterMissing) do
      get :translate_language_codes
    end
  end
end
