### Background
Since OCP 4.22, the image `quay.io/olmqe/etcd-index:upgrade-fips` crashes on FIPS-enabled clusters. This branch builds learn-operator as a replacement to address the following issue:
```go
I0224 06:10:40.865139 18921 helper.go:182] $oc get [pods -n e2e-test-default-bmvjr], the returned resource:
NAME                                                              READY   STATUS             RESTARTS        AGE
4c2751e06cfee1334210e29dd8e63541fed8c640915ec9e43ba52ad9bcbbh4r   0/1     Completed          0               6m10s
9b63e17ede664f0c63f58facb12bb59eadd0765dcb7d57a97a038f9f9e2wnhl   0/1     Completed          0               5m11s
cs-43101-qndcl                                                    1/1     Running            0               7m12s
etcd-operator-5644d6896d-f2d7h                                    2/3     CrashLoopBackOff   5 (2m37s ago)   5m33s 
```

### Description
This new image `quay.io/olmqe/learn-operator-index:v25-43101` contains `learn-operator.v0.0.1/learn-operator.v0.0.2/learn-operator.v0.0.3` in the `beta` channel.
- The `learn-operator.v0.0.1` contains
```yaml
        {
            "type": "olm.maxOpenShiftVersion",
            "value": " "
        },
```
- The `learn-operator.v0.0.2` contains
```yaml
        {   
            "type": "olm.maxOpenShiftVersion",
            "value": "4.21"
        },
```
- The `learn-operator.v0.0.3` contains
```yaml
        {   
            "type": "olm.maxOpenShiftVersion",
            "value": "4.22.0"
        },
```

#### Steps
1. Generate the `catalog.json` file by using `opm migrate` command:
```console
jiazha-mac:learn jiazha$ opm migrate quay.io/olmqe/learn-operator-index:v25 catalog/
INFO[0000] rendering index "quay.io/olmqe/learn-operator-index:v25" as file-based catalog 
INFO[0020] wrote rendered file-based catalog to "catalog/"
jiazha-mac:learn jiazha$ tree catalog/
catalog/
├── learn
│   └── catalog.json
└── sample-operator
    └── catalog.json
```
2. Modify the `catalog.json` to add the property described in the `Description` section and validate it.
```console
jiazha-mac:learn-operator jiazha$ opm validate catalog
jiazha-mac:learn-operator jiazha$
```
3. Generate the `catalog.Dockerfile` by using the `opm generate` command:
```console
jiazha-mac:learn-operator jiazha$ opm generate dockerfile catalog -b registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19 -i registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19
jiazha-mac:learn-operator jiazha$ git status
On branch OCP-43101
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   catalog/learn/catalog.json
	new file:   catalog/sample-operator/catalog.json

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	catalog.Dockerfile
```
4. Build the multi-arch index image
```console
jiazha-mac:learn-operator jiazha$ podman build --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x  --manifest quay.io/olmqe/learn-operator-index:v25-43101 . -f catalog.Dockerfile
[linux/s390x] [1/2] STEP 1/3: FROM registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19 AS builder
Trying to pull registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.19...
Getting image source signatures
...
...
jiazha-mac:learn-operator jiazha$ podman manifest push quay.io/olmqe/learn-operator-index:v25-43101
Getting image list signatures
Copying 4 images generated from 4 images in list
Copying image sha256:30e6916fc8df8c9083762b8cfedcd715f84fbd672185cad51def7bb05cb14641 (1/4)
Getting image source signatures
...
```
