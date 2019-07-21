#!/bin/bash

go build -ldflags="-s -w" -o bin/winner src/winner/main.go
go build -ldflags="-s -w" -o bin/deletekeys src/deletekeys/main.go
sls deploy --verbose
