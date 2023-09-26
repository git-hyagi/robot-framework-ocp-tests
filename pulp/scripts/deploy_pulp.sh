#!/bin/bash

oc new-project pulp || oc project pulp

kubectl apply -f-<<EOF
apiVersion: v1
kind: Secret
metadata:
 name: admin-password
stringData:
 password: 'password'
EOF


kubectl apply -f-<<EOF
apiVersion: v1
kind: Secret
metadata:
  name: external-database
stringData:
  POSTGRES_HOST: postgresql.db.svc
  POSTGRES_PORT: '5432'
  POSTGRES_USERNAME: 'pulp'
  POSTGRES_PASSWORD: 'password'
  POSTGRES_DB_NAME: 'pulp'
  POSTGRES_SSLMODE: 'prefer'
EOF


kubectl apply -f-<<EOF
apiVersion: v1
kind: Secret
metadata:
  name: pulp-object-storage
stringData:
  s3-access-key-id: 'AKIAIT2Z5TDYPX3ARJBA'
  s3-secret-access-key: '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'
  s3-bucket-name: 'pulp3'
  s3-endpoint: http://minio.minio.svc:9000
EOF

kubectl apply -f-<<EOF
apiVersion: repo-manager.pulpproject.org/v1beta2
kind: Pulp
metadata:
  name: test-pulp-ha
spec:
  admin_password_secret: admin-password
  object_storage_s3_secret: pulp-object-storage
  ingress_type: nodeport
  nodeport_port: 30002
  pulp_settings:
    telemetry: false
  api:
    replicas: 3
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app.kubernetes.io/component
                operator: In
                values:
                - api
            topologyKey: topology.kubernetes.io/zone
  content:
    replicas: 1
  worker:
    replicas: 1
  web:
    replicas: 1
  database:
    external_db_secret: external-database
EOF

