package io.confluent.devx.util.thesongis;

import java.util.Arrays;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
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
    private static final String CURRENTLY_PLAYING_API = "https://api.spotify.com/v1/me/player/currently-playing";
    private static final String PAUSE_USERS_PLAYBACK_API = "https://api.spotify.com/v1/me/player/pause";

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Value("${spotify.access.token}")
    private String spotifyAccessToken;

    @Value("${spotify.refresh.token}")
    private String spotifyRefreshToken;

    @Value("${DEVICE_ID}")
    private String deviceId;

    @Value("${CLIENT_ID}")
    private String clientId;

    @Value("${CLIENT_SECRET}")
    private String clientSecret;

    private final RestTemplate rest = new RestTemplate();
    private final JsonParser parser = new JsonParser();

    private String currentSong;

    @KafkaListener(topics = CURRENT_SONG)
    public void updateCurrentSong(ConsumerRecord record) {

        String json = record.value().toString();
        JsonElement ele = parser.parse(json);
        JsonObject root = ele.getAsJsonObject();
        currentSong = root.get("name").getAsString();

    }

    @Scheduled(fixedRate = 3000)
    public void monitorCurrentSong() {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON));
        headers.setBearerAuth(spotifyAccessToken);

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
        values.add("refresh_token", spotifyRefreshToken);

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

            spotifyAccessToken = root.get("access_token").getAsString();
            System.out.println("------------> Access Token was Refreshed Successfully !!!");

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
        headers.setBearerAuth(spotifyAccessToken);

        HttpEntity<String> request =
            new HttpEntity<String>("parameters", headers);

        try {

            StringBuilder endpointUri = new StringBuilder();
            endpointUri.append(PAUSE_USERS_PLAYBACK_API);
            endpointUri.append("?device_id=");
            endpointUri.append(deviceId);

            rest.exchange(endpointUri.toString(),
                HttpMethod.PUT, request, String.class);

        } catch (Exception ex) { ex.printStackTrace(); }

    }

}