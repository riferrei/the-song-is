package io.confluent.cloud.thesongis;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class SongHelperApp {

	public static void main(String[] args) {
		SpringApplication.run(SongHelperApp.class, args);
	}

}