### Compile the Binary
You can run the `make build` command to get the `learn-operator` binary. As follow:
```console
$ make build
mkdir -p "build/_output/bin/"
export GO111MODULE=on && export GOPROXY=https://goproxy.io && go build -o "build/_output/bin//learn-operator" "./cmd/manager/main.go"

$ ls -l build/_output/bin/learn-operator 
-rwxr-xr-x. 1 root root 39674923 Oct 22 22:23 build/_output/bin/learn-operator
$ ./build/_output/bin/learn-operator --help
Usage of ./build/_output/bin/learn-operator:
      --kubeconfig string                Paths to a kubeconfig. Only required if out-of-cluster.
      --master --kubeconfig              (Deprecated: switch to --kubeconfig) The address of the Kubernetes API server. Overrides any value in kubeconfig. Only required if out-of-cluster.
      --zap-devel                        Enable zap development mode (changes defaults to console encoder, debug log level, and disables sampling)
      --zap-encoder encoder              Zap log encoding ('json' or 'console')
      --zap-level level                  Zap log level (one of 'debug', 'info', 'error' or any integer value > 0) (default info)
      --zap-sample sample                Enable zap log sampling. Sampling will be disabled for integer log levels > 1
      --zap-time-encoding timeEncoding   Sets the zap time format ('epoch', 'millis', 'nano', or 'iso8601') (default )
pflag: help requested
```

### Create a Docker image for this binary
You can use this [Dockerfile](https://github.com/jianzhangbjz/learn-operator/blob/master/build/Dockerfile), as follows:
```console
$ docker build -f build/Dockerfile -t quay.io/olmqe/learn-operator:v1 .
Sending build context to Docker daemon  40.27MB
Step 1/7 : FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
latest: Pulling from ubi8/ubi-minimal
0fd3b5213a9b: Already exists 
aebb8c556853: Already exists 
Digest: sha256:5cfbaf45ca96806917830c183e9f37df2e913b187aadb32e89fd83fa455ebaa6
Status: Downloaded newer image for registry.access.redhat.com/ubi8/ubi-minimal:latest
 ---> 28095021e526
Step 2/7 : ENV OPERATOR=/usr/local/bin/learn-operator     USER_UID=1001     USER_NAME=learn-operator
 ---> Running in 8ea785dc7d31
Removing intermediate container 8ea785dc7d31
 ---> e58d351d046f
Step 3/7 : COPY build/_output/bin/learn-operator ${OPERATOR}
 ---> 24a495093ff2
Step 4/7 : COPY build/bin /usr/local/bin
 ---> b31ea373b410
Step 5/7 : RUN  /usr/local/bin/user_setup
 ---> Running in 203017c7df32
+ mkdir -p /root
+ chown 1001:0 /root
+ chmod ug+rwx /root
+ chmod g+rw /etc/passwd
+ rm /usr/local/bin/user_setup
Removing intermediate container 203017c7df32
 ---> 7217a26389de
Step 6/7 : ENTRYPOINT ["/usr/local/bin/entrypoint"]
 ---> Running in 4f2253ae0857
Removing intermediate container 4f2253ae0857
 ---> eca03f1431ac
Step 7/7 : USER ${USER_UID}
 ---> Running in 418b6dd2d390
Removing intermediate container 418b6dd2d390
 ---> 6d1c3e2b3445
Successfully built 6d1c3e2b3445
Successfully tagged quay.io/olmqe/learn-operator:v1
```

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

## Build the multi-arch image
### Build the operator image
Based on the https://github.com/docker/buildx#building-multi-platform-images description, I build the multi-arch image on `MacOS`.
1. The base image should support multi-arch. You can check it by using the `docker buildx imagetools inspect xxx` command. For example, the current `Dockerfile` as follows,
```yaml
FROM golang:1.17 as build
COPY . /app/
WORKDIR /app
RUN go build -mod=vendor -o "/app/build/bin/learn-operator" "/app/cmd/manager/main.go"

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
COPY --from=build  /app/build/bin /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/learn-operator"]
```
Let's check the base image: `registry.access.redhat.com/ubi8/ubi-minimal:latest`, as follows, it supports the `linux/amd64, linux/arm64, linux/ppc64le, linux/s390x` four platforms.
```yaml
mac:learn-operator jianzhang$ docker buildx imagetools inspect registry.access.redhat.com/ubi8/ubi-minimal:latest
Name:      registry.access.redhat.com/ubi8/ubi-minimal:latest
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:574f201d7ed185a9932c91cef5d397f5298dff9df08bc2ebb266c6d1e6284cd1
           
Manifests: 
  Name:      registry.access.redhat.com/ubi8/ubi-minimal:latest@sha256:c1cd272f2ffd1d4ae660bdd31d08f2072e9a6a0805d4d31730dc475e55296948
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64
             
  Name:      registry.access.redhat.com/ubi8/ubi-minimal:latest@sha256:9bf78e321fd7fe46075971a83c6f92e48cbc35b546bf9af72b865fc45673d562
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64
             
  Name:      registry.access.redhat.com/ubi8/ubi-minimal:latest@sha256:aeba4dfe9297d322afe7f633e6b3ebe0c80dc282e60d5755765d3a26b4d7d05b
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/ppc64le
             
  Name:      registry.access.redhat.com/ubi8/ubi-minimal:latest@sha256:1049e0a6e05d8e839060f51e3b838439f7e38d0a3497b2504da8107603c8ba92
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/s390x
```
2. Create a `Builder` instance that its driver should be `docker-container` or `kubernetes`, as follows,
```yaml
mac:learn-operator jianzhang$ docker buildx create --use --name jian
jian
mac:learn-operator jianzhang$ docker buildx ls
NAME/NODE       DRIVER/ENDPOINT             STATUS   PLATFORMS
elegant_wu      docker-container                     
  elegant_wu0   unix:///var/run/docker.sock stopped  
jian *          docker-container                     
  jian0         unix:///var/run/docker.sock inactive 
desktop-linux   docker                               
  desktop-linux desktop-linux               running  linux/amd64, linux/arm64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
default         docker                               
  default       default                     running  linux/amd64, linux/arm64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```
3. Start to build the multi-arch image based on the current `Dockerfile`. Note that the `--platform` args should match the base image's supported platforms.
```yaml
mac:learn-operator jianzhang$ docker buildx build --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t quay.io/olmqe/learn-operator:v2 --push .
[+] Building 1034.8s (11/35)                                                                                                                   
[+] Building 1035.0s (11/35)                                                                                                                   
[+] Building 2175.2s (29/35)                                                                                                                   
[+] Building 3497.0s (29/35)                                                                                                                   
[+] Building 3562.8s (29/35)                                                                                                                   
[+] Building 4890.8s (37/37) FINISHED                                                                                                          
 => [internal] load build definition from Dockerfile                                                                                      0.0s
 => => transferring dockerfile: 330B                                                                                                      0.0s
 => [internal] load .dockerignore                                                                                                         0.0s
 => => transferring context: 2B                                                                                                           0.0s
 => [linux/s390x internal] load metadata for registry.access.redhat.com/ubi8/ubi-minimal:latest                                           9.8s
 => [linux/s390x internal] load metadata for docker.io/library/golang:1.17                                                                4.5s
 => [linux/arm64 internal] load metadata for registry.access.redhat.com/ubi8/ubi-minimal:latest                                           6.7s
 => [linux/arm64 internal] load metadata for docker.io/library/golang:1.17                                                                7.1s
 => [linux/amd64 internal] load metadata for registry.access.redhat.com/ubi8/ubi-minimal:latest                                           5.0s
 => [linux/amd64 internal] load metadata for docker.io/library/golang:1.17                                                                7.2s
 => [linux/ppc64le internal] load metadata for registry.access.redhat.com/ubi8/ubi-minimal:latest                                         9.6s
 => [linux/ppc64le internal] load metadata for docker.io/library/golang:1.17                                                              8.2s
 ...
 => => pushing layers                                                                                                                   139.5s
 => => pushing manifest for quay.io/olmqe/learn-operator:v2@sha256:f6a1edff25fe0d666b50dd8128122e20e8248808859c895f48c7ec5ef6c3e3a5       6.3s
 => [auth] olmqe/learn-operator:pull,push token for quay.io   
```
Done, check if it support the multi-arch now,
```yaml
mac:learn-operator jianzhang$ docker buildx imagetools inspect quay.io/olmqe/learn-operator:v2
Name:      quay.io/olmqe/learn-operator:v2
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:f6a1edff25fe0d666b50dd8128122e20e8248808859c895f48c7ec5ef6c3e3a5
           
Manifests: 
  Name:      quay.io/olmqe/learn-operator:v2@sha256:befdb773305baaca896355ccdd72c84f009a3fc19e23fb1879339545ad6e8594
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64
             
  Name:      quay.io/olmqe/learn-operator:v2@sha256:4fe99a30425af03732720199f9b4b2ad444dadc316277f6da08907bb7216a75f
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64
             
  Name:      quay.io/olmqe/learn-operator:v2@sha256:66c107a6099e2e7ccac76d205f73626c6ccb843240699058e6b2c274b235044f
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/ppc64le
             
  Name:      quay.io/olmqe/learn-operator:v2@sha256:3a203afab2de2506e591743875de0d0857b01224e51ad65c5a903d1338f6b04a
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/s390x
  ```

  ### Build the operator bundle image
  1. Generate the `bundle.Dockerfile` via `opm`, as follows,
  ```yaml
  mac:learn-operator jianzhang$ opm alpha bundle build -c alpha -e alpha -d ./manifests/learn/0.0.1/ -p learn -t quay.io/olmqe/learn-operator-bundle:v0.0.1 --overwrite
  ...
  ```
  2. Create the **multi-arch** image based on this generated `bundle.Dockerfile`.
  ```yaml
  mac:learn-operator jianzhang$ docker buildx build -f bundle.Dockerfile --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t quay.io/olmqe/learn-operator-bundle:v0.0.1 --push --no-cache .
  [+] Building 18.0s (8/13)     
  ...
  ...
   => => pushing manifest for quay.io/olmqe/learn-operator-bundle:v0.0.1@sha256:796b10c65b93b35e1bd1f972eeac131e2c298df83973aeacfba9c54746  6.3s
   => [auth] olmqe/learn-operator-bundle:pull,push token for quay.io 
  ```
  If you need to create multi bundle images, you can repeat above steps 1, 2. For example, create `v0.0.2` version.
  ```yaml
  mac:learn-operator jianzhang$ opm alpha bundle build -c alpha -e alpha -d ./manifests/learn/0.0.2/ -p learn -t quay.io/olmqe/learn-operator-bundle:v0.0.2 --overwrite
  INFO[0000] Building annotations.yaml  
  ...
  ```
  ```yaml
  mac:learn-operator jianzhang$ docker buildx build -f bundle.Dockerfile --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t quay.io/olmqe/learn-operator-bundle:v0.0.2 --push --no-cache .
  [+] Building 12.8s (7/12)  
  ...
  ```
  create `v0.0.3` version
  ```yaml
  mac:learn-operator jianzhang$ opm alpha bundle build -c beta -e beta -d ./manifests/learn/0.0.3/ -p learn -t quay.io/olmqe/learn-operator-bundle:v0.0.3 --overwrite
  INFO[0000] Building annotations.yaml                    
  ...                    
  ```
  ```yaml
  mac:learn-operator jianzhang$ docker buildx build -f bundle.Dockerfile --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t quay.io/olmqe/learn-operator-bundle:v0.0.3 --push --no-cache .
  [+] Building 13.2s (7/12)                                                                                                                      
  => [internal] load build definition from bundle.Dockerfile   
  ...
  ``` 
  ### Build the operator index image
  1. Generate the `index.Dockerfile` only.
  ```yaml
  mac:learn-operator jianzhang$ opm index add -b quay.io/olmqe/learn-operator-bundle:v0.0.1 -t quay.io/olmqe/learn-operator-index:v1 --generate   
  WARN[0000] DEPRECATION NOTICE:
  ...
  ```
  2. Create a multi-arch image based on this `index.Dockerfile`.
  ```yaml
  mac:learn-operator jianzhang$ docker buildx build -f index.Dockerfile --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t quay.io/olmqe/learn-operator-index:v1 --push --no-cache .
  ...
  ```
  If you want to add more bundles into an index image, just do:
  ```yaml
  mac:learn-operator jianzhang$ opm index add -b quay.io/olmqe/learn-operator-bundle:v0.0.2,quay.io/olmqe/learn-operator-bundle:v0.0.3 -f quay.io/olmqe/learn-operator-index:v1 -t quay.io/olmqe/learn-operator-index:v1 --generate 
  ...
  INFO[0364] writing dockerfile: index.Dockerfile          bundles="[quay.io/olmqe/learn-operator-bundle:v0.0.2]"
  ```
  ```yaml
  mac:learn-operator jianzhang$ docker buildx build -f index.Dockerfile --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x -t quay.io/olmqe/learn-operator-index:v1 --push --no-cache .
  ...
   => => pushing manifest for quay.io/olmqe/learn-operator-index:v1@sha256:bd7c7fae846c3efbd02c0e91c51f316029a08dadd6f72a1397ba98f1ba97f01  7.9s
   => [auth] olmqe/learn-operator-index:pull,push token for quay.io 
  ```




