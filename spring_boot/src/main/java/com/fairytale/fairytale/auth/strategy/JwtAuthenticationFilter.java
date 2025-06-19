// 🎯 JwtAuthenticationFilter.java - 색칠공부 인증 처리 개선

package com.fairytale.fairytale.auth.strategy;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private JwtAuthStrategy jwtAuthStrategy;

    public JwtAuthenticationFilter(JwtAuthStrategy jwtAuthStrategy) {
        this.jwtAuthStrategy = jwtAuthStrategy;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();
        String method = request.getMethod();

        // 🔧 OAuth 경로와 기타 공개 경로는 JWT 필터를 건너뛰기
        if (path.startsWith("/oauth/") ||
                path.startsWith("/api/auth/") ||
                path.startsWith("/coloring/") ||
                path.equals("/health") ||
                path.startsWith("/actuator/") ||
                path.startsWith("/h2-console/")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 🎯 색칠공부 GET 요청 중 인증이 필요 없는 것들만 허용
        if (path.startsWith("/api/coloring") && "GET".equals(method)) {
            // 내 색칠공부 목록은 인증 필요
            if (path.equals("/api/coloring/my")) {
                // JWT 토큰 처리 계속 진행
            } else {
                // 다른 GET 요청들은 허용
                filterChain.doFilter(request, response);
                return;
            }
        }

        String token = resolveToken(request); // 요청 헤더에서 토큰 꺼내기

        // 🔍 디버깅 로그 추가
        System.out.println("🔍 [JwtFilter] 경로: " + path + ", 메서드: " + method);
        System.out.println("🔍 [JwtFilter] 토큰 존재: " + (token != null));

        // 만약에 유저에게 request받은 토큰이 있고 기존에 있던 token과 비교했을 때 똑같다면
        if (token != null && jwtAuthStrategy.isValid(token)) {
            // auth 변수에 token을 넣고 인증 객체로 사용한다.
            Authentication auth = jwtAuthStrategy.getAuthentication(token);

            // 🔍 디버깅 로그 추가
            System.out.println("🔍 [JwtFilter] 인증 객체 생성: " + (auth != null));
            if (auth != null) {
                System.out.println("🔍 [JwtFilter] 사용자명: " + auth.getName());
            }

            // 그러고 시큐리티컨텍스트홀더에 담아준다. 담게 되면 인증을 통과한 객체라고 인식한다.
            SecurityContextHolder.getContext().setAuthentication(auth);
        } else {
            System.out.println("❌ [JwtFilter] 토큰이 없거나 유효하지 않음");
        }

        // 다음 요청을 처리하도록 넘긴다.
        filterChain.doFilter(request, response);
    }

    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        System.out.println("🔍 [JwtFilter] Authorization 헤더: " + bearerToken);

        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            String token = bearerToken.substring(7);
            System.out.println("🔍 [JwtFilter] 추출된 토큰: " + token.substring(0, Math.min(20, token.length())) + "...");
            return token;
        }
        return null;
    }
}