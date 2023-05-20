# gcosts CLI program

## Library

* [Cobra](https://github.com/spf13/cobra)
* [PTerm](https://github.com/pterm/pterm)
* [yaml.v3](https://gopkg.in/yaml.v3)

## Run

```bash
go run main.go
```

## Format

Please run:

```bash
gofmt -w -s *.go
```

## Lint

Please use `golangci-lint`. It is a Go linters aggregator.

* Install: <https://golangci-lint.run/usage/install/>
    * Linux:
        ```bash
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin
        ```
    * macOS:
        ```bash
        brew install golangci-lint
        ```

Run:
```bash
golangci-lint run
```

## Compile

Compile the packages for Linux, macOS and Windows:
```bash
make
```