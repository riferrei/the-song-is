package io.confluent.demos.thesongis;

import com.amazon.ask.dispatcher.request.handler.HandlerInput;
import com.amazon.ask.dispatcher.request.handler.RequestHandler;
import com.amazon.ask.model.Response;
import com.amazon.ask.request.Predicates;

import redis.clients.jedis.Jedis;
import java.util.Optional;

public class DeleteKeysIntentHandler implements RequestHandler {

    private static final String REDIS_HOST = System.getenv("REDIS_HOST");
    private static final String REDIS_PORT = System.getenv("REDIS_PORT");

    @Override
    public boolean canHandle(HandlerInput input) {
       return input.matches(Predicates.intentName("DeleteKeysIntent"));
    }

    @Override
    public Optional<Response> handle(HandlerInput input) {
        deleteKeys();
        return input.getResponseBuilder()
            .withSpeech("OK... all winners are gone. Ready to play.")
            .build();
    }

    private static void deleteKeys() {
        if (!jedis.isConnected()) {
            jedis.connect();
        }
        jedis.flushAll();

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