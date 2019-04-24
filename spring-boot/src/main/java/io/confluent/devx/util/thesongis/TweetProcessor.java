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

import io.opentracing.contrib.kafka.TracingKafkaUtils;
import io.opentracing.util.GlobalTracer;

@Service
public class TweetProcessor {

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

        String songGuess = root.get("songGuess").getAsString();
        String userName = root.get("userName").getAsString();
        String value = createValueWithGuess(songGuess, userName);

        sendGuess(headers, value);

    }

    private void sendGuess(Headers headers, String value) {

        if (value != null) {

            ProducerRecord<String, String> record =
                new ProducerRecord<String, String>(GUESSES,
                    null, null, value, headers);

            TracingKafkaUtils.buildAndInjectSpan(record, GlobalTracer.get());
            kafkaTemplate.send(record);

        }

    }

    private String createValueWithGuess(String songGuess, String userName) {

        JsonObject root = new JsonObject();
        root.addProperty("guess", songGuess);
        root.addProperty("user", userName);

        return root.toString();

    }

}