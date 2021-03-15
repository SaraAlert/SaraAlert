set -ev

PERFORMANCE='true' bundle exec rails db:drop db:create db:schema:load
    
echo "y" | PERFORMANCE='true' bundle exec rails admin:import_or_update_jurisdictions

PERFORMANCE='true' bundle exec rails demo:setup_performance_test_users

LIMIT=10000 DAYS=10 COUNT=1000 bundle exec rails demo:populate

COUNT=350000 FORKS=8 bundle exec rails demo:create_bulk_data

bundle exec rails demo:backup_database
