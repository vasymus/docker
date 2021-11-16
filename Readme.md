### Docker Images Update

#### Docker Base Image Update

Go to the root of the project and run:

```shell
# authenticate to docker hub
docker login

# build image with adding tag
docker image build --file ./docker/app/base.Dockerfile --tag vasymus/base-php-nginx-node:$MY_TAG_HERE .

# push docker image to repository
docker image push vasymus/base-php-nginx-node:$MY_TAG_HERE
```

### Docker Troubleshooting

#### Permissions troubles

If there would be any php errors related permissions to file, run such commands:

```shell
# enter container
docker-compose exec app bash

chown -R :www-data /var/www/html/bootstrap/cache/
chown -R :www-data /var/www/html/public/
chown -R :www-data /var/www/html/storage/

chmod -R g+w /var/www/html/bootstrap/cache/
chmod -R g+w /var/www/html/public/
chmod -R g+w /var/www/html/storage/
```
