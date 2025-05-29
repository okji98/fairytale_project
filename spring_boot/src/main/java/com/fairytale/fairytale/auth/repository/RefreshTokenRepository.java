package com.fairytale.fairytale.auth.repository;

import com.fairytale.fairytale.auth.dto.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByUserId(Long userId);
    // 로그아웃 시 리프레시 토큰 삭제용
    void deleteByUserId(Long userId);
}
