# Hazelcast Operator

This is a step-by-step guide how to deploy Hazelcast cluster (together with Management Center) on your OpenShift or Kubernetes cluster.

## Prerequisites

You must have one of the followings:
 * OpenShift cluster (with admin rights) and the `oc` command configured (you may use [Minishift](https://github.com/minishift/minishift))
 * Kubernetes cluster (with admin rights) and the `kubectl` command configured (you may use [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/))

## Security Context Constraints (SCC) Requirements

Hazelcast uses Redhat shipped `restricted` SCC which :

- Ensures that pods cannot run as privileged.
- Ensures that pods cannot mount host directory volumes.
- Requires that a pod run as a user in a pre-allocated range of UIDs.
- Requires that a pod run with a pre-allocated MCS label.
- Allows pods to use any FSGroup.
- Allows pods to use any supplemental group.

You can refer to [Openshift Documentation](https://docs.openshift.com/) for more details.

## OpenShift Deployment steps

Below are the steps to start a Hazelcast cluster using Operator Framework. Note that the first 3 steps are usually performed only once for the OpenShift cluster/project (usually by the cluster admin). The step 4 is performed each time you want to create a new Hazelcast cluster.

Note: You need to clone this repository before following the next steps.

    git clone https://github.com/hazelcast/hazelcast-operator.git
    cd hazelcast-operator/hazelcast-operator

#### Step 0: Create project

To create a new project, run the following command.

    oc new-project hazelcast-operator
    
#### Step 1: Create RBAC

Run the following command to configure the Operator permissions.
   
    oc apply -f operator-rbac.yaml

Run the following command to configure the Hazelcast cluster permissions.

    oc apply -f hazelcast-rbac.yaml

#### Step 2: Create CRD (Custom Resource Definition)

To create the Hazelcast resource definition, run the following command.

    oc apply -f hazelcastcluster.crd.yaml


#### Step 3: Deploy Hazelcast Operator

Deploy Hazelcast Operator with the following command.

    oc apply -f operator.yaml

#### Step 4: Start Hazelcast

Start Hazelcast cluster with the following command.

    oc apply -f hazelcast.yaml

Your Hazelcast cluster (together with Management Center) should be created.

    $ oc get pods
    NAME                                 READY     STATUS    RESTARTS   AGE
    hazelcast-operator-b5bd8f7c7-7wqxh   1/1       Running   0          8m21s
    hz-hazelcast-0                       1/1       Running   0          3m55s
    hz-hazelcast-1                       1/1       Running   0          3m11s
    hz-hazelcast-2                       1/1       Running   0          2m25s
    hz-hazelcast-mancenter-0             1/1       Running   0          3m55s


**Note**: In `hazelcast.yaml` you can specify all parameters available in the [Hazelcast Helm Chart](https://github.com/hazelcast/charts/tree/master/stable/hazelcast).

**Note** also that you cannot create multiple Hazelcast clusters with the same name.

To connect to Management Center, you can use `EXTERNAL-IP` and open your browser at: `http://<EXTERNAL-IP>:8080/hazelcast-mancenter`. If your OpenShift environment does not have Load Balancer configured, then you can create a route to Management Center with `oc expose`.

![Management Center](../markdown/management-center.png)

## Kubernetes Deployment steps

Below are the steps to start a Hazelcast cluster using Operator Framework. Note that the first 3 steps are usually performed only once for the Kubernetes cluster (by the cluster admin). The step 4 is performed each time you want to create a new Hazelcast cluster.

Note: You need to clone this repository before following the next steps.

    git clone https://github.com/hazelcast/hazelcast-operator.git
    cd hazelcast-operator/hazelcast-operator

#### Step 1: Create RBAC

Run the following commands to configure the Operator permissions.

    kubectl apply -f operator-rbac.yaml

Run the following commands to configure the Hazelcast cluster permissions.

    kubectl apply -f hazelcast-rbac.yaml

#### Step 2: Create CRD (Custom Resource Definition)

To create the Hazelcast resource definition, run the following command.

    kubectl apply -f hazelcastcluster.crd.yaml

#### Step 3: Deploy Hazelcast Operator

Deploy Hazelcast Operator with the following command.

    kubectl --validate=false apply -f operator.yaml

#### Step 4: Start Hazelcast

Start Hazelcast cluster with the following command.

    kubectl apply -f hazelcast.yaml

Your Hazelcast cluster (together with Management Center) should be created.

    $ kubectl get pods
    NAME                                 READY     STATUS    RESTARTS   AGE
    hazelcast-operator-b5bd8f7c7-7wqxh   1/1       Running   0          8m21s
    hz-hazelcast-0                       1/1       Running   0          3m55s
    hz-hazelcast-1                       1/1       Running   0          3m11s
    hz-hazelcast-2                       1/1       Running   0          2m25s
    hz-hazelcast-mancenter-0             1/1       Running   0          3m55s

**Note**: In `hazelcast.yaml` you can specify all parameters available in the [Hazelcast Helm Chart](https://github.com/hazelcast/charts/tree/master/stable/hazelcast).

**Note** also that you cannot create multiple Hazelcast clusters with the same name.

To connect to Management Center, you can use `EXTERNAL-IP` and open your browser at: `http://<EXTERNAL-IP>:8080/hazelcast-mancenter`. If your Kubernetes environment does not have Load Balancer configured, then please use `NodePort` or `Ingress`.

![Management Center](../markdown/management-center.png)

## Configuration

You may want to modify the behavior of the Hazelcast Operator.

#### Changing Hazelcast and Management Center version

If you want to modify the Hazelcast or Management Center version, update `RELATED_IMAGE_HAZELCAST` and `RELATED_IMAGE_MANCENTER` environment variables in `operator-rhel.yaml` (or `operator-docker-hub.yaml`).

#### Configuring Hazelcast Cluster

Description of all parameters can be found [here](https://github.com/hazelcast/charts/tree/master/stable/hazelcast#configuration).

## Troubleshooting

Kubernetes/OpenShift clusters are deployed in many different ways and you may encounter some of the following issues in some environments.

#### Invalid value: must be no more than 63 characters

In the sample `hazelcast.yaml`, the name of the Hazelcast cluster is `hz`. If you make this value longer, you may encounter the following error.

    oc describe statefulset.apps/my-hazelcast-2esqhajupdg5002uqwgoc8jnj-hazelcast
     
    .......Invalid value: "my-hazelcast-2esqhajupdg5002uqwgoc8jnj-hazelcast-74cf94b5": must be no more than 63 characters
    
This is the issue of the Operator itself, so there is not better solution for now than giving your cluster a short name.

#### WriteNotAllowedException in Management Center

Some of the OpenShift environments may have the restriction on the User ID used in volume mounts, which may cause the following exception in Management Center.

    Caused by: com.hazelcast.webmonitor.service.exception.WriteNotAllowedException: WARNING: /data can not be created. Either make it writable, or set "hazelcast.mancenter.
    home" system property to a writable directory and restart.
            at com.hazelcast.webmonitor.service.HomeDirectoryProviderImpl.constructDirectory(HomeDirectoryProviderImpl.java:63)
            at com.hazelcast.webmonitor.service.HomeDirectoryProviderImpl.<init>(HomeDirectoryProviderImpl.java:25)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
            at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
            at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
            at org.springframework.beans.BeanUtils.instantiateClass(BeanUtils.java:142)
            ... 66 common frames omitted

In such case, please update your `hazelcast.yaml` with the valid `runAsUser` and `fsGroup` values.

    apiVersion: hazelcast.com/v1alpha1
    kind: Hazelcast
    metadata:
      name: hz
    spec:
    ...
      securityContext:
        runAsUser: 1000160000
        fsGroup: 1000160000

Note: You can find the UID range for your project with the following command `oc describe project <project-name> | grep openshift.io/sa.scc.uid-range`.
