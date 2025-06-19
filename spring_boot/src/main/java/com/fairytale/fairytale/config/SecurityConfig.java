package com.fairytale.fairytale.config;

import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.auth.strategy.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
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
                // ⭐ CSRF 완전 비활성화
                .csrf(AbstractHttpConfigurer::disable)

                // ⭐ CORS 허용
                .cors(AbstractHttpConfigurer::disable)

                // ⭐ 세션 비활성화 (JWT 사용)
                .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // ⭐ 경로별 권한 설정 (중요!)
                .authorizeHttpRequests(auth -> auth
                        // OAuth 관련 경로는 모두 허용
                        .requestMatchers("/oauth/**").permitAll()
                        .requestMatchers("/api/auth/**").permitAll()

                        // 업로드 관련 경로
                        .requestMatchers("/api/upload/**").authenticated()

                        // 사용자 관련 경로
                        .requestMatchers(HttpMethod.PUT, "/api/user/profile-image").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/user/**").authenticated()
                        .requestMatchers("/api/user/health").permitAll()

                        // 정적 리소스 경로 허용
                        .requestMatchers("/coloring/**").permitAll()

                        // 🔥 갤러리처럼 단순하게! (복잡한 설정 제거)
                        .requestMatchers("/api/gallery/**").authenticated()
                        .requestMatchers("/api/coloring/**").authenticated()  // 🎯 이것만!

                        // 자장가 허용
                        .requestMatchers("/api/lullaby/**").permitAll()

                        // FastAPI 경로 허용
                        .requestMatchers("/api/fairytale/**", "/health", "/actuator/**", "/h2-console/**").permitAll()

                        // 나머지는 인증 필요
                        .anyRequest().authenticated()
                )

                // ⭐ JWT 필터 추가
                .addFilterBefore(new JwtAuthenticationFilter(jwtAuthStrategy), UsernamePasswordAuthenticationFilter.class)

                .build();
    }
}