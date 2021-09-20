# Use the commented out commands on L2-3 for debugging
# docker run --rm -e MYSQL_ROOT_PASSWORD=root ghcr.io/saraalert/saraalert-1m-database:latest
# docker exec -it <container ID> sh -c 'exec mysql -uroot -proot'
#
# Want to migrate an existing database dump and rebuild the image?
#
# Pull latest database with docker pull ghcr.io/saraalert/saraalert-1m-database:latest
# Run it docker run --rm -e MYSQL_ROOT_PASSWORD=root ghcr.io/saraalert/saraalert-1m-database:latest
# Dump the database (in a new terminal) docker exec <container ID> mysqldump -u root --password=root disease_trakker_development > sara_database_latest.sql
# FILE=./path_to_backup.sql bundle exec rails demo:restore_database
# bundle exec rails db:migrate
# bundle exec rails demo:backup_database
# ./performance/docker/build-push-1m-database-image.sh ./path_to_migrated_db_dump.sql
#

set -ev

# Expect first POSARG to be location of the .sql dump
if [ ! -f "$1" ]; then
    echo "The file \"$1\" cannot be found!"
    echo "The first positional argument should be the path to a .sql dump file!"
    exit 1
fi

# Build image with non-volume data dir
echo "Building base docker mariadb image without volumes..."
docker build ./performance/docker/ -t ghcr.io/saraalert/saraalert-1m-database:latest -f ./performance/docker/1m-database.dockerfile
echo "Built base docker mariadb image without volumes."

docker stop saraalert-1m-database || true
docker rm saraalert-1m-database || true

# Run the image, populate, then docker commit
echo "Loading 1m database into container..."
docker run --name saraalert-1m-database -e MYSQL_ROOT_PASSWORD=root -d ghcr.io/saraalert/saraalert-1m-database:latest
sleep 30
docker exec -i saraalert-1m-database sh -c 'exec mysql -uroot -proot -e"CREATE DATABASE disease_trakker_development"'
docker exec -i saraalert-1m-database sh -c 'exec mysql -uroot -proot disease_trakker_development' < $1
echo "Showing table information"
docker exec -i saraalert-1m-database sh -c 'exec mysql -uroot -proot disease_trakker_development -e "show tables;"'
docker exec -i saraalert-1m-database sh -c 'exec mysql -uroot -proot disease_trakker_development -e "SELECT COUNT(*) FROM patients;"'
docker exec -i saraalert-1m-database sh -c 'exec mysql -uroot -proot disease_trakker_development -e "SELECT COUNT(*) FROM symptoms;"'
echo "Loaded 1m database into container."
echo "Commiting new version of 1m database container..."
docker commit saraalert-1m-database ghcr.io/saraalert/saraalert-1m-database:latest
echo "Committed new version of 1m database container."
docker stop saraalert-1m-database
docker rm saraalert-1m-database

# Login to GitHub Container Registry (You only need to do this once)
docker login -u $GHCR_USER -p $GHCR_PASSWORD ghcr.io

# Push the new image
docker push ghcr.io/saraalert/saraalert-1m-database:latest
