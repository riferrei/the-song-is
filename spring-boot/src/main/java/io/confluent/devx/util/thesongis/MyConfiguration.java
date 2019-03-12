package io.confluent.devx.util.thesongis;

import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

import io.confluent.kafka.serializers.KafkaAvroDeserializer;
import io.jaegertracing.Configuration.ReporterConfiguration;
import io.jaegertracing.Configuration.SamplerConfiguration;
import io.opentracing.Tracer;
import io.opentracing.contrib.kafka.spring.TracingConsumerFactory;
import io.opentracing.contrib.kafka.spring.TracingProducerFactory;

@Configuration
public class MyConfiguration {

    @Value("${BOOTSTRAP_SERVERS}")
    private String bootstrapServers;

    @Value("${ACCESS_KEY}")
    private String accessKey;

    @Value("${ACCESS_SECRET}")
    private String accessSecret;

    @Value("${SCHEMA_REGISTRY_URL}")
    private String schemaRegistryUrl;

    @Bean
    public Tracer tracer() {

        return new io.jaegertracing.Configuration("Spring Boot")
            .withSampler(SamplerConfiguration.fromEnv())
            .withReporter(ReporterConfiguration.fromEnv())
            .getTracer();

    }

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

        return new TracingConsumerFactory<>(new DefaultKafkaConsumerFactory<>(config), tracer());

    }

    @Bean
    public ProducerFactory<String, String> producerFactory() {

        Map<String, Object> config = new HashMap<String, Object>();

        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put("ssl.endpoint.identification.algorithm", "https");
        config.put("sasl.mechanism", "PLAIN");
        config.put("security.protocol", "SASL_SSL");
        config.put("sasl.jaas.config", getJaaSConfig());

        return new TracingProducerFactory<>(new DefaultKafkaProducerFactory<>(config), tracer());
        
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

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {

        return new KafkaTemplate<>(producerFactory());

    }

}