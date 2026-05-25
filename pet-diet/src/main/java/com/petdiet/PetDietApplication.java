package com.petdiet;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class PetDietApplication {

	public static void main(String[] args) {
		SpringApplication.run(PetDietApplication.class, args);
	}

}
