# frozen_string_literal: true

require 'test_case'

class UserFiltersControllerTest < ActionController::TestCase
  def setup
    @original_max_filters = ADMIN_OPTIONS['max_user_filters']
    @params = {
      'activeFilterOptions' => [{
        'filterOption' => {
          'name' => 'assigned-user',
          'title' => 'Assigned User (Multi-select)',
          'description' => 'Monitorees who have a specific assigned user',
          'type' => 'multi',
          # rubocop:disable Layout/LineLength
          'options' => [{ 'value' => 57, 'label' => 57 }, { 'value' => 134_095, 'label' => 134_095 }, { 'value' => 144_444, 'label' => 144_444 },
                        { 'value' => 242_947, 'label' => 242_947 }, { 'value' => 251_048, 'label' => 251_048 }, { 'value' => 265_024, 'label' => 265_024 }, { 'value' => 266_800, 'label' => 266_800 }, { 'value' => 326_480, 'label' => 326_480 }, { 'value' => 386_822, 'label' => 386_822 }, { 'value' => 485_594, 'label' => 485_594 }, { 'value' => 497_452, 'label' => 497_452 }, { 'value' => 538_127, 'label' => 538_127 }, { 'value' => 678_295, 'label' => 678_295 }, { 'value' => 825_208, 'label' => 825_208 }, { 'value' => 832_541, 'label' => 832_541 }, { 'value' => 885_015, 'label' => 885_015 }, { 'value' => 894_558, 'label' => 894_558 }, { 'value' => 895_323, 'label' => 895_323 }, { 'value' => 946_448, 'label' => 946_448 }]
          # rubocop:enable Layout/LineLength
        },
        'value' => [],
        'numberOption' => nil,
        'dateOption' => nil,
        'relativeOption' => nil,
        'additionalFilterOption' => nil
      }],
      'name' => 'Test'
    }
  end

  def teardown
    ADMIN_OPTIONS['max_user_filters'] = @original_max_filters
  end

  test 'cannot create if the user has too many filters' do
    # Allow only 1 filter to be created
    ADMIN_OPTIONS['max_user_filters'] = 1
    user = create(:user)
    create(:user_filter, user: user)
    # Allowed to create another filter here, only enforcement is in the controller.
    create(:user_filter, user: user)
    sign_in user
    get :create
    assert_response :bad_request
    assert(JSON.parse(response.body).key?('error'))
  end

  test 'create a multi-select advanced filter with no options selected' do
    user = create(:user)
    sign_in user
    post :create, params: @params
    assert_response :success
    user.reload
    assert_equal(1, user.user_filters.count)
  end
end
