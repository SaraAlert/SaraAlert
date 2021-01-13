# frozen_string_literal: true

require 'ruby-jmeter'

test do

  defaults :domain => 'localhost'
  defaults :port => 3000

  cache :clear_each_iteration => true

  cookies

  threads  :count => 20, :loops => 1 do
    think_time 500, 3000

    Once do
      transaction '01_SA_visit_sign_in' do
        visit :name => 'home', :url => '/users/sign_in' do
          assert 'contains' => 'Log In'
          # <input type="hidden" name="authenticity_token" value="[FILTERED]">
          extract :regex => 'input type="hidden" name="authenticity_token" value="(.+?)"', :name => 'authenticity_token', match_number: 1
        end
      end

      exists 'authenticity_token' do
        transaction '02_SA_sign_in' do
          #  {"authenticity_token"=>"[FILTERED]", "user"=>{"email"=>"[FILTERED]", "password"=>"[FILTERED]"}}
          submit name: 'signin', url: '/users/sign_in',
            fill_in: {
              "user[email]": "epi_enroller_all@example.com",
              "user[password]": '1234567ab!',
              authenticity_token: '${authenticity_token}'
            } do
              assert 'contains' => 'epi_enroller_all@example.com (Public Health Enroller)'
              think_time 500, 1000
          end
        end
      end
    end

    # <meta name="csrf-token" content="[FILTERED]">
    extract :regex => 'meta name="csrf-token" content="(.+?)"', :name => 'csrf_token', match_number: 1

    # {"query"=>{"jurisdiction"=>1, "scope"=>"all", "workflow"=>"exposure", "tab"=>"all"}, "jurisdiction"=>{}}
    submit name: 'assigned_users', url: '/jurisdictions/assigned_users',
      fill_in: {
        "query[jurisdiction]": 1,
        "query[scope]": "all",
        "query[workflow]": "exposure",
        "query[tab]": "all",
        authenticity_token: '${csrf_token}'
      } do
        assert 'contains' => 'epi_enroller_all@example.com (Public Health Enroller)'
        think_time 500, 1000
    end
  end
# end.run(path: '/usr/local/bin/', gui: true)
end.jmx(file: 'tmp/example_public_health_controller_test.jmx')
