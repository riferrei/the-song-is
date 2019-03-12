package io.confluent.demos.currentidentity;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.Response;

import java.util.Optional;

import static com.amazon.ask.request.Predicates.intentName;

public class FallbackIntentHandler implements RequestHandler {

    @Override
    public boolean canHandle(HandlerInput input) {

        return input.matches(intentName("AMAZON.FallbackIntent"));
        
    }

    @Override
    public Optional<Response> handle(HandlerInput input) {

        String speechText = "Sorry, I didn't catch that one. Could you be more specific?";

        return input.getResponseBuilder()
                .withSpeech(speechText)
                .withSimpleCard("CurrentIdentity", speechText)
                .withReprompt(speechText)
                .build();
    }

}