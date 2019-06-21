package io.confluent.devx.util.thesongis;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.header.Headers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class GuessProcessor {

    private static final String INPUTS = "INPUTS";
    private static final String GUESSES = "GUESSES";

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @KafkaListener(topics = INPUTS)
    public void consume(ConsumerRecord record) {

        Headers headers = record.headers();
        String json = record.value().toString();
        JsonParser parser = new JsonParser();
        JsonElement ele = parser.parse(json);
        JsonObject root = ele.getAsJsonObject();
        JsonObject guess = root.get("guess").getAsJsonObject();

        String modifiedGuess = createValueWithGuess(guess);

        if (modifiedGuess != null) {

            kafkaTemplate.send(
                new ProducerRecord<String, String>(
                    GUESSES, null, null, modifiedGuess, headers));

        }

    }

    private String createValueWithGuess(JsonObject guess) {

        JsonObject root = new JsonObject();
        root.addProperty("guess", guess.get("song").getAsString());
        root.addProperty("user", guess.get("user").getAsString());

        return root.toString();

    }

}