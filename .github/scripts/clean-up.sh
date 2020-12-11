#!/bin/bash

set -e
set -o pipefail

# Clean up after test
WORKDIR=$1
PROJECT=$2

oc delete -f ${WORKDIR}/hazelcast.yaml
oc delete -f ${WORKDIR}/secret.yaml
oc delete -f ${WORKDIR}/operator-rhel.yaml
oc delete -f ${WORKDIR}/hazelcastcluster.crd.yaml
oc delete -f ${WORKDIR}/hazelcast-rbac.yaml
oc delete -f ${WORKDIR}/operator-rbac.yaml
oc delete secret pull-secret
oc delete project $PROJECT

oc logout