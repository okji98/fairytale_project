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
        String token = resolveToken(request); // 요청 헤더에서 토큰 꺼내기

        // 만약에 유저에게 request받은 토큰이 있고 기존에 있던 token과 비교했을 때 똑같다면
        if (token != null && jwtAuthStrategy.isValid(token)) {
            // auth 변수에 token을 넣고 인증 객체로 사용한다.
            Authentication auth = jwtAuthStrategy.getAuthentication(token);
            // 그러고 시큐리티컨텍스트홀더에 담아준다. 담게 되면 인증을 통과한 객체라고 인식한다.
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        // 다음 요청을 처리하도록 넘긴다.
        filterChain.doFilter(request, response);
    }

    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}