.DEFAULT_GOAL := run

GOVERSION= $(shell go version | awk '{print $$3}')

run:
	go run main.go

build:
	goreleaser check
	GOVERSION=$(GOVERSION) goreleaser build \
		--snapshot --clean --skip=validate

