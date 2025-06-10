package com.fairytale.fairytale.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestTemplateConfig {
    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();

        // 기본 JDK의 SimpleClientHttpRequestFactory 사용 (스프링부트 3.x 호환)
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();

        // 타임아웃 설정
        factory.setConnectTimeout(5000);     // 연결 타임아웃 5초
        factory.setReadTimeout(10000);       // 읽기 타임아웃 10초

        restTemplate.setRequestFactory(factory);

        return restTemplate;
    }
}