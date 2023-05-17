#!/usr/bin/env bash

# Native
echo "Native" && \
go build -ldflags="-s -w" -o gcosts main.go && \

# Linux
echo "Linux" && \
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o gcosts-linux-x86_64 main.go && \
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o gcosts-linux-arm64  main.go && \

# macOS
echo "macOS" && \
GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o gcosts-macos-x86_64 main.go && \
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o gcosts-macos-arm64  main.go && \

# Windows
echo "Windows" && \
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o gcosts-windows-x86_64.exe main.go && \
GOOS=windows GOARCH=arm64 go build -ldflags="-s -w" -o gcosts-windows-arm64.exe  main.go && \

echo "✅ DONE"
