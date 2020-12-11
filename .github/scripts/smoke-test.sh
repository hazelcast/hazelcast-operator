#!/bin/bash

set -e
set -o pipefail

# Fill the variables before running the script
WORKDIR=$1
PROJECT=$2
HZ_ENTERPRISE_LICENSE=$3
LOGIN_USERNAME=$4
LOGIN_PASSWORD=$5
OCP_CLUSTER_URL=$6
RED_HAT_USERNAME=unused
RED_HAT_PASSWORD=$7
RED_HAT_EMAIL=unused
HAZELCAST_CLUSTER_SIZE=$8
MANAGEMENT_CENTER_REPLICAS=$9
LOGIN_COMMAND="oc login ${OCP_CLUSTER_URL} -u=${LOGIN_USERNAME} -p=${LOGIN_PASSWORD}"

# LOG INTO OpenShift
eval "${LOGIN_COMMAND}"

# CREATE PROJECT
oc new-project $PROJECT

oc create secret docker-registry pull-secret \
 --docker-server=scan.connect.redhat.com \
 --docker-username=$RED_HAT_USERNAME \
 --docker-password=$RED_HAT_PASSWORD \
 --docker-email=$RED_HAT_EMAIL

oc apply -f ${WORKDIR}/operator-rbac.yaml
oc apply -f ${WORKDIR}/hazelcast-rbac.yaml
oc apply -f ${WORKDIR}/hazelcastcluster.crd.yaml

oc secrets link hazelcast-enterprise-operator pull-secret --for=pull
oc apply -f ${WORKDIR}/operator-rhel.yaml

# CREATE HAZELCAST ENTERPRISE KEY SECRET
LICENSE_KEY=$(echo -n "${HZ_ENTERPRISE_LICENSE}" | base64 -w 0)
sed -i  "s/key: <base64-hz-license-key>/key: ${LICENSE_KEY}/g" ${WORKDIR}/secret.yaml
oc apply -f ${WORKDIR}/secret.yaml

oc apply -f ${WORKDIR}/hazelcast.yaml
