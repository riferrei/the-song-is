#!/bin/bash

rm -rf deploy
mkdir -p deploy
mkdir -p bin

mvn clean
mvn compile
mvn package
mv target/guess-1.0.jar deploy/guess-1.0.jar

GOOS=linux go build -ldflags="-s -w" -o bin/winner src/winner/main.go
zip deploy/winner.zip bin/winner

GOOS=linux go build -ldflags='-s -w' -o bin/deletekeys src/deletekeys/main.go
zip deploy/deletekeys.zip bin/deletekeys

rm -rf bin
