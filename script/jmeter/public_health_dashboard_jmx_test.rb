# frozen_string_literal: true

require 'ruby-jmeter'

test do
  domain = ENV['JMX_DOMAIN'] || 'localhost'
  port = ENV['JMX_PORT'] || '3000'
  username = ENV['JMX_USERNAME'] || 'epi_enroller_all@example.com'
  password = ENV['JMX_PASSWORD'] || '1234567ab!'

  defaults domain: domain
  defaults port: port

  cache clear_each_iteration: true

  cookies

  threads count: 10, loops: 1 do
    think_time 500, 3000

    visit name: '01_SA_visit_sign_in', url: '/users/sign_in' do
      # <input type="hidden" name="authenticity_token" value="[FILTERED]">
      extract regex: 'input type="hidden" name="authenticity_token" value="(.+?)"', name: 'authenticity_token', match_number: 1
    end

    exists 'authenticity_token' do
      #  {"authenticity_token"=>"[FILTERED]", "user"=>{"email"=>"[FILTERED]", "password"=>"[FILTERED]"}}
      submit name: '02_SA_sign_in',
             url: '/users/sign_in',
             fill_in: {
               'user[email]': username,
               'user[password]': password,
               authenticity_token: '${authenticity_token}'
             } do
        think_time 500, 1000
      end
    end

    loops count: 20 do
      visit name: '03_SA_dashboard', url: '/public_health' do
        think_time 500, 1000
        # <meta name="csrf-token" content="[FILTERED]">
        extract regex: 'meta name="csrf-token" content="(.+?)"', name: 'csrf_token', match_number: 1
      end

      exists 'csrf_token' do
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
          think_time 500, 1000
        end
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
end.run(path: '/usr/local/bin/', gui: false)
