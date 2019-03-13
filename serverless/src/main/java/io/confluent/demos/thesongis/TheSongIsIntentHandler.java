package io.confluent.demos.thesongis;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.Response;
import com.amazon.ask.request.Predicates;

import redis.clients.jedis.Jedis;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public class TheSongIsIntentHandler implements RequestHandler {

    private static final String REDIS_HOST = System.getenv("REDIS_HOST");
    private static final String REDIS_PORT = System.getenv("REDIS_PORT");

    @Override
    public boolean canHandle(HandlerInput input) {

       return input.matches(Predicates.intentName("TheSongIsIntent"));
       
    }

    @Override
    public Optional<Response> handle(HandlerInput input) {

        String speechText = getSpeechText(selectWinner());

        return input.getResponseBuilder()
            .withSpeech(speechText)
            .build();

    }

    private static String selectWinner() {

        if (!jedis.isConnected()) {

            jedis.connect();

        }

        Set<String> keys = jedis.keys("*");

        if (keys == null || keys.isEmpty()) {

            return null;

        }

        List<Date> candidates = new ArrayList<Date>();

        for (String key : keys) {

            try {

                long tValue = Long.parseLong(key);
                candidates.add(new Date(tValue));

            } catch (NumberFormatException nfe) {}

        }

        Collections.sort(candidates);

        Date dSelected = candidates.get(0);
        long lSelected = dSelected.getTime();
        String selected = String.valueOf(lSelected);
        String winner = jedis.get(selected);

        if (winner != null) {

            winner = winner.trim();

        }

        return winner;

    }

    private static String getSpeechText(String winner) {

        final StringBuilder speechText = new StringBuilder();

        if (winner != null) {

            speechText.append("The winner is ");
            speechText.append(winner);

            return speechText.toString();

        } else {

            speechText.append("There are no winners at this time");
            
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