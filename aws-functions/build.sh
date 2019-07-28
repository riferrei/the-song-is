#!/bin/bash

GOOS=linux go build -ldflags="-s -w" -o bin/winner src/winner/main.go
GOOS=linux go build -ldflags='-s -w' -o bin/deletekeys src/deletekeys/main.go
