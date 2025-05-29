package com.fairytale.fairytale.auth.service;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.strategy.AuthStrategy;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

@Service
@RequiredArgsConstructor
public class OAuthService {
    private final UsersRepository usersRepository;
    private final AuthStrategy jwtAuthStrategy;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();
    @Value("${spring.security.oauth2.client.provider.kakao.user-info-uri}")
    private String kakaoUserInfoUri;
    @Value("${spring.security.oauth2.client.provider.google.user-info-uri}")
    private String googleUserInfoUri;
    @Value("${spring.security.oauth2.client.provider.kakao.client-id}")
    private String kakaoUserApi;
    @Value("${spring.security.oauth2.client.provider.google.client-id}")
    private String googleUserApi;

    @Transactional
    public TokenResponse loginWithOauth(OAuthLoginRequest request){
        // 1. 소셜 토큰으로 사용자 정보 가져오기
        Users user = getUserInfoFromProvider(request.getProvider(), request.getAccessToken());
        // 2. DB에 사용자 정보 저장 or 업데이트
        Users savedUser = saveOrUpdateUser(user);
        String jwtToken = jwtAuthStrategy.authenticate(savedUser);
        return new TokenResponse(jwtToken, "Bearer ");
    }

    private Users getUserInfoFromProvider(String provider, String accessToken) {
        // 만약 회사이름이 카카오라면 엑세스토큰 발급
        if (provider.equals("kakao")) {
            return getKakaoUser(accessToken);
        } else if (provider.equals("google")) {
            return getGoogleUser(accessToken);
        }
        throw new IllegalArgumentException("지원하지 않는 소셜 로그인 제공자입니다.");
    }

    // provider가 "kakao"일 때, accessToken을 이용해 카카오 사용자 정보를 가져오는 메서드
    private Users getKakaoUser(String accessToken) {
        // http 헤더에 accesstoken 넣기
        HttpHeaders headers = new HttpHeaders();
        // Base64로 인코딩한 accessToken을 header에 넣음
        headers.setBearerAuth(accessToken);
        // entity에 headers의 accessToken을 담음.
        HttpEntity<String> entity = new HttpEntity<>(headers);

        ResponseEntity<String> response = restTemplate.exchange(
                kakaoUserInfoUri, // 카카오 유저 정보 URL
                HttpMethod.GET, // GET요청
                entity, // 토큰이 담긴 헤더
                String.class // 응답을 String타입으로 받는다.
        );

        try {
            // 카카오가 준 유저 정보를 root에 담음.
            JsonNode root = objectMapper.readTree(response.getBody());
            // 카카오 ID
            Long kakaoId = root.path("id").asLong();
            // 카카오 계정 정보
            JsonNode kakaoAccount = root.path("kakao_account");
            // 계정 정보에서 email을 꺼내올 때 null값이면 null값을 주고 있으면 문자열로 준다.
            String email = kakaoAccount.path("email").asText(null);
            JsonNode profile = kakaoAccount.path("profile");
            String nickname = profile.path("nickname").asText(null);

            // Users 객체 빌드
            return Users.builder()
                    .kakaoId(String.valueOf(kakaoId))
                    .email(email)
                    .nickname(nickname)
                    .build();

        } catch (Exception e) {
            throw new RuntimeException("kakao 사용자 정보 파싱 실패", e);
        }
    }

    private Users getGoogleUser(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        ResponseEntity<String> response = restTemplate.exchange(
                googleUserInfoUri,
                HttpMethod.GET,
                entity,
                String.class
        );

        try {
            JsonNode root = objectMapper.readTree(response.getBody());
            Long googleId = root.path("id").asLong();
            // google 계정 정보
            JsonNode googleAccount = root.path("google_account");
            // 계정 정보에서 email, nickname을 꺼내올 때 null값이면 null값을 주고 있으면 문자열로 준다.
            String email = googleAccount.path("email").asText(null);
            JsonNode profile = root.path("profile");
            String nickname = profile.path("nickname").asText(null);

            return Users.builder()
                    .googleId(String.valueOf(googleId))
                    .email(email)
                    .nickname(nickname)
                    .build();

        } catch (Exception e) {
            throw new RuntimeException("google 사용자 정보 파싱 실패", e);
        }
    }

    private Users saveOrUpdateUser(Users user) {
        return usersRepository.findByEmail(user.getEmail())
                .map(existingUser -> {
                    existingUser.setNickname(user.getNickname());
                    return usersRepository.save(existingUser);
                }).orElseGet(() -> usersRepository.save(user));
    }
}
