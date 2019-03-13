package io.confluent.devx.util.thesongis;

import java.util.HashMap;
import java.util.Map;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.stereotype.Service;

import io.confluent.devx.util.JaegerTracingConsumerInterceptor;
import io.confluent.devx.util.JaegerTracingProducerInterceptor;
import io.confluent.devx.util.JaegerTracingUtils;
import io.confluent.kafka.serializers.KafkaAvroDeserializer;

@Service
public class TweetProcessor {

    private static final String TWEETS = "TWEETS";
    private static final String GUESSES = "GUESSES";

    @Value("${BOOTSTRAP_SERVERS}")
    private String bootstrapServers;

    @Value("${ACCESS_KEY}")
    private String accessKey;

    @Value("${ACCESS_SECRET}")
    private String accessSecret;

    @Value("${SCHEMA_REGISTRY_URL}")
    private String schemaRegistryUrl;

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

    @Bean
    public ConsumerFactory<String, String> consumerFactory() {

        Map<String, Object> config = new HashMap<String, Object>();

        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class.getName());
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "SpringBoot");
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, JaegerTracingConsumerInterceptor.class.getName());
        config.put(JaegerTracingUtils.CONFIG_FILE_PROP, "/etc/the-song-is/interceptorsConfig.json");
        config.put("schema.registry.url", schemaRegistryUrl);
        config.put("ssl.endpoint.identification.algorithm", "https");
        config.put("sasl.mechanism", "PLAIN");
        config.put("security.protocol", "SASL_SSL");
        config.put("sasl.jaas.config", getJaaSConfig());

        return new DefaultKafkaConsumerFactory<>(config);

    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory() {
    
        ConcurrentKafkaListenerContainerFactory<String, String> factory
            = new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());

        return factory;

    }

    private void sendGuess(String value) {

        if (value != null) {

            if (producer == null) {

                producer = createProducer();

            }

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

    private KafkaProducer<String, String> createProducer() {

        Map<String, Object> config = new HashMap<String, Object>();

        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, JaegerTracingProducerInterceptor.class.getName());
        config.put(JaegerTracingUtils.CONFIG_FILE_PROP, "/etc/the-song-is/interceptorsConfig.json");
        config.put("ssl.endpoint.identification.algorithm", "https");
        config.put("sasl.mechanism", "PLAIN");
        config.put("security.protocol", "SASL_SSL");
        config.put("sasl.jaas.config", getJaaSConfig());

        return new KafkaProducer<String, String>(config);
        
    }

    private String getJaaSConfig() {

        StringBuilder jaasConfig = new StringBuilder();
        jaasConfig.append("org.apache.kafka.common.security.plain.PlainLoginModule ");
        jaasConfig.append("required username=\"").append(accessKey).append("\" ");
        jaasConfig.append("password=\"").append(accessSecret).append("\"; ");

        return jaasConfig.toString();

    }

}