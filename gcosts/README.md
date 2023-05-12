# gcosts CLI program

## Library

* [Cobra](https://github.com/spf13/cobra)
* [PTerm](https://github.com/pterm/pterm)
* [yaml.v3](https://gopkg.in/yaml.v3)

## Run

```bash
go run main.go
```

## Compile

Compile the packages for Linux, macOS and Windows:
```bash
bash build.sh
```

## Lint

Please use `golangci-lint`. It is a Go linters aggregator.

Install: <https://golangci-lint.run/usage/install/>

```bash
golangci-lint run
```