package com.fairytale.fairytale;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = "com.fairytale.fairytale")
public class FairytaleApplication {
	public static void main(String[] args) {
		SpringApplication.run(FairytaleApplication.class, args);
	}
}


