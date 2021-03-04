#!/bin/bash

set -e
set -o pipefail

# Clean up after test
WORKDIR=$1
PROJECT=$2

oc delete -f  ${WORKDIR}/hazelcast.yaml --wait=true
oc delete -f  ${WORKDIR}/secret.yaml --wait=true
oc delete -f  ${WORKDIR}/hazelcast-rbac.yaml --wait=true

oc delete --wait=true rolebinding hazelcast-enterprise-operator
oc delete --wait=true clusterrole hazelcast-enterprise-operator
oc delete --wait=true serviceaccount hazelcast-enterprise-operator
oc delete --wait=true deployment hazelcast-enterprise-operator

oc delete --wait=true secret pull-secret
oc delete project $PROJECT --wait=true

oc logout