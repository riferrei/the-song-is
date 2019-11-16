package shared

import "time"

// GuessEvent represents the user guess
type GuessEvent struct {
	Guess string `json:"guess"`
	User  string `json:"user"`
}

// GuessResponse is the reply back
type GuessResponse struct {
	Message string `json:"message"`
}

// AlexaRequest represents the Alexa request
type AlexaRequest struct {
	Version string `json:"version"`
	Request struct {
		Type   string `json:"type"`
		Time   string `json:"timestamp"`
		Intent struct {
			Name               string `json:"name"`
			ConfirmationStatus string `json:"confirmationstatus"`
		} `json:"intent"`
	} `json:"request"`
}

// AlexaResponse represents the Alexa response
type AlexaResponse struct {
	Version  string `json:"version"`
	Response struct {
		OutputSpeech struct {
			Type string `json:"type"`
			Text string `json:"text"`
		} `json:"outputSpeech"`
	} `json:"response"`
}

// Say is a utility function to set what
// Alexa will reply back to the user
func (alexaRes *AlexaResponse) Say(message string) {
	alexaRes.Response.OutputSpeech.Text = message
}

// SortableTime allows time to
// be sorted, from the oldest
// to the newst element.
type SortableTime []time.Time

func (st SortableTime) Len() int {
	return len(st)
}

func (st SortableTime) Less(i, j int) bool {
	return st[i].Before(st[j])
}

func (st SortableTime) Swap(i, j int) {
	st[i], st[j] = st[j], st[i]
}
