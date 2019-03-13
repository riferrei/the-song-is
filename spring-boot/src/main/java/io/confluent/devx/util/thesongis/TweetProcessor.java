package io.confluent.devx.util.thesongis;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class TweetProcessor {

    private static final String TWEETS = "TWEETS";
    private static final String GUESSES = "GUESSES";

    @Autowired
    private KafkaProducer<String, String> producer;

    @KafkaListener(topics = TWEETS)
    public void consume(ConsumerRecord record) {

        String json = record.value().toString();
        JsonParser parser = new JsonParser();
        JsonElement ele = parser.parse(json);
        JsonObject root = ele.getAsJsonObject();

        String text = root.get("Text").getAsString();
        JsonObject _user = root.get("User").getAsJsonObject();
        String user = _user.get("Name").getAsString();
        String value = createValueWithGuess(text, user);

        sendGuess(value);

    }

    private void sendGuess(String value) {

        if (value != null) {

            ProducerRecord<String, String> record =
                new ProducerRecord<String, String>(GUESSES, value);

            producer.send(record);

        }

    }

    private String createValueWithGuess(String text, String user) {

        int start = text.indexOf("[");
        int end = text.indexOf("]");

        if (start != -1 && end != -1) {

            String guess = text.substring(++start, end);
            JsonObject root = new JsonObject();
            root.addProperty("guess", guess);
            root.addProperty("user", user);

            return root.toString();

        }

        return null;

    }

}