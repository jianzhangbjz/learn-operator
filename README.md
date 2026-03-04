## Background

Since OCP 4.22, the image `quay.io/olmqe/etcd-index:33450-fips` crashes on FIPS-enabled clusters. This branch builds `learn-operator` as a replacement to address the following issue:

```
I0225 04:10:53.820362 36963 helper.go:182] $oc get [pods -n e2e-test-default-h9hf7], the returned resource:
NAME                             READY   STATUS             RESTARTS        AGE
etcd-operator-6599dc6c5f-47fvh   2/3     CrashLoopBackOff   5 (2m23s ago)   5m34s
```

For more details, see:
- Jira: https://issues.redhat.com/browse/OCPQE-31615
- Slack: https://redhat-internal.slack.com/archives/C06KP34REFJ/p1772079055034849

## Description

OCP-33450 is a special test case that requires adding an invalid OpenAPI schema to `learn-operator v0.0.3`, causing the CSV to fail during installation.

## Steps

### 1. Add an invalid OpenAPI schema to learn-operator v0.0.3

Update `manifests/learn/0.0.3/learn.crd.yaml`:

```yaml
spec:
  type: object
  x-kubernetes-preserve-unknown-fields: true
  properties:
    invalidField:
      type: invalidType
      minimum: "not-a-number"
status:
  type: object
  x-kubernetes-preserve-unknown-fields: true
```

### 2. Build a multi-arch bundle image using `opm`

Generate `bundle.Dockerfile`:

```bash
opm alpha bundle build -c alpha -e alpha \
  -d ./manifests/learn/0.0.3/ \
  -p learn \
  -b podman \
  -t quay.io/olmqe/learn-operator-bundle:v33450 \
  --overwrite \
  --base-image registry.access.redhat.com/ubi8/ubi-minimal:latest
```

Build the multi-arch bundle image:

```bash
podman build \
  --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x \
  --manifest quay.io/olmqe/learn-operator-bundle:v0.0.3-33450 \
  . -f bundle.Dockerfile
```

Push the bundle image:

```bash
podman manifest push quay.io/olmqe/learn-operator-bundle:v0.0.3-33450
```

### 3. Build a multi-arch index image

Use `opm migrate` to generate an index JSON file:

```console
$ opm migrate quay.io/olmqe/learn-operator-index:v25 catalog/
INFO[0000] rendering index "quay.io/olmqe/learn-operator-index:v25" as file-based catalog
INFO[0042] wrote rendered file-based catalog to "catalog/"

$ tree catalog/
catalog/
├── learn
│   └── catalog.json
└── sample-operator
    └── catalog.json
```

### 4. Modify the catalog JSON

Since OLMv0 **does not support automatic operator upgrades across channels**, modify `catalog/learn/catalog.json`:
- Replace `beta` with `alpha`
- Remove duplicate channels

Original channel configuration:

```console
$ opm alpha list channels quay.io/olmqe/learn-operator-index:v25
PACKAGE          CHANNEL  HEAD
learn            alpha    learn-operator.v0.0.2
learn            beta     learn-operator.v0.0.3
sample-operator  alpha    sample-operator.v0.0.1
```

Validate the JSON file:

```console
$ opm validate catalog
FATA[0000] package "learn" has duplicate channel "alpha"
```

### 5. Build and push the multi-arch index image

```bash
podman build \
  --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x \
  --manifest quay.io/olmqe/learn-operator-index:v25-33450 \
  . -f catalog.Dockerfile

podman manifest push quay.io/olmqe/learn-operator-index:v25-33450
```

Verify the multi-arch image:

```console
$ oc image info quay.io/olmqe/learn-operator-index:v25-33450
error: the image is a manifest list and contains multiple images - use --filter-by-os to select from:

  OS            DIGEST
  linux/arm64   sha256:3cea222036f146730d4eb54ebe9bb5d44c34dc556ad720b7dedcef89bb977ac7
  linux/amd64   sha256:5514473d6d0db19f94e00973be824c15195102fc9be7cc9151811cba3388ed8b
  linux/s390x   sha256:c6c232c72740284f3eb5e980ef4d91ab26ee1acc6b7a798bf79b448f42196d7b
  linux/ppc64le sha256:4cf00ff52ddf3a85bf4abaf32412038bdd44d02dba5c5f71ca616363b251f3ea

$ opm alpha list channels quay.io/olmqe/learn-operator-index:v25-33450
PACKAGE          CHANNEL  HEAD
learn            alpha    learn-operator.v0.0.3
sample-operator  alpha    sample-operator.v0.0.1
```
