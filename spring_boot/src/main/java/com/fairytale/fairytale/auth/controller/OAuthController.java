package com.fairytale.fairytale.auth.controller;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.service.OAuthService;
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
        TokenResponse tokenResponse = oauthService.loginWithOauth(request);
        return ResponseEntity.ok(tokenResponse);
    }
}
