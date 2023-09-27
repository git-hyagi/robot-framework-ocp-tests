#!/bin/bash

export MINIO_ACCESS_KEY=AKIAIT2Z5TDYPX3ARJBA
export MINIO_SECRET_KEY=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

oc new-project minio
oc apply -f-<<EOF
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: minio
  name: minio
  namespace: minio
spec:
  containers:
  - name: minio
    image: quay.io/minio/minio:latest
    command:
    - /bin/bash
    - -c
    args:
    - minio server /data --console-address :9090
    env:
    - name: MINIO_ACCESS_KEY
      value: $MINIO_ACCESS_KEY
    - name: MINIO_SECRET_KEY
      value: $MINIO_SECRET_KEY
    volumeMounts:
    - mountPath: /data
      name: localvolume
  volumes:
  - name: localvolume
    emptyDir: {}
EOF

oc apply -f-<<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  selector:
    app: minio
  ports:
    - protocol: TCP
      port: 9000
      targetPort: 9000
      nodePort: 31000
  type: NodePort
EOF

oc -nminio expose svc minio
oc -nminio wait --for=jsonpath='{.status.phase}'=Running pod/minio
oc exec -it minio -- mc config host add s3 http://localhost:9000 AKIAIT2Z5TDYPX3ARJBA fqRvjWaPU5o0fCqQuUWbj9Fainj2pVZtBCiDiieS --api S3v4
oc exec -it minio -- mc config host rm local
oc exec -it minio -- mc mb s3/pulp3 --region us-east-1
oc exec -it minio -- mc ls s3/
