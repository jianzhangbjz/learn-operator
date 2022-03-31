FROM golang:1.17 as build
COPY . /app/
WORKDIR /app
RUN go build -mod=vendor -o "/app/build/bin/learn-operator" "/app/cmd/manager/main.go"

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
COPY --from=build  /app/build/bin /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/learn-operator"]
