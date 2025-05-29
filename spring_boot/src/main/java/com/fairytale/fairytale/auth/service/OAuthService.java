package com.fairytale.fairytale.auth.service;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.RefreshToken;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.repository.RefreshTokenRepository;
import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

@Service
@RequiredArgsConstructor
public class OAuthService {
    private final UsersRepository usersRepository;
    private final JwtAuthStrategy jwtAuthStrategy;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();
    @Value("${spring.security.oauth2.client.provider.kakao.user-info-uri}")
    private String kakaoUserInfoUri;
    @Value("${spring.security.oauth2.client.provider.google.user-info-uri}")
    private String googleUserInfoUri;
    @Value("${spring.security.oauth2.client.registration.kakao.client-id}")
    private String kakaoClientId;
    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private String googleClientId;
    @Value("${spring.security.oauth2.client.provider.client-secret}")
    private String googleClientSecret;

    @Transactional
    public TokenResponse loginWithAuthorizationCode(OAuthLoginRequest request) {
        // 1. 소셜 provider로부터 AccessToken 얻기
        String socialAccessToken = getAccessTokenFromProvider(request.getProvider(), request.getAuthorizationCode());
        // 2. AccessToken으로 사용자 정보 가져오기
        Users user = getUserInfoFromProvider(request.getProvider(), socialAccessToken);
        // 3. DB에 사용자 정보 저장 or 업데이트
        Users savedUser = saveOrUpdateUser(user);
        // 4. JWT 발급
        TokenResponse tokens = jwtAuthStrategy.generateTokens(savedUser);
        // 5. Refresh Token 저장
        refreshTokenRepository.save(new RefreshToken(savedUser.getId(), tokens.getRefreshToken()));

        return tokens;
    }

    private String getAccessTokenFromProvider(String provider, String authorizationCode) {
        if (provider.equalsIgnoreCase("kakao")) {
            return getKakaoAccessToken(authorizationCode);
        } else if (provider.equalsIgnoreCase("google")) {
            return getGoogleAccessToken(authorizationCode);
        } else {
            throw new IllegalArgumentException("지원하지 않는 provider: " + provider);
        }
    }

    private Users getUserInfoFromProvider(String provider, String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        String uri = "";
        if ("kakao".equals(provider)) uri = kakaoUserInfoUri;
        else if ("google".equals(provider)) uri = googleUserInfoUri;
        else throw new IllegalArgumentException("지원하지 않는 소셜 로그인 제공자입니다.");

        ResponseEntity<String> response = restTemplate.exchange(uri, HttpMethod.GET, entity, String.class);

        try {
            JsonNode root = objectMapper.readTree(response.getBody());
            if ("kakao".equals(provider)) {
                return parseKakaoUser(root);
            } else if ("google".equals(provider)) {
                return parseGoogleUser(root);
            }
        } catch (Exception e) {
            throw new RuntimeException(provider + " 사용자 정보 파싱 실패", e);
        }
        throw new IllegalStateException("사용자 정보 파싱 실패");
    }

    private String getKakaoAccessToken(String authorizationCode) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "authorization_code");
        body.add("client_id", kakaoClientId);
        body.add("redirect_uri", kakaoUserInfoUri);
        body.add("code", authorizationCode);

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);
        ResponseEntity<String> response = restTemplate.postForEntity("https://kauth.kakao.com/oauth/token", request, String.class);

        try {
            JsonNode json = objectMapper.readTree(response.getBody());
            return json.get("access_token").asText();
        } catch (Exception e) {
            throw new RuntimeException("카카오 access token 요청 실패", e);
        }
    }


    private String getGoogleAccessToken(String authorizationCode) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "authorization_code");
        body.add("client_id", googleClientId);
        body.add("client_secret", googleClientSecret);
        body.add("redirect_uri", googleUserInfoUri);
        body.add("code", authorizationCode);

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);
        ResponseEntity<String> response = restTemplate.postForEntity("https://oauth2.googleapis.com/token", request, String.class);

        try {
            JsonNode json = objectMapper.readTree(response.getBody());
            return json.get("access_token").asText();
        } catch (Exception e) {
            throw new RuntimeException("구글 access token 요청 실패", e);
        }
    }

    private Users parseKakaoUser(JsonNode root) {
        String kakaoId = root.get("id").asText();
        JsonNode account = root.get("kakao_account");
        String email = account.has("email") ? account.get("email").asText() : kakaoId + "@kakao.com";
        String nickname = account.get("profile").get("nickname").asText();

        return Users.builder()
                .kakaoId(kakaoId)
                .email(email)
                .nickname(nickname)
                .username("kakao_" + kakaoId)
                .build();
    }

    private Users parseGoogleUser(JsonNode root) {
        String googleId = root.get("sub").asText();
        String email = root.get("email").asText();
        String nickname = root.get("name").asText();

        return Users.builder()
                .googleId(googleId)
                .email(email)
                .nickname(nickname)
                .username("google_" + googleId)
                .build();
    }

    private Users saveOrUpdateUser(Users oauthUser) {
        return usersRepository.findByEmail(oauthUser.getEmail())
                .or(() -> usersRepository.findByGoogleId(oauthUser.getGoogleId()))
                .or(() -> usersRepository.findByKakaoId(oauthUser.getKakaoId()))
                .map(user -> {
                    user.setNickname(oauthUser.getNickname());
                    return usersRepository.save(user);
                }).orElseGet(() -> usersRepository.save(oauthUser));
    }

    // 로그아웃 기능 추가
    @Transactional
    public void logout(String accessToken) {
        try {
            // 1. 액세스 토큰에서 사용자 정보 추출
            String username = jwtAuthStrategy.getUsername(accessToken);

            // 2. 사용자 ID로 리프레시 토큰 삭제
            Users user = usersRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            refreshTokenRepository.deleteByUserId(user.getId());

        } catch (Exception e) {
            throw new RuntimeException("로그아웃 처리 중 오류 발생", e);
        }
    }

    // 토큰 갱신 기능 추가
    @Transactional
    public TokenResponse refreshTokens(String refreshToken) {
        try {
            // 1. 리프레시 토큰 유효성 검사
            if (!jwtAuthStrategy.isValid(refreshToken)) {
                throw new RuntimeException("유효하지 않은 리프레시 토큰입니다.");
            }

            // 2. 리프레시 토큰에서 사용자 정보 추출
            String username = jwtAuthStrategy.getUsername(refreshToken);
            Users user = usersRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            // 3. DB에서 리프레시 토큰 확인
            RefreshToken storedRefreshToken = refreshTokenRepository.findByUserId(user.getId())
                    .orElseThrow(() -> new RuntimeException("저장된 리프레시 토큰이 없습니다."));

            if (!storedRefreshToken.getRefreshToken().equals(refreshToken)) {
                throw new RuntimeException("리프레시 토큰이 일치하지 않습니다.");
            }

            // 4. 새로운 토큰들 생성
            TokenResponse newTokens = jwtAuthStrategy.generateTokens(user);

            // 5. 새로운 리프레시 토큰 저장
            storedRefreshToken.setRefreshToken(newTokens.getRefreshToken());
            refreshTokenRepository.save(storedRefreshToken);

            return newTokens;

        } catch (Exception e) {
            throw new RuntimeException("토큰 갱신 중 오류 발생", e);
        }
    }
}
