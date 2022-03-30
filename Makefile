all: build clean deploy_operator deploy_cr
.PHONY: all build clean deploy_operator deploy_cr
OUT_DIR=build/_output/bin

build:
	mkdir -p "${OUT_DIR}"
	export GO111MODULE=on && export GOPROXY=https://goproxy.io && go env && go mod tidy && go build -mod=mod -o "${OUT_DIR}/learn-operator" "./cmd/manager/main.go"
	mkdir -p "/tmp" && cp "${OUT_DIR}/learn-operator" "/tmp/learn-operator" && cp -r "build/bin" "/tmp/bin"

deploy_operator:
	./hack/deploy_operator.sh

deploy_cr:
	./hack/deploy_cr.sh

clean:
	$(RM) ./bin/learn-operator
.PHONY: clean
