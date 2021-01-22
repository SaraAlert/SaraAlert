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

    visit name: '01_01_SA_visit_sign_in', url: '/users/sign_in' do
      # <input type="hidden" name="authenticity_token" value="[FILTERED]">
      extract regex: 'input type="hidden" name="authenticity_token" value="(.+?)"', name: 'authenticity_token', match_number: 1
    end

    exists 'authenticity_token' do
      #  {"authenticity_token"=>"[FILTERED]", "user"=>{"email"=>"[FILTERED]", "password"=>"[FILTERED]"}}
      submit name: '01_02_SA_sign_in',
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
      visit name: '01_03_SA_dashboard', url: '/public_health' do
        think_time 500, 1000
        # <meta name="csrf-token" content="[FILTERED]">
        extract regex: 'meta name="csrf-token" content="(.+?)"', name: 'csrf_token', match_number: 1
      end

      exists 'csrf_token' do
        # {"query"=>{"jurisdiction"=>1, "scope"=>"all", "workflow"=>"exposure", "tab"=>"all"}, "jurisdiction"=>{}}
        submit name: '01_04_SA_assigned_users',
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

        # {
        #   "query": {
        #     "workflow": "exposure",
        #     "tab"=>"all",
        #     "jurisdiction"=>1,
        #     "scope"=>"all",
        #     "user"=>nil,
        #     "search"=>"",
        #     "page"=>"[FILTERED]",
        #     "entries"=>25,
        #     "tz_offset"=>480
        #   },
        #   "cancelToken": {
        #     "promise": {}
        #   },
        #   "public_health": {
        #     "query": {
        #       "workflow": "exposure",
        #       "tab"=>"all",
        #       "jurisdiction"=>1,
        #       "scope"=>"all",
        #       "user"=>nil,
        #       "search"=>"ryan",
        #       "page"=>"[FILTERED]",
        #       "entries"=>25,
        #       "tz_offset"=>480
        #     },
        #     "cancelToken": {
        #       "promise": {}
        #     }
        #   }
        # }
        submit name: '01_05_SA_patients',
               url: '/public_health/patients',
               fill_in: {
                 'query[workflow]': 'exposure',
                 'query[tab]': 'all',
                 'query[jurisdiction]': 1,
                 'query[scope]': 'all',
                 'query[user]': nil,
                 'query[search]': '',
                 'query[page]': 1,
                 'query[entries]': 25,
                 'query[tz_offset]': 480,
                 'cancelToken[promise]': {},
                 'public_health[query][workflow]': 'exposure',
                 'public_health[query][tab]': 'all',
                 'public_health[query][jurisdiction]': '1',
                 'public_health[query][scope]': 'all',
                 'public_health[query][user]': nil,
                 'public_health[query][search]': '',
                 'public_health[query][page]': 1,
                 'public_health[query][entries]': 25,
                 'public_health[query][tz_offset]': 480,
                 'public_health[cancelToken][promise]': {},
                 authenticity_token: '${csrf_token}'
               } do
          think_time 500, 1000
        end
      end
    end
  end

  if ENV['JMX_GRAPH']
    latencies_over_time name: 'Response Latencies Over Time'
    response_codes_per_second name: 'Response Codes per Second'
    response_times_distribution name: 'Response Times Distribution'
    response_times_over_time name: 'Response Times Over Time'
    response_times_percentiles name: 'Response Times Percentiles'
    transactions_per_second name: 'Transactions per Second'
  end

  # end.run(path: '/usr/local/bin/', gui: false)
  # end.jmx(file: 'tmp/public_health_dashboard_jmx_test.jmx')
end.run(gui: false)
