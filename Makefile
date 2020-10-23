all: build clean deploy_operator deploy_cr
.PHONY: all build clean deploy_operator deploy_cr
OUT_DIR=build/_output/bin

build:
	mkdir -p "${OUT_DIR}"
	pwd
	export GO111MODULE=on && export GOPROXY=https://goproxy.io && go get ./... && go build -o "${OUT_DIR}/learn-operator" "./cmd/manager/main.go"

deploy_operator:
	./hack/deploy_operator.sh

deploy_cr:
	./hack/deploy_cr.sh

clean:
	$(RM) ./bin/learn-operator
.PHONY: clean
