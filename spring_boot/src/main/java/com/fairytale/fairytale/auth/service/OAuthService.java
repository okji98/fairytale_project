package com.fairytale.fairytale.auth.service;

import com.fairytale.fairytale.auth.dto.OAuthLoginRequest;
import com.fairytale.fairytale.auth.dto.RefreshToken;
import com.fairytale.fairytale.auth.dto.TokenResponse;
import com.fairytale.fairytale.auth.repository.RefreshTokenRepository;
import com.fairytale.fairytale.auth.strategy.JwtAuthStrategy;
import com.fairytale.fairytale.role.Role;
import com.fairytale.fairytale.role.RoleRepository;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

@Service
@RequiredArgsConstructor
public class OAuthService {
    private final RestTemplate restTemplate;
    private final UsersRepository usersRepository;
    private final RoleRepository roleRepository;
    private final JwtAuthStrategy jwtAuthStrategy;
    private final RefreshTokenRepository refreshTokenRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${spring.security.oauth2.client.provider.kakao.user-info-uri}")
    private String kakaoUserInfoUri;
    @Value("${spring.security.oauth2.client.provider.google.user-info-uri}")
    private String googleUserInfoUri;
    @Value("${spring.security.oauth2.client.registration.kakao.redirect-uri}")
    private String kakaoUserRedirectUri;
    @Value("${spring.security.oauth2.client.registration.google.redirect-uri}")
    private String googleUserRedirectUri;
    @Value("${spring.security.oauth2.client.registration.kakao.client-id}")
    private String kakaoClientId;
    @Value("${spring.security.oauth2.client.registration.google.client-id}")
    private String googleClientId;
    @Value("${spring.security.oauth2.client.registration.google.client-secret}")
    private String googleClientSecret;

    @Transactional
    public TokenResponse loginWithAccessToken(OAuthLoginRequest request) {
        System.out.println("🔍 OAuth 로그인 시작 - Provider: " + request.getProvider());
        // 클라이언트가 보낸 accessToken으로 바로 유저 정보 조회
        Users user = getUserInfoFromProvider(request.getProvider(), request.getAccessToken());
        System.out.println("🔍 소셜 로그인 사용자 정보: " + user.getUsername());
        // 사용자 DB에 저장 또는 업데이트
        Users savedUser = saveOrUpdateUser(user);
        System.out.println("🔍 DB 저장 완료 - ID: " + savedUser.getId() + ", Username: " + savedUser.getUsername());
        // JWT 토큰 발급
        TokenResponse tokens = jwtAuthStrategy.generateTokens(savedUser);
        System.out.println("🔍 JWT 토큰 발급 완료");
        // RefreshToken 저장
        refreshTokenRepository.save(new RefreshToken(savedUser.getId(), tokens.getRefreshToken()));
        return tokens;
    }

    private Users getUserInfoFromProvider(String provider, String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        String uri;
        if ("kakao".equalsIgnoreCase(provider)) {
            uri = kakaoUserInfoUri;
        } else if ("google".equalsIgnoreCase(provider)) {
            uri = googleUserInfoUri;
        } else {
            throw new IllegalArgumentException("지원하지 않는 소셜 로그인 제공자입니다.");
        }

        ResponseEntity<String> response = restTemplate.exchange(uri, HttpMethod.GET, entity, String.class);

        try {
            JsonNode root = objectMapper.readTree(response.getBody());

            if ("kakao".equalsIgnoreCase(provider)) {
                return parseKakaoUser(root);
            } else if ("google".equalsIgnoreCase(provider)) {
                return parseGoogleUser(root);
            }
        } catch (Exception e) {
            throw new RuntimeException(provider + " 사용자 정보 파싱 실패", e);
        }

        throw new IllegalStateException("사용자 정보 파싱 실패");
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
        // 🆕 기본 USER 역할 설정
        Role userRole = roleRepository.findByRoleName("USER")
                .orElseGet(() -> {
                    System.out.println("⚠️ USER 역할이 없어서 새로 생성합니다.");
                    Role newRole = new Role();
                    newRole.setRoleName("USER");
                    return roleRepository.save(newRole);
                });

        // OAuth 사용자에게 역할 설정
        oauthUser.setRole(userRole);
        System.out.println("🔍 사용자 역할 설정 완료: " + userRole.getRoleName());

        return usersRepository.findByEmail(oauthUser.getEmail())
                .or(() -> usersRepository.findByGoogleId(oauthUser.getGoogleId()))
                .or(() -> usersRepository.findByKakaoId(oauthUser.getKakaoId()))
                .map(existingUser -> {
                    System.out.println("🔍 기존 사용자 업데이트: " + existingUser.getUsername());
                    existingUser.setNickname(oauthUser.getNickname());
                    // 역할이 없으면 설정
                    if (existingUser.getRole() == null) {
                        existingUser.setRole(userRole);
                    }
                    // 소셜 ID 업데이트
                    if (oauthUser.getGoogleId() != null) {
                        existingUser.setGoogleId(oauthUser.getGoogleId());
                    }
                    if (oauthUser.getKakaoId() != null) {
                        existingUser.setKakaoId(oauthUser.getKakaoId());
                    }
                    return usersRepository.save(existingUser);
                })
                .orElseGet(() -> {
                    System.out.println("🔍 새 사용자 생성: " + oauthUser.getUsername());
                    return usersRepository.save(oauthUser);
                });
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
