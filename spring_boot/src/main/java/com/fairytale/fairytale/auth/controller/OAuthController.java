package com.fairytale.fairytale.auth.controller;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.RefreshTokenRequest;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.service.OAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/oauth")
@RequiredArgsConstructor
public class OAuthController {
    private final OAuthService oauthService;

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> socialLogin(@RequestBody OAuthLoginRequest request) {
        System.out.println("🚀 로그인 요청 - Provider: " + request.getProvider());
        System.out.println("🚀 액세스 토큰 앞 20자: " + request.getAccessToken().substring(0, Math.min(20, request.getAccessToken().length())));

        TokenResponse tokenResponse = oauthService.loginWithAccessToken(request);
        return ResponseEntity.ok(tokenResponse);
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(HttpServletRequest request) {
        String token = resolveToken(request);
        if (token != null) {
            oauthService.logout(token);
            return ResponseEntity.ok("로그아웃 성공");
        }
        return ResponseEntity.badRequest().body("토큰이 없습니다.");
    }

    // 토큰 갱신 추가
    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refreshToken(@RequestBody RefreshTokenRequest request) {
        TokenResponse newTokens = oauthService.refreshTokens(request.getRefreshToken());
        return ResponseEntity.ok(newTokens);
    }

    // Authorization 헤더에서 토큰 추출
    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
