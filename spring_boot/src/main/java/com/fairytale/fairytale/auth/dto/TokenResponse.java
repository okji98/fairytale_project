package com.fairytale.fairytale.auth.dto;

import lombok.*;
import org.springframework.security.oauth2.jwt.DPoPProofContext;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class TokenResponse {
    private String accessToken;
    private String refreshToken;
    private String type;

    public TokenResponse(String accessToken, String refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }
}
