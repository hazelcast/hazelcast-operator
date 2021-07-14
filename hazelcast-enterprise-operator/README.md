# Hazelcast Enterprise Operator

This is a step-by-step guide how to deploy Hazelcast Enterprise cluster (together with Management Center) on your OpenShift or Kubernetes cluster.

## Prerequisites

You must have one of the followings:
 * OpenShift cluster (with admin rights) and the `oc` command configured (you may use [Minishift](https://github.com/minishift/minishift))
 * Kubernetes cluster (with admin rights) and the `kubectl` command configured (you may use [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/))

 Versions compatibility:
 * hazelcast-enterprise-operator 0.2+ is compatible with hazelcast 4+
 * for older hazelcast versions, use hazelcast-enterprise-operator 0.1.x

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

Below are the steps to start a Hazelcast Enterprise cluster using Operator Framework. Note that the first 4 steps are usually performed only once for the OpenShift cluster/project (usually by the cluster admin). The step 5 is performed each time you want to create a new Hazelcast cluster.

Note: You need to clone this repository before following the next steps.

    git clone https://github.com/hazelcast/hazelcast-operator.git
    cd hazelcast-operator/hazelcast-enterprise-operator

Note: By default the communication is not secured. To enable SSL, read the [Configuring SSL](#configuring-ssl) section.

#### Step 0: Create project

To create a new project, run the following command.

    oc new-project hazelcast-operator

#### Step 1: Deploy Hazelcast Operator

Run the following command to configure the Hazelcast operator permissions, it will also deploy the operator.

    oc apply -f bundle-rhel.yaml

Note that if you prefer Docker Hub images, you can use `bundle.yaml` instead.


#### Step 2: Create RBAC

Run the following command to configure the Hazelcast cluster permissions.

    oc apply -f hazelcast-rbac.yaml


#### Step 3: Create Secret with Hazelcast License Key

Use base64 to encode your Hazelcast License Key. If you don't have one, get a trial key from this [link](https://hazelcast.com/hazelcast-enterprise-download/trial/).

    $ echo -n "<hazelcast-license-key>" | base64
    VU5MSU1JVEVEX0xJQ0VOU0UjOTlOb2RlcyMxMjM0NTY3ODlhYmNkZWZnaGlqa2xtbm9wcnN0d3kxMjM0NTY3ODkxMjM0NTY3ODkxMTExMTExMTExMTE=

Insert this value into `secret.yaml`, replace `<base64-hz-license-key>`. Then, create the secret.

    oc apply -f secret.yaml

#### Step 4: Start Hazelcast

Start Hazelcast cluster with the following command.

    oc apply -f hazelcast.yaml

Your Hazelcast Enterprise cluster (together with Management Center) should be created.

    $ oc get pods
    NAME                                             READY     STATUS    RESTARTS   AGE
    hazelcast-enterprise-operator-7965b9d785-wst5k   1/1       Running   0          2m39s
    hz-hazelcast-enterprise-0                        1/1       Running   0          2m6s
    hz-hazelcast-enterprise-1                        1/1       Running   0          86s
    hz-hazelcast-enterprise-2                        1/1       Running   0          44s
    hz-hazelcast-enterprise-mancenter-0              1/1       Running   0          2m6s


**Note**: In `hazelcast.yaml` you can specify all parameters available in the [Hazelcast Enterprise Helm Chart](https://github.com/hazelcast/charts/tree/master/stable/hazelcast-enterprise).

**Note** also that you cannot create multiple Hazelcast clusters with the same name.

To connect to Management Center, you can use `EXTERNAL-IP` and open your browser at: `http://<EXTERNAL-IP>:8080/hazelcast-mancenter`. If your OpenShift environment does not have Load Balancer configured, then you can create a route to Management Center with `oc expose`.

![Management Center](../markdown/management-center.png)

## RedHat Marketplace Quick Start Guide

### Step 1: Prequisities

You must have the following to install Hazelcast Enterprise IMDG on your Red Hat OpenShift cluster or Trial cluster:

- [OpenShift CLI](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html)
- Project/Namespace to deploy your Hazelcast cluster.

        $ oc new-project <project name>

### Step 2: Operator Installation from RedHat Marketplace

1. For information on registering your cluster and creating a project/namespace, see [Red Hat Marketplace Docs](https://marketplace.redhat.com/en-us/documentation/clusters). This must be done prior to operator install.
2. On the main menu, click **Workspace > My Software > Hazelcast IMDG Product > Install Operator**.
3. On the **Update Channel** section, select an option.
4. On the **Approval Strategy** section, select either **Automatic or Manual**. The approval strategy corresponds to how you want to process operator upgrades.
5. On the **Target Cluster** section:
    - Click the checkbox next to the clusters where you want to install the Operator.
    - For each cluster you selected, under **Namespace Scope**, on the **Select Scope** list, select an option.
6. Click **Install**. It may take several minutes for installation to complete.
7. Once installation is complete, the status will change from **Installing** to **Up to date**.
8. For further information, see the [Red Hat Marketplace Operator documentation](https://marketplace.redhat.com/en-us/documentation/operators).


### Step 3: Verification of Hazelcast Operator installation

1. Once status changes to Up to date, click the vertical ellipses and select Cluster Console.
2. Open the cluster where you installed the product
3. Go to **Operators > Installed Operators**
4. Select the **Namespace** or **Project** you installed on
5. Verify status for product is **Succeeded**

### Step 4: Hazelcast Enterprise Cluster and Management Center installation

1. Run the following command to configure the Hazelcast cluster permissions.

        $ oc apply -f https://raw.githubusercontent.com/hazelcast/hazelcast-operator/master/hazelcast-enterprise-operator/hazelcast-rbac.yaml

2. Hazelcast Enterprise license key. If you don't have one, get a trial key from this [link](https://hazelcast.com/get-started/#hazelcast-imdg/). Add a Secret within the Project that contains the Hazelcast License Key:

        $ oc create secret generic hz-license-key-secret --from-literal=key=LICENSE-KEY-HERE

3. Create Hazelcast Enterprise custom resource YAML file with minimal config:

        apiVersion: hazelcast.com/v1alpha1
        kind: HazelcastEnterprise
        metadata:
          name: hz
          namespace: <project/namespace>
        spec:
          hazelcast:
            licenseKeySecretName: hz-license-key-secret
          securityContext:
            runAsUser: ''
            runAsGroup: ''
            fsGroup: ''


    If you want modify Hazelcast Enterprise IMDG configuration, you can check all configuration options in [hazelcast-full.yaml](https://github.com/hazelcast/hazelcast-operator/blob/master/hazelcast-enterprise-operator/hazelcast-full.yaml). Description of all parameters can be found [here](https://github.com/hazelcast/charts/tree/master/stable/hazelcast-enterprise#configuration).

4. Start Hazelcast Enterprise IMDG cluster and Management Center with the following command:

        $ oc apply -f < minimal config yaml >

5. Check the last status of your Hazelcast Enterprise IMDG cluster and Management Center:

        $ oc get pods
        NAME                                             READY     STATUS    RESTARTS   AGE
        hazelcast-enterprise-operator-7965b9d785-wst5k   1/1       Running   0          2m39s
        hz-hazelcast-enterprise-0                        1/1       Running   0          2m6s
        hz-hazelcast-enterprise-1                        1/1       Running   0          86s
        hz-hazelcast-enterprise-2                        1/1       Running   0          44s
        hz-hazelcast-enterprise-mancenter-0              1/1       Running   0          2m6s

6. To connect to Management Center dashboard, you can use `EXTERNAL-IP` and open your browser at: `http://<EXTERNAL-IP>:8080`.

        $ oc get services
        NAME                                TYPE           EXTERNAL-IP
        ...
        hz-hazelcast-enterprise-mancenter   LoadBalancer   ...eu-west-3.elb.amazonaws.com

    ![Management Center](../markdown/management-center.png)

    If your OpenShift environment does not have Load Balancer configured, then you can create a route to Management Center with `oc expose`:

        $ oc expose svc/hz-hazelcast-enterprise-mancenter

    Then you can reach its dashboard via route URL.


## Kubernetes Deployment steps

Below are the steps to start a Hazelcast Enterprise cluster using Operator Framework. Note that the first 4 steps are usually performed only once for the Kubernetes cluster (by the cluster admin). The step 5 is performed each time you want to create a new Hazelcast cluster.

Note: You need to clone this repository before following the next steps.

    git clone https://github.com/hazelcast/hazelcast-operator.git
    cd hazelcast-operator/hazelcast-enterprise-operator

#### Step 1: Deploy Hazelcast Operator

Deploy Hazelcast Operator with the following command.

    kubectl --validate=false apply -f bundle.yaml

#### Step 2: Create RBAC

Run the following commands to configure the Hazelcast cluster permissions.

    kubectl apply -f hazelcast-rbac.yaml

#### Step 3: Create Secret with Hazelcast License Key

Use base64 to encode your Hazelcast License Key. If you don't have one, get a trial key from this [link](https://hazelcast.com/hazelcast-enterprise-download/trial/).

    $ echo -n "<hazelcast-license-key>" | base64
    VU5MSU1JVEVEX0xJQ0VOU0UjOTlOb2RlcyMxMjM0NTY3ODlhYmNkZWZnaGlqa2xtbm9wcnN0d3kxMjM0NTY3ODkxMjM0NTY3ODkxMTExMTExMTExMTE=

Insert this value into `secret.yaml`, replace `<base64-hz-license-key>`. Then, create the secret.

    kubectl apply -f secret.yaml

#### Step 4: Start Hazelcast

Before starting the cluster, you need to remove the `securityContext` part from `hazelcast.yaml`.


```
 securityContext:
    runAsUser: ""
    runAsGroup: ""
    fsGroup: ""
```

After deletion, you can start the Hazelcast cluster with the following command.

    kubectl apply -f hazelcast.yaml

Your Hazelcast Enterprise cluster (together with Management Center) should be created.

    $ kubectl get pods
    NAME                                                                  READY   STATUS    RESTARTS   AGE
    pod/hazelcast-enterprise-operator-79468c667-lz96b                     1/1     Running   0          6m
    pod/hz-hazelcast-enterprise-0                                         1/1     Running   0          3m
    pod/hz-hazelcast-enterprise-1                                         1/1     Running   0          2m
    pod/hz-hazelcast-enterprise-2                                         1/1     Running   0          1m
    pod/hz-hazelcast-enterprise-mancenter-0                               1/1     Running   0          1m

**Note**: In `hazelcast.yaml` you can specify all parameters available in the [Hazelcast Enterprise Helm Chart](https://github.com/hazelcast/charts/tree/master/stable/hazelcast-enterprise).

**Note** also that you cannot create multiple Hazelcast clusters with the same name.

To connect to Management Center, you can use `EXTERNAL-IP` and open your browser at: `http://<EXTERNAL-IP>:8080/hazelcast-mancenter`. If your Kubernetes environment does not have Load Balancer configured, then please use `NodePort` or `Ingress`.

![Management Center](../markdown/management-center.png)

## Configuration

You may want to modify the behavior of the Hazelcast Enterprise Operator.

#### Changing Hazelcast and Management Center version

If you want to modify the Hazelcast or Management Center version, update `RELATED_IMAGE_HAZELCAST` and `RELATED_IMAGE_MANCENTER` environment variables in `operator-rhel.yaml` (or `operator-docker-hub.yaml`).

#### Configuring Hazelcast Cluster

You can check all configuration options in [hazelcast-full.yaml](https://github.com/hazelcast/hazelcast-operator/blob/master/hazelcast-enterprise-operator/hazelcast-full.yaml). Description of all parameters can be found [here](https://github.com/hazelcast/charts/tree/master/stable/hazelcast-enterprise#configuration).

#### Configuring SSL

By default the communication is not secured. To enable SSL-protected communication between members and clients, you need first to provide the keys and certificates as a secret.

For example, if you use keystore/truststore, then you can import them with the following OpenShift command.

    $ oc create secret generic keystore --from-file=./keystore --from-file=./truststore

The same command for Kubernetes looks as follows.

    $ kubectl create secret generic keystore --from-file=./keystore --from-file=./truststore

Then, since Kubernetes liveness/readiness probes cannot use SSL, we need to prepare Hazelcast configuration with a separate non-secured port opened for health checks. Create a file `hazelcast.yaml`.

```yaml
hazelcast:
  advanced-network:
    enabled: true
    join:
      kubernetes:
        enabled: true
        service-name: ${serviceName}
        service-port: 5702
        namespace: ${namespace}
    member-server-socket-endpoint-config:
      port:
        port: 5702
      ssl:
        enabled: true
    client-server-socket-endpoint-config:
      port:
        port: 5701
      ssl:
        enabled: true
    rest-server-socket-endpoint-config:
      port:
        port: 5703
      endpoint-groups:
        HEALTH_CHECK:
          enabled: true
```

Then, add this configuration as a ConfigMap.

    $ oc create configmap hazelcast-configuration --from-file=hazelcast.yaml

Or in case of Kubernetes, use the following command.

    $ kubectl create configmap hazelcast-configuration --from-file=hazelcast.yaml

Then, use the following Hazelcast configuration.

```yaml
apiVersion: hazelcast.com/v1alpha1
kind: HazelcastEnterprise
metadata:
  name: hz
spec:
...
  secretsMountName: keystore
  hazelcast:
    licenseKeySecretName: hz-license-key
    javaOpts: '-Djavax.net.ssl.keyStore=/data/secrets/keystore -Djavax.net.ssl.keyStorePassword=123456 -Djavax.net.ssl.trustStore=/data/secrets/truststore -Djavax.net.ssl.trustStorePassword=123456'
    existingConfigMap: hazelcast-configuration
  livenessProbe:
    port: 5703
  readinessProbe:
    port: 5703
  mancenter:
    secretsMountName: keystore
    yaml:
      hazelcast-client:
        network:
          ssl:
            enabled: true
    javaOpts: '-Djavax.net.ssl.keyStore=/secrets/keystore -Djavax.net.ssl.keyStorePassword=123456 -Djavax.net.ssl.trustStore=/secrets/truststore -Djavax.net.ssl.trustStorePassword=123456'
```

For more information on Hazelcast Security check the following resources:

* [Hazelcast Kubernetes SSL Guide](https://guides.hazelcast.org/kubernetes-ssl/)
* [Hazelcast Reference Manual - Security](https://docs.hazelcast.com/imdg/latest/security/security.html)
* [Management Center Reference Manual - Security](https://docs.hazelcast.org/docs/management-center/latest/manual/html/index.html#configuring-and-enabling-security)

## Troubleshooting

Kubernetes/OpenShift clusters are deployed in many different ways and you may encounter some of the following issues in some environments.

#### Invalid value: must be no more than 63 characters

In the sample `hazelcast.yaml`, the name of the Hazelcast cluster is `hz`. If you make this value longer, you may encounter the following error.

    oc describe statefulset.apps/my-hazelcast-2esqhajupdg5002uqwgoc8jnj-hazelcast-enterprise

    .......Invalid value: "my-hazelcast-2esqhajupdg5002uqwgoc8jnj-hazelcast-enterprise-74cf94b5": must be no more than 63 characters

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
    kind: HazelcastEnterprise
    metadata:
      name: hz
    spec:
    ...
      securityContext:
        runAsUser: 1000160000
        fsGroup: 1000160000

Note: You can find the UID range for your project with the following command `oc describe project <project-name> | grep openshift.io/sa.scc.uid-range`.
