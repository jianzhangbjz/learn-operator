#!/bin/bash

INDEX_IMAGE="quay.io/olmqe/learn-operator-index:v1"

echo "Deploy the CatalogSource"
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: demo-learn
  namespace: openshift-marketplace
spec:
  displayName: Jian Test
  publisher: Jian
  sourceType: grpc
  image: ${INDEX_IMAGE}
  updateStrategy:
    registryPoll:
      interval: 10m
EOF

echo "Subscribe to Learn Operator"
cat <<EOF | oc create -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: test-og
  namespace: default
spec:
  targetNamespaces:
  - default
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: learn
  namespace: default
spec:
  channel: 0.0.1
  installPlanApproval: Automatic
  name: learn
  source: demo-learn
  sourceNamespace: openshift-marketplace
  startingCSV: learn-operator.v0.0.1
EOF
