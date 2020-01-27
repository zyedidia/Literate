build:
	go build -ldflags "-s -w" ./cmd/lit

install:
	go install -ldflags "-s -w" ./cmd/lit
