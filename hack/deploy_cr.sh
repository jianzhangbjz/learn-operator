#!/bin/bash

echo "Deploy the Learn CR: example-learn"
cat <<EOF | oc create -f -
apiVersion: app.learn.com/v1
kind: Learn
metadata:
  name: example-learn
  namespace: default
spec:
  size: 2
EOF
