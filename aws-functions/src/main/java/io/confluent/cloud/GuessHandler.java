package io.confluent.cloud;

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.serialization.StringSerializer;

public class GuessHandler implements RequestHandler<Map<String, Object>, Map<String, Object>> {

    public Map<String, Object> handleRequest(final Map<String, Object> request, final Context context) {

        final LambdaLogger logger = context.getLogger();
        logger.log("Request: " + request.getClass().getName());
        logger.log("Request: " + request);

        final Map<String, Object> response = new HashMap<String, Object>();
        response.put("statusCode", 200);
        Map<String, Object> headers = new HashMap<String, Object>();
        headers.put("Content-Type", "text/plain");
        headers.put("Access-Control-Allow-Origin", "*");
        response.put("headers", headers);

        if (request.containsKey(BODY_KEY)) {

            if (producer == null) {
                final Properties properties = new Properties();
                properties.setProperty("ssl.endpoint.identification.algorithm", "https");
                properties.setProperty("sasl.mechanism", "PLAIN");
                properties.setProperty("security.protocol", "SASL_SSL");
                properties.setProperty("sasl.jaas.config", getJaaSConfig());
                properties.setProperty(ProducerConfig.RETRY_BACKOFF_MS_CONFIG, "500");
                properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
                properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
                properties.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
                properties.setProperty(ProducerConfig.ACKS_CONFIG, "all");
                producer = new KafkaProducer<String, String>(properties);
            }

            final String body = (String) request.get(BODY_KEY);
            producer.send(new ProducerRecord<String, String>("GUESSES", body), new Callback() {
                public void onCompletion(final RecordMetadata metadata, final Exception exception) {
                    response.put("body", "OK");
                }
            });
            producer.flush();

            /*
            try {
                Thread.sleep(1000);
            } catch (final InterruptedException ie) {}
            */

        } else {
            logger.log("Wake up event received: " + request);
        }
        
        return response;
    }

    private String getJaaSConfig() {
        final StringBuilder jaasConfig = new StringBuilder();
        jaasConfig.append("org.apache.kafka.common.security.plain.PlainLoginModule ");
        jaasConfig.append("required username=\"").append(CLUSTER_API_KEY).append("\" ");
        jaasConfig.append("password=\"").append(CLUSTER_API_SECRET).append("\"; ");
        return jaasConfig.toString();
    }

    private static final String BODY_KEY = "body";
    private static final String BOOTSTRAP_SERVERS = System.getenv("BOOTSTRAP_SERVERS");
    private static final String CLUSTER_API_KEY = System.getenv("CLUSTER_API_KEY");
    private static final String CLUSTER_API_SECRET = System.getenv("CLUSTER_API_SECRET");
    private static KafkaProducer<String, String> producer;

    static {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() {
                producer.close();
            }
        });
    }

}