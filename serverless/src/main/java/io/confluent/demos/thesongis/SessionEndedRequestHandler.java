package io.confluent.demos.thesongis;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.Response;
import com.amazon.ask.model.SessionEndedRequest;
import static com.amazon.ask.request.Predicates.requestType;

import java.util.Optional;

public class SessionEndedRequestHandler implements RequestHandler {

    @Override
    public boolean canHandle(HandlerInput input) {

        return input.matches(requestType(SessionEndedRequest.class));

    }

    @Override
    public Optional<Response> handle(HandlerInput input) {

        return input.getResponseBuilder().build();

    }

}