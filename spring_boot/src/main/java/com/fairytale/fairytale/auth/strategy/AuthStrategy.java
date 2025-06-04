package com.fairytale.fairytale.auth.strategy;

import com.fairytale.fairytale.users.Users;
import jakarta.servlet.http.HttpServletRequest;
<<<<<<< HEAD
import org.springframework.security.core.Authentication;
=======
>>>>>>> ff499d6d3234cd9769f50af99afea5d983c6a701

public interface AuthStrategy {
    String authenticate(Users user, Long durationMs); // 로그인 후 토큰 발급
    boolean isValid(String token); // 유효성 검사
    String getUsername(String token); // 토큰에서 사용자 정보 추출
<<<<<<< HEAD
    Authentication getAuthentication(String token);
=======
>>>>>>> ff499d6d3234cd9769f50af99afea5d983c6a701
}
