package com.fairytale.fairytale.auth.dto;

<<<<<<< HEAD
import lombok.*;
import org.springframework.security.oauth2.jwt.DPoPProofContext;
=======
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
>>>>>>> ff499d6d3234cd9769f50af99afea5d983c6a701

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
<<<<<<< HEAD
@Builder
=======
>>>>>>> ff499d6d3234cd9769f50af99afea5d983c6a701
public class TokenResponse {
    private String accessToken;
    private String refreshToken;
    private String type;

    public TokenResponse(String accessToken, String refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }
}
