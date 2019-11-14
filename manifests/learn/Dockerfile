FROM scratch

LABEL operators.operatorframework.io.bundle.mediatype.v1=plain
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=learn-operator
LABEL operators.operatorframework.io.bundle.channels.v1=alpha
LABEL operators.operatorframework.io.bundle.channel.default.v1=alpha

ADD /Users/jianzhang/goproject/src/github.com/example-inc/learn-operator/manifests/learn/*.yaml /manifests/
ADD /Users/jianzhang/goproject/src/github.com/example-inc/learn-operator/manifests/learn/metadata/annotations.yaml /metadata/annotations.yaml
