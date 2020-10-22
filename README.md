### Create Bundle Image
Each Bundle image for a single operator version. You can use the tool [opm](https://github.com/operator-framework/operator-registry/blob/master/docs/design/opm-tooling.md#opm) to do this. Steps as follows:
1. Run the `opm alpha bundle build` command:
```console
$ opm alpha bundle build -c 0.0.1, 0.0.2 -e 0.0.1 -d ./ manifests/learn/0.0.1/ -p learn -t quay.io/olmqe/learn-operator-bundle:v1
INFO[0000] Building annotations.yaml                    
INFO[0000] Writing annotations.yaml in /data/goproject/src/github.com/jianzhangbjz/learn-operator/manifests/learn/metadata 
INFO[0000] Building Dockerfile                          
INFO[0000] Writing bundle.Dockerfile in /data/goproject/src/github.com/jianzhangbjz/learn-operator/manifests 
INFO[0000] Building bundle image                        
Sending build context to Docker daemon  179.7kB
Step 1/9 : FROM scratch
 ---> 
Step 2/9 : LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
 ---> Using cache
 ---> 7e95ac289bf7
Step 3/9 : LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
 ---> Using cache
 ---> c7798578d997
Step 4/9 : LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
 ---> Using cache
 ---> a4cf559f3fb0
Step 5/9 : LABEL operators.operatorframework.io.bundle.package.v1=learn
 ---> Running in 359602eb2125
Removing intermediate container 359602eb2125
 ---> 284edc1a52d6
Step 6/9 : LABEL operators.operatorframework.io.bundle.channels.v1=0.0.1,
 ---> Running in c94d5babcb7d
Removing intermediate container c94d5babcb7d
 ---> 053dffd07355
Step 7/9 : LABEL operators.operatorframework.io.bundle.channel.default.v1=0.0.1
 ---> Running in f5d7e48665f8
Removing intermediate container f5d7e48665f8
 ---> 9477882f546b
Step 8/9 : COPY learn/0.0.1 /manifests/
 ---> c5fd2cb76085
Step 9/9 : COPY learn/metadata /metadata/
 ---> 84d985ca43c5
Successfully built 84d985ca43c5
Successfully tagged quay.io/olmqe/learn-operator-bundle:v1
```
2. Push this image to the Quay.io registry, and make it public.
```console
$ docker push quay.io/olmqe/learn-operator-bundle:v1
The push refers to repository [quay.io/olmqe/learn-operator-bundle]
2f161fcac2d0: Pushed 
8b4c261611af: Pushed 
v1: digest: sha256:5a0a4d18a1ac46b22e09e5052e42aeabbe603006b603e08297f8a8e50ee2c343 size: 732
```

### Create Index Image
1. Run `opm index add` command, like
```console
$ opm index add -b quay.io/olmqe/learn-operator-bundle:v1 -t quay.io/olmqe/learn-operator-index:v1
INFO[0000] building the index                            bundles="[quay.io/olmqe/learn-operator-bundle:v1]"
INFO[0000] resolved name: quay.io/olmqe/learn-operator-bundle:v1 
INFO[0000] fetched                                       digest="sha256:5a0a4d18a1ac46b22e09e5052e42aeabbe603006b603e08297f8a8e50ee2c343"
INFO[0000] fetched                                       digest="sha256:078cddf8bb1fa7c6f24ed8cf677f7e5a455c2770668904db955085a4fe154e08"
INFO[0000] fetched                                       digest="sha256:84d985ca43c5e5c0a9b6a2c58482d7cf2acc5fda44c1e6ff28d32932f0736a2c"
INFO[0000] fetched                                       digest="sha256:11a088f33d1202b278d197166978dd54b24e493251f949fbe710d03bbc719e52"
INFO[0000] unpacking layer: {application/vnd.docker.image.rootfs.diff.tar.gzip sha256:11a088f33d1202b278d197166978dd54b24e493251f949fbe710d03bbc719e52 1590 [] map[] <nil>} 
INFO[0000] unpacking layer: {application/vnd.docker.image.rootfs.diff.tar.gzip sha256:078cddf8bb1fa7c6f24ed8cf677f7e5a455c2770668904db955085a4fe154e08 285 [] map[] <nil>} 
INFO[0000] Could not find optional dependencies file     dir=bundle_tmp889724958 file=bundle_tmp889724958/metadata load=annotations
INFO[0000] found csv, loading bundle                     dir=bundle_tmp889724958 file=bundle_tmp889724958/manifests load=bundle
INFO[0000] loading bundle file                           dir=bundle_tmp889724958/manifests file=learn-operator.v0.0.1.clusterserviceversion.yaml load=bundle
INFO[0000] loading bundle file                           dir=bundle_tmp889724958/manifests file=learn.crd.yaml load=bundle
INFO[0000] Generating dockerfile                         bundles="[quay.io/olmqe/learn-operator-bundle:v1]"
INFO[0000] writing dockerfile: index.Dockerfile794041612  bundles="[quay.io/olmqe/learn-operator-bundle:v1]"
INFO[0000] running podman build                          bundles="[quay.io/olmqe/learn-operator-bundle:v1]"
INFO[0000] [podman build --format docker -f index.Dockerfile794041612 -t quay.io/olmqe/learn-operator-index:v1 .]  bundles="[quay.io/olmqe/learn-operator-bundle:v1]"
```
2. Push this index image to Quay.io and make it public.
```console
$ podman push quay.io/olmqe/learn-operator-index:v1
Getting image source signatures
Copying blob afef313ed14c done  
Copying blob 4150c4f2e6df skipped: already exists  
Copying blob 5a2855009e89 skipped: already exists  
Copying blob 87b4d8523d6d skipped: already exists  
Copying blob 50644c29ef5a skipped: already exists  
Copying config cf42b3cf7c done  
Writing manifest to image destination
Writing manifest to image destination
Storing signatures
```

## Deploy it on OCP4.x
1. Create and deploy the CatalogSource for it, like below:
```console
$ cat cs-learn.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: demo-learn
  namespace: openshift-marketplace
spec:
  displayName: Jian Test
  publisher: Jian
  sourceType: grpc
  image: quay.io/olmqe/learn-operator-index:v1
  updateStrategy:
    registryPoll:
      interval: 10m

$ oc create -f cs-learn.yaml 
catalogsource.operators.coreos.com/demo-learn created

$ oc get catalogsource
NAME                  DISPLAY                TYPE   PUBLISHER      AGE
certified-operators   Certified Operators    grpc   Red Hat        41m
community-operators   Community Operators    grpc   Red Hat        41m
demo-learn            Jian Test              grpc   Jian           7s
qe-app-registry       Production Operators   grpc   OpenShift QE   22m
redhat-marketplace    Red Hat Marketplace    grpc   Red Hat        41m
redhat-operators      Red Hat Operators      grpc   Red Hat        41m

$ oc get packagemanifest|grep learn
learn                                                Jian Test              31s
```
2. Subscribe this `learn-operator`, you can do this on WebConsole too.
In the backend, you need to create the OperatorGroup object first, like below: 
```console
$ cat og.yaml 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: test-og
  namespace: default
spec:
  targetNamespaces:
  - default

$ cat sub-learn.yaml 
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
```
After create them, you will get the below objects:
```console
$ oc get sub -n default
NAME    PACKAGE   SOURCE       CHANNEL
learn   learn     demo-learn   0.0.1
$ oc get ip -n default
NAME            CSV                     APPROVAL    APPROVED
install-26wbx   learn-operator.v0.0.1   Automatic   true
$ oc get csv -n default
NAME                    DISPLAY          VERSION   REPLACES   PHASE
learn-operator.v0.0.1   Learn Operator   0.0.1                Succeeded
```

### Create the Learn CR
You will get an `example-learn` instance and its two pods, as follows:
```console
# cat learn-instance.yaml 
apiVersion: app.learn.com/v1
kind: Learn
metadata:
  name: example-learn
  namespace: default
spec:
  size: 2

$ oc get learn -n default
NAME            AGE
example-learn   34m
$ oc get pods -n default
NAME                             READY   STATUS    RESTARTS   AGE
example-learn-85fc47cf75-7fq2m   1/1     Running   0          34m
example-learn-85fc47cf75-jv9mg   1/1     Running   0          34m
learn-operator-9cd7b7d5c-ffxs9   1/1     Running   0          40m
```

