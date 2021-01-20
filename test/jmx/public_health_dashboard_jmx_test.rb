# frozen_string_literal: true

require 'ruby-jmeter'

test do
  defaults domain: 'localhost'
  defaults port: 3000

  cache clear_each_iteration: true

  cookies

  threads count: 30 do
    think_time 500, 3000

    visit name: '01_SA_visit_sign_in', url: '/users/sign_in' do
      assert 'contains': 'Log In'
      # <input type="hidden" name="authenticity_token" value="[FILTERED]">
      extract regex: 'input type="hidden" name="authenticity_token" value="(.+?)"', name: 'authenticity_token', match_number: 1
    end

    exists 'authenticity_token' do
      #  {"authenticity_token"=>"[FILTERED]", "user"=>{"email"=>"[FILTERED]", "password"=>"[FILTERED]"}}
      submit name: '02_SA_sign_in',
             url: '/users/sign_in',
             fill_in: {
               'user[email]': 'epi_enroller_all@example.com',
               'user[password]': '1234567ab!',
               authenticity_token: '${authenticity_token}'
             } do
        assert 'contains': 'epi_enroller_all@example.com (Public Health Enroller)'
        think_time 500, 1000
      end
    end

    loops count: 50 do
      visit name: '03_SA_dashboard', url: '/public_health' do
        assert 'contains': 'epi_enroller_all@example.com (Public Health Enroller)'
        think_time 500, 1000
        # <meta name="csrf-token" content="[FILTERED]">
        extract regex: 'meta name="csrf-token" content="(.+?)"', name: 'csrf_token', match_number: 1
      end

      # {"query"=>{"jurisdiction"=>1, "scope"=>"all", "workflow"=>"exposure", "tab"=>"all"}, "jurisdiction"=>{}}
      submit name: '04_SA_assigned_users',
             url: '/jurisdictions/assigned_users',
             fill_in: {
               'query[jurisdiction]': 1,
               'query[scope]': 'all',
               'query[workflow]': 'exposure',
               'query[tab]': 'all',
               authenticity_token: '${csrf_token}'
             } do
        assert 'contains': 'epi_enroller_all@example.com (Public Health Enroller)'
        think_time 500, 1000
      end
    end
  end

  latencies_over_time name: 'Response Latencies Over Time'
  response_codes_per_second name: 'Response Codes per Second'
  response_times_distribution name: 'Response Times Distribution'
  response_times_over_time name: 'Response Times Over Time'
  response_times_percentiles name: 'Response Times Percentiles'
  transactions_per_second name: 'Transactions per Second'

  # end.run(path: '/usr/local/bin/', gui: false)
  # end.jmx(file: 'tmp/public_health_dashboard_jmx_test.jmx')
end.run(path: '/usr/local/bin/', gui: true)
