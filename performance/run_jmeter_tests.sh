
bundle exec rails s &

sleep 15

for script in $(ls performance/jmeter/); do
  echo "Executing JMeter test: $script"
  bundle exec ruby performance/jmeter/$script
  sleep 5
done

if [ -f "tmp/pids/server.pid" ]; then
    echo "Killing rails server with PID $(cat tmp/pids/server.pid)"
    # -INT does not terminate the server
    # kill -INT $(cat tmp/pids/server.pid)
    kill -9 $(cat tmp/pids/server.pid)
fi

bundle exec ruby performance/assert_jmeter_results.rb
