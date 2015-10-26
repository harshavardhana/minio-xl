all: install

checkdeps:
	@echo "Checking deps:"
	@(env bash $(PWD)/buildscripts/checkdeps.sh)

checkgopath:
	@echo "Checking if project is at ${GOPATH}"
	@for miniopath in $(echo ${GOPATH} | sed 's/:/\n/g'); do if [ ! -d ${miniopath}/src/github.com/minio/minio ]; then echo "Project not found in ${miniopath}, please follow instructions provided at https://github.com/minio/minio-xl/blob/master/CONTRIBUTING.md#setup-your-minio-github-repository" && exit 1; fi done

getdeps: checkdeps checkgopath
	@go get github.com/golang/lint/golint && echo "Installed golint:"
	@go get golang.org/x/tools/cmd/vet && echo "Installed vet:"
	@go get github.com/fzipp/gocyclo && echo "Installed gocyclo:"

verifiers: getdeps vet fmt lint cyclo

vet:
	@echo "Running $@:"
	@GO15VENDOREXPERIMENT=1 go tool vet -all *.go
	@GO15VENDOREXPERIMENT=1 go tool vet -all ./pkg
	@GO15VENDOREXPERIMENT=1 go tool vet -shadow=true *.go
	@GO15VENDOREXPERIMENT=1 go tool vet -shadow=true ./pkg

fmt:
	@echo "Running $@:"
	@GO15VENDOREXPERIMENT=1 gofmt -s -l *.go
	@GO15VENDOREXPERIMENT=1 gofmt -s -l pkg

lint:
	@echo "Running $@:"
	@GO15VENDOREXPERIMENT=1 golint *.go
	@GO15VENDOREXPERIMENT=1 golint github.com/minio/minio-xl/pkg...

cyclo:
	@echo "Running $@:"
	@GO15VENDOREXPERIMENT=1 gocyclo -over 25 *.go
	@GO15VENDOREXPERIMENT=1 gocyclo -over 25 pkg

build: config getdeps verifiers
	@echo "Installing minio:"
	@GO15VENDOREXPERIMENT=1 go generate ./...

test: build
	@echo "Running all testing:"
	@GO15VENDOREXPERIMENT=1 go test $(GOFLAGS) .
	@GO15VENDOREXPERIMENT=1 go test $(GOFLAGS) github.com/minio/minio-xl/pkg...

gomake-all: build
	@GO15VENDOREXPERIMENT=1 go install github.com/minio/minio-xl

install: gomake-all

config:
	@echo "Generating new config.go"
	@GO15VENDOREXPERIMENT=1 go run buildscripts/config-gen.go

pkg-add:
	@GO15VENDOREXPERIMENT=1 govendor add $(PKG)

pkg-update:
	@GO15VENDOREXPERIMENT=1 govendor update $(PKG)

pkg-remove:
	@GO15VENDOREXPERIMENT=1 govendor remove $(PKG)

clean:
	@echo "Cleaning up all the generated files:"
	@rm -fv config.go
	@rm -fv cover.out
	@rm -fv minio
	@rm -fv pkg/erasure/*.syso
