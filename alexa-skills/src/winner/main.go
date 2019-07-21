package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"shared"
	"sort"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/gomodule/redigo/redis"
)

var redisConn redis.Conn

// HandleRequest is the entry point for the Alexa skill
func HandleRequest(ctx context.Context, alexaReq shared.AlexaRequest) (shared.AlexaResponse, error) {
	alexaRes := shared.AlexaResponse{Version: "1.0"}
	alexaRes.Response.OutputSpeech.Type = "PlainText"
	switch alexaReq.Request.Intent.Name {
	case "WinnerIntent":
		winner := selectWinner()
		if len(winner) > 0 {
			alexaRes.Say(fmt.Sprintf("The winner is %s. Congratulations!", winner))
		} else {
			alexaRes.Say("There are no winners at this time!")
		}
	case "AMAZON.HelpIntent":
		alexaRes.Say("To use this skill, just say: 'tell me who is the winner'.")
	default:
		alexaRes.Say("I'm sorry, but I was not able to understand this command.")
	}
	return alexaRes, nil
}

func selectWinner() string {
	var winner string
	keys, err := redis.Strings(redisConn.Do("KEYS", "*"))
	if err == nil && len(keys) > 0 {
		keyMapping := make(map[time.Time]string)
		candidates := make([]time.Time, 0, len(keys))
		for _, key := range keys {
			timestamp, _ := strconv.ParseInt(key, 10, 64)
			if timestamp > 0 {
				t := time.Unix(timestamp/1000, 0)
				candidates = append(candidates, t)
				keyMapping[t] = key
			}
		}
		sort.Sort(shared.SortableTime(candidates))
		selected := keyMapping[candidates[0]]
		userJSON, err := redis.String(redisConn.Do("GET", selected))
		if err == nil && len(userJSON) > 0 {
			var user struct {
				User string `json:"USER"`
			}
			json.Unmarshal([]byte(userJSON), &user)
			winner = user.User
		}
	}
	return winner
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
