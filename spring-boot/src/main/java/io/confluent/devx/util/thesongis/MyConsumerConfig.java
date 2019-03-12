package io.confluent.devx.util.thesongis;

import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import io.confluent.kafka.serializers.KafkaAvroDeserializer;

@Configuration
public class MyConsumerConfig {

    @Value("${BOOTSTRAP_SERVERS}")
    private String bootstrapServers;

    @Value("${ACCESS_KEY}")
    private String accessKey;

    @Value("${ACCESS_SECRET}")
    private String accessSecret;

    @Value("${SCHEMA_REGISTRY_URL}")
    private String schemaRegistryUrl;

    @Bean
    public ConsumerFactory<String, String> consumerFactory() {

        Map<String, Object> config = new HashMap<String, Object>();

        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class.getName());
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "SpringBoot");
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put("schema.registry.url", schemaRegistryUrl);
        config.put("ssl.endpoint.identification.algorithm", "https");
        config.put("sasl.mechanism", "PLAIN");
        config.put("security.protocol", "SASL_SSL");
        config.put("sasl.jaas.config", getJaaSConfig());

        return new DefaultKafkaConsumerFactory<>(config);
        
    }

    private String getJaaSConfig() {

        StringBuilder jaasConfig = new StringBuilder();
        jaasConfig.append("org.apache.kafka.common.security.plain.PlainLoginModule ");
        jaasConfig.append("required username=\"").append(accessKey).append("\" ");
        jaasConfig.append("password=\"").append(accessSecret).append("\"; ");

        return jaasConfig.toString();

    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory() {
    
        ConcurrentKafkaListenerContainerFactory<String, String> factory
            = new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());

        return factory;

    }    

}