package io.confluent.demos.currentidentity;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.Intent;
import com.amazon.ask.model.IntentRequest;
import com.amazon.ask.model.Request;
import com.amazon.ask.model.Response;
import com.amazon.ask.model.Slot;
import com.amazon.ask.request.Predicates;

import redis.clients.jedis.Jedis;

import java.util.Map;
import java.util.Optional;

public class CurrentIdentityIntentHandler implements RequestHandler {

    private static final String HERO_NAME_SLOT = "heroName";
    private static final String REDIS_HOST = System.getenv("REDIS_HOST");
    private static final String REDIS_PORT = System.getenv("REDIS_PORT");

    @Override
    public boolean canHandle(HandlerInput input) {

       return input.matches(Predicates.intentName("CurrentIdentityIntent"));
       
    }

    @Override
    public Optional<Response> handle(HandlerInput input) {

        Request request = input.getRequestEnvelope().getRequest();
        IntentRequest intentRequest = (IntentRequest) request;
        Intent intent = intentRequest.getIntent();
        Map<String, Slot> slots = intent.getSlots();

        Slot heroNameSlot = slots.get(HERO_NAME_SLOT);
        String heroName = heroNameSlot.getValue();
        heroName = heroName.toUpperCase();

        String currentIdentity = getCurrentIdentity(heroName);
        String speechText = getSpeechText(heroName, currentIdentity);

        return input.getResponseBuilder()
            .withSpeech(speechText)
            .build();

    }

    private static String getCurrentIdentity(String heroName) {

        if (!jedis.isConnected()) {

            jedis.connect();

        }

        String currentIdentity = null;

        if (jedis.exists(heroName)) {

            currentIdentity = jedis.get(heroName);

            if (currentIdentity != null) {

                currentIdentity = currentIdentity.trim();

            }

        }

        return currentIdentity;

    }

    private static String getSpeechText(String heroName, String currentIdentity) {

        final StringBuilder speechText = new StringBuilder();

        if (currentIdentity != null) {

            speechText.append(heroName);
            speechText.append("'s current identity is ");
            speechText.append(currentIdentity);

            return speechText.toString();

        } else {

            speechText.append("I could not find ");
            speechText.append(heroName);
            speechText.append("'s current identity. ");
            speechText.append("<amazon:effect name=\"whispered\">Sorry...</amazon:effect>");

            return speechText.toString();

        }

    }

    private static Jedis jedis;

    static {

        jedis = new Jedis(REDIS_HOST, Integer.parseInt(REDIS_PORT));

        Runtime.getRuntime().addShutdownHook(new Thread() {

            public void run() {

                if (jedis != null) {

                    jedis.disconnect();
                    jedis.close();

                }

            }

        });

    }

}