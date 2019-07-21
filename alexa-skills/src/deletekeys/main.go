package main

import (
	"context"
	"fmt"
	"os"
	"shared"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/gomodule/redigo/redis"
)

var redisConn redis.Conn

// HandleRequest is the entry point for the Alexa skill
func HandleRequest(ctx context.Context, alexaReq shared.AlexaRequest) (shared.AlexaResponse, error) {
	alexaRes := shared.AlexaResponse{Version: "1.0"}
	alexaRes.Response.OutputSpeech.Type = "PlainText"
	switch alexaReq.Request.Intent.Name {
	case "DeleteKeysIntent":
		redisConn.Do("FLUSHALL")
		alexaRes.Say("OK... all winners are gone. Ready to play.")
	case "AMAZON.HelpIntent":
		alexaRes.Say("To use this skill, just say: 'tell the demo to remove all winners.'.")
	default:
		alexaRes.Say("I'm sorry, but I was not able to understand this command.")
	}
	return alexaRes, nil
}

func main() {
	redisHost := os.Getenv("REDIS_HOST")
	redisPort := os.Getenv("REDIS_PORT")
	url := "redis://" + redisHost + ":" + redisPort
	conn, err := redis.DialURL(url)
	if err == nil {
		redisConn = conn
		defer redisConn.Close()
	} else {
		panic(fmt.Errorf("Error while connecting to Redis: %s", err))
	}
	lambda.Start(HandleRequest)
}
