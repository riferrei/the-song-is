package io.confluent.demos.currentidentity;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.LaunchRequest;
import com.amazon.ask.model.Response;
import com.amazon.ask.request.Predicates;

import java.util.Optional;

public class LaunchRequestHandler implements RequestHandler {

    @Override
    public boolean canHandle(HandlerInput input) {

        return input.matches(Predicates.requestType(LaunchRequest.class));

    }

    @Override
    public Optional<Response> handle(HandlerInput input) {

        String speechText = "Welcome to the current identity skill. You can ask me for heroes identities but please... <amazon:effect name=\"whispered\">keep down OK?</amazon:effect>";

        return input.getResponseBuilder()
            .withSpeech(speechText)
            .withSimpleCard("CurrentIdentity", speechText)
            .build();

    }

}