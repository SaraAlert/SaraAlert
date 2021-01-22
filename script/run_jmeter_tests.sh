
DISEASE_TRAKKER_DATABASE_NAME='1m_disease_trakker_development' \
bundle exec rails s &

sleep 15

for script in $(ls script/jmeter/); do
  echo "Executing JMeter test: $script"
  ruby script/jmeter/$script
  sleep 5
done

if [ -f "tmp/pids/server.pid" ]; then
    echo "Killing rails server with PID $(cat tmp/pids/server.pid)"
    # -INT does not terminate the server
    # kill -INT $(cat tmp/pids/server.pid)
    kill -9 $(cat tmp/pids/server.pid)
fi

ruby script/assert_jmeter_results.rb
