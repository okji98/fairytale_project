package com.fairytale.fairytale.config;

import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.auth.strategy.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthStrategy jwtAuthStrategy;

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/main", "/home", "/share", "/stories", "/coloring-list", "coloring", "/lullabies", "/not-profile").permitAll()
                        .requestMatchers("/oauth/login", "/oauth/refresh").permitAll() // 로그인, 토큰 갱신 허용
                        .requestMatchers("/oauth/logout").authenticated() // 로그아웃은 인증 필요
                        .anyRequest().authenticated()
                )
                .addFilterBefore(new JwtAuthenticationFilter(jwtAuthStrategy), UsernamePasswordAuthenticationFilter.class)
                .build();
    }
}
