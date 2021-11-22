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

## Deploy (docker swarm)

### Create secrets

Create docker swarm secrets via echo but without displaying secret values in bash history. Run:

```shell
# enter password [without echoing to input]
read -s db_root_password
read -s db_user
read -s db_password
read -s mailgun_secret
read -s app_key

# create docker swarm secrets
echo "$db_root_password" | docker secret create db_root_password -
echo "$db_user" | docker secret create db_user -
echo "$db_password" | docker secret create db_password -
echo "$mailgun_secret" | docker secret create mailgun_secret -
echo "$app_key" | docker secret create app_key -

# delete bash shell variables
unset db_root_password
unset db_user
unset db_password
unset mailgun_secret
unset app_key
```

### Run docker swarm

Create `docker-stack.yml` via console terminal and run docker swarm:

```shell
docker stack deploy $stackName -c <(docker-compose -f ./docker-stack.yml config)
```
