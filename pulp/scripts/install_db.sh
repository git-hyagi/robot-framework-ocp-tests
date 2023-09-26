#!/bin/bash

oc new-project db
oc -ndb new-app \
    -e POSTGRESQL_USER=pulp \
    -e POSTGRESQL_PASSWORD=password \
    -e POSTGRESQL_DATABASE=pulp \
    postgresql:12

oc -ndb wait --for=condition=Available deployment/postgresql
oc -ndb exec -it deployment/postgresql -- psql -U postgres -c 'ALTER USER pulp WITH SUPERUSER'
