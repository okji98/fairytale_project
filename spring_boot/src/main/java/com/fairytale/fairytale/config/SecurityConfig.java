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

                        // 🎯 색칠공부 API 상세 권한 설정 (핵심 수정!)
                        .requestMatchers("/api/coloring/**").permitAll()
//                        .requestMatchers(HttpMethod.GET, "/api/coloring/templates").authenticated()
//                        .requestMatchers(HttpMethod.GET, "/api/coloring/templates/**").authenticated()
//                        .requestMatchers(HttpMethod.POST, "/api/coloring/create-template").authenticated()
//                        .requestMatchers(HttpMethod.POST, "/api/coloring/save").authenticated()
//                        .requestMatchers(HttpMethod.POST, "/api/coloring/save-coloring-work").authenticated()
//                        .requestMatchers(HttpMethod.DELETE, "/api/coloring/templates/**").authenticated()
//                        .requestMatchers(HttpMethod.POST, "/api/coloring/share/**").authenticated()
//                        .requestMatchers("/api/coloring/templates/search").authenticated()

                        // 업로드 관련 경로
                        .requestMatchers("/api/upload/**").authenticated()

                        // 사용자 관련 경로
                        .requestMatchers(HttpMethod.PUT, "/api/user/profile-image").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/user/**").authenticated()
                        .requestMatchers("/api/user/health").permitAll()

                        // 갤러리 API
                        .requestMatchers("/api/gallery/**").authenticated()

                        // 정적 리소스 경로 허용
                        .requestMatchers("/coloring/**").permitAll()

                        // 자장가 허용
                        .requestMatchers("/api/lullaby/**").permitAll()

                        // FastAPI 경로 허용
                        .requestMatchers("/api/fairytale/**").permitAll()

                        // 헬스체크 및 관리 경로
                        .requestMatchers("/health", "/actuator/**", "/h2-console/**").permitAll()

                        // 나머지는 인증 필요
                        .anyRequest().authenticated()
                )

                // ⭐ JWT 필터 추가
                .addFilterBefore(new JwtAuthenticationFilter(jwtAuthStrategy), UsernamePasswordAuthenticationFilter.class)

                .build();
    }
}