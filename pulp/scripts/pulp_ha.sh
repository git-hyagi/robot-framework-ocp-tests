#!/bin/bash

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
    replicas: 6
    pdb:
      minAvailable: 3
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
    pdb:
      maxUnavailable: 50%
    replicas: 6
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
                - content
            topologyKey: topology.kubernetes.io/zone
  worker:
    pdb:
      minAvailable: 2
    replicas: 6
#    node_selector:
#      is_spot_instance: "true"
  web:
    replicas: 1
  database:
    external_db_secret: external-database
EOF

