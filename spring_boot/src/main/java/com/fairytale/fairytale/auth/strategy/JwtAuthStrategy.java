package com.fairytale.fairytale.auth.strategy;

import com.fairytale.fairytale.users.Users;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;

@Component("jwtAuthStrategy") // 스프링 빈으로 등록
@RequiredArgsConstructor
public class JwtAuthStrategy implements AuthStrategy {
    @Value("${jwt.secret}") // application.yml에서 jwt.secret 값 주입
    private String secretKeyString;

    @Value("${jwt.expiration}") // application.yml에서 만료시간 주입
    private Long expirationTimeMs;

    private Key key; // 실제 JWT 서명에 쓰일 key 객체

    @PostConstruct
    public void init() {
        // secretKeyString을 바이트 배열로 바꿔서
        // HMAC-SHA256 서명용 Key 객체 생성
        this.key = Keys.hmacShaKeyFor(secretKeyString.getBytes());
    }

    // 로그인 후 토큰 발급 로직
    @Override
    public String authenticate(Users username) {
        Date now = new Date(); // 현재 시간 생성
        Date expiry = new Date(now.getTime() + expirationTimeMs); // 만료 시간 계산

        return Jwts.builder()
                .setSubject(username.getUsername()) // 토큰의 사용자명 설정
                .setIssuedAt(now) // 발행 시간 설정
                .setExpiration(expiry) // 만료 시간 설정
                .signWith(key, SignatureAlgorithm.HS256) // 비밀키로 HS256 알고리즘 서명
                .compact(); // 최종 JWT 문자열 생성 후 리턴
    }

    // 유효성 검사 로직
    @Override
    public boolean isValid(String token) {
        try {
            // 토큰을 파싱하며 서명 검증도 같이 함
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true; // 문제 없으면 true 반환 (유효한 토큰)
        } catch (JwtException | IllegalArgumentException e) {
            // 파싱 실패, 서명 검증 실패, 토큰이 잘못됐을 때 예외 잡음
            return false; // 유효하지 않은 토큰
        }
    }


    // 토큰에서 사용자 정보 추출 로직
    @Override
    public String getUsername(String token) {
        // 토큰에서 페이로드 부분(Claims)(실제 데이터가 담겨 있는 부분) 파싱해서 가져옴
        Claims claims = Jwts.parserBuilder().setSigningKey(key).build()
                .parseClaimsJws(token)
                .getBody();
        return claims.getSubject(); // Claims에서 subject(사용자명) 반환
    }
}
