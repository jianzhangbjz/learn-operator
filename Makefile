all: build clean
.PHONY: all build clean
OUT_DIR=build/_output/bin/

build:
	mkdir -p "${OUT_DIR}"
	export GO111MODULE=on && export GOPROXY=https://goproxy.io && go build -o "${OUT_DIR}/learn-operator" "./cmd/manager/main.go"

clean:
	$(RM) ./bin/learn-operator
.PHONY: clean
