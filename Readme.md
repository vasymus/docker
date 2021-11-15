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
