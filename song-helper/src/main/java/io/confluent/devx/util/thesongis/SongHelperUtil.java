package io.confluent.devx.util.thesongis;

import java.util.Arrays;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

@Service
public class SongHelperUtil {

    private static final String CURRENT_SONG = "CURRENT_SONG";
    private static final String WINNERS = "WINNERS";

    private static final String SPOTIFY_ACCOUNT_TOKENS = "https://accounts.spotify.com/api/token";
    private static final String SPOTIFY_PLAYER_DEVICES = "https://api.spotify.com/v1/me/player/devices";
    private static final String CURRENTLY_PLAYING_API = "https://api.spotify.com/v1/me/player/currently-playing";
    private static final String PAUSE_USERS_PLAYBACK_API = "https://api.spotify.com/v1/me/player/pause";

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Value("${CLIENT_ID}")
    private String clientId;

    @Value("${CLIENT_SECRET}")
    private String clientSecret;

    @Value("${ACCESS_TOKEN}")
    private String accessToken;

    @Value("${REFRESH_TOKEN}")
    private String refreshToken;

    @Value("${DEVICE_NAME}")
    private String deviceName;

    private final Logger logger = LoggerFactory.getLogger(SongHelperUtil.class);
    private final RestTemplate rest = new RestTemplate();
    private final JsonParser parser = new JsonParser();

    private String deviceId;
    private String currentSong;

    @KafkaListener(topics = CURRENT_SONG)
    public void updateCurrentSong(ConsumerRecord record) {

        String json = record.value().toString();
        JsonElement ele = parser.parse(json);
        JsonObject root = ele.getAsJsonObject();
        currentSong = root.get("name").getAsString();

    }

    @Scheduled(fixedRate = 30000)
    public void monitorDeviceId() {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON));
        headers.setBearerAuth(accessToken);

        HttpEntity<String> request =
            new HttpEntity<String>("parameters", headers);

        ResponseEntity<String> response = null;

        try {

            response = rest.exchange(SPOTIFY_PLAYER_DEVICES,
                HttpMethod.GET, request, String.class);

        } catch (HttpClientErrorException ex) {

            if (ex.getStatusCode().equals(HttpStatus.UNAUTHORIZED)) {
                refreshAccessToken();
            }
    
        }

        if (response != null && response.getStatusCode().equals(HttpStatus.OK)) {

            String json = response.getBody();
            JsonElement ele = parser.parse(json);
            JsonObject root = ele.getAsJsonObject();
            JsonArray devices = root.getAsJsonArray("devices");

            if (devices != null && devices.size() > 0) {

                boolean found = false;

                for (int i = 0; i < devices.size(); i++) {

                    JsonObject device = devices.get(i).getAsJsonObject();
                    String deviceName = device.get("name").getAsString();

                    if (deviceName.equals(this.deviceName)) {

                        deviceId = device.get("id").getAsString();
                        found = true;
                        break;

                    }

                }

                if (!found) {
                    deviceId = null;
                }

            }

        }
    
    }

    @Scheduled(fixedRate = 1000)
    public void monitorCurrentSong() {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON));
        headers.setBearerAuth(accessToken);

        HttpEntity<String> request =
            new HttpEntity<String>("parameters", headers);

        ResponseEntity<String> response = null;

        try {

            response = rest.exchange(CURRENTLY_PLAYING_API,
                HttpMethod.GET, request, String.class);

        } catch (HttpClientErrorException ex) {

            if (ex.getStatusCode().equals(HttpStatus.UNAUTHORIZED)) {
                refreshAccessToken();
            }

        }

        if (response != null && response.getStatusCode().equals(HttpStatus.OK)) {

            String json = response.getBody();
            JsonElement ele = parser.parse(json);
            JsonObject root = ele.getAsJsonObject();

            JsonObject item = root.getAsJsonObject("item");
            String songName = item.get("name").getAsString();
            JsonArray artists = item.getAsJsonArray("artists");
            JsonObject artist = artists.get(0).getAsJsonObject();
            String author = artist.get("name").getAsString();

            if (currentSong == null || !currentSong.equals(songName)) {
                setCurrentSong(songName, author);
            }

        }

    }

    private void refreshAccessToken() {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        headers.setBasicAuth(clientId, clientSecret);

        MultiValueMap<String, String> values = new LinkedMultiValueMap<String, String>();
        values.add("grant_type", "refresh_token");
        values.add("refresh_token", refreshToken);

        HttpEntity<MultiValueMap<String, String>> request =
            new HttpEntity<MultiValueMap<String, String>>(values, headers);

        ResponseEntity<String> response = null;

        try {

            response = rest.postForEntity(SPOTIFY_ACCOUNT_TOKENS,
                request, String.class);

        } catch (Exception ex) { ex.printStackTrace(); }

        if (response != null && response.getStatusCode().equals(HttpStatus.OK)) {

            String json = response.getBody();
            JsonElement ele = parser.parse(json);
            JsonObject root = ele.getAsJsonObject();

            accessToken = root.get("access_token").getAsString();
            logger.info("The access token has been refreshed successfully!");

        }

    }

    private void setCurrentSong(String songName, String author) {

        JsonObject root = new JsonObject();
        root.addProperty("name", songName);
        root.addProperty("author", author);

        ProducerRecord<String, String> record =
            new ProducerRecord<String, String>(CURRENT_SONG,
                root.toString());

        kafkaTemplate.send(record);

    }

    @KafkaListener(topics = WINNERS)
    public void stopCurrentSong(ConsumerRecord record) {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON));
        headers.setBearerAuth(accessToken);

        HttpEntity<String> request =
            new HttpEntity<String>("parameters", headers);

        try {

            if (deviceId != null) {

                StringBuilder endpoint = new StringBuilder();
                endpoint.append(PAUSE_USERS_PLAYBACK_API);
                endpoint.append("?device_id=");
                endpoint.append(deviceId);
    
                rest.exchange(endpoint.toString(),
                    HttpMethod.PUT, request, String.class);

            } else {

                rest.exchange(PAUSE_USERS_PLAYBACK_API,
                    HttpMethod.PUT, request, String.class);

            }

        } catch (Exception ex) { ex.printStackTrace(); }

    }

}