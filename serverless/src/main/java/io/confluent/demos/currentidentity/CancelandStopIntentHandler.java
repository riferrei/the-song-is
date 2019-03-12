package io.confluent.demos.currentidentity;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.Response;
import static com.amazon.ask.request.Predicates.intentName;

import java.util.Optional;

public class CancelandStopIntentHandler implements RequestHandler {

    @Override
    public boolean canHandle(HandlerInput input) {

        return input.matches(intentName("AMAZON.StopIntent")
            .or(intentName("AMAZON.CancelIntent")));

    }

    @Override
    public Optional<Response> handle(HandlerInput input) {

        return input.getResponseBuilder()
            .withSpeech("Goodbye")
            .withSimpleCard("CurrentIdentity", "Goodbye")
            .build();

    }

}