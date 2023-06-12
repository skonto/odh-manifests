# KServe

KServe comes with two component:

1. [KServe](#KServe)
2. [KServe runtimes](#KServe-Runtimes)

## KServe

Contains deployment manifests for the KServe controller.

- [kserve-controller](https://github.com/opendatahub-io/kserve)
  - Forked upstream kserve/kserve repository

## KServe runtimes

Contains the runtime manifests for KServe.

- [kserve-controller](https://github.com/opendatahub-io/kserve)
  - Forked upstream kserve/kserve repository

## Original manifests

KServe also uses `kustomize` so we can directly use [their manifests](https://github.com/opendatahub-io/kserve/tree/master/config).

* `default` is the entrypoint for CRDs, KServe controller and RBAC resources.
* `runtimes` is the second entrypoint for the KServe runtimes. They are referenced separately, as these are not namespaced.

The KServe manifests are directly referenced in our [overlays](#overlays).


## Overlays

There are two overlays defined with the necessary changes for ODH:

* [controller](./odh-overlays/controller)
* [runtimes](./odh-overlays/runtimes)


### Installation process

Following are the steps to install Model Mesh as a part of OpenDataHub install:

1. Install the OpenDataHub operator
2. Make sure you install Service Mesh and Serverless components and configure them appropriately
3. Create a KfDef that includes the KServe components and runtimes

```
apiVersion: kfdef.apps.kubeflow.org/v1
kind: KfDef
metadata:
  name: opendatahub
  namespace: opendatahub
spec:
  applications:
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: odh-common
      name: odh-common
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: kserve
      name: kserve
  repos:
    - name: manifests
      uri: https://api.github.com/repos/opendatahub-io/odh-manifests/tarball/master
  version: master
```

4. You can now create a new project and create an `InferenceService` CR.

## Using KServe in ODH

You can use the `InferenceService` examples from KServe. Make sure to include the additional annotation for OpenShift Service Mesh:

```yaml
metadata:
  annotations:
    sidecar.istio.io/inject: "true"
    sidecar.istio.io/rewriteAppHTTPProbers: "true"
    serving.knative.openshift.io/enablePassthrough: "true"
```

Example:

```yaml
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "sklearn-iris"
  namespace: kserve-demo
  annotations:
    sidecar.istio.io/inject: "true"
    sidecar.istio.io/rewriteAppHTTPProbers: "true"
    serving.knative.openshift.io/enablePassthrough: "true"
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      storageUri: "gs://kfserving-examples/models/sklearn/1.0/model"
```

## Limitations

Currently, the target namespace service account must be allowed to run as `anyuid`, so allow this using:

```bash
oc adm policy add-scc-to-user anyuid -z default -n <your-namespace>
```

**Reason**
* for istio: allow to run as user 1337 because of https://istio.io/latest/docs/setup/additional-setup/cni/#compatibility-with-application-init-containers
* for the python images of KServe: allow to run as user 1000 because of: https://github.com/kserve/kserve/blob/master/python/aiffairness.Dockerfile#L46
