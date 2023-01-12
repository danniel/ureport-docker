fastbuild:
	ENVIRONMENT=production docker-compose up -d --build

build:                            ## TODO: dev/stage/prod
	ENVIRONMENT=production docker-compose up -d --build --force-recreate --remove-orphans

superuser:                        ## creates a superuser for the backend
	docker-compose exec ureport-web python3 manage.py createsuperuser

drop-db:                          ## drops the database
	docker-compose down -t 60
	docker volume rm ureport-pgdata

migrate:                          ## apply migrations in a clean container
	docker-compose exec ureport-web python3 manage.py migrate

pyshell:                          ## start a django shell
	docker-compose exec ureport-web python3 manage.py shell

shell:                            ## start bash
	docker-compose exec ureport-web bash


## TODO: Update the SSL certificates for NGINX
