#!/bin/bash

rm -rf deploy
mkdir -p deploy
mkdir -p bin

GOOS=linux go build -ldflags="-s -w" -o bin/winner src/winner/main.go
zip deploy/winner.zip bin/winner

GOOS=linux go build -ldflags='-s -w' -o bin/deletekeys src/deletekeys/main.go
zip deploy/deletekeys.zip bin/deletekeys

rm -rf bin
