// src/main/java/com/fairytale/fairytale/share/SharePostRepository.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SharePostRepository extends JpaRepository<SharePost, Long> {

    /**
     * 모든 공유 게시물을 최신순으로 조회
     */
    List<SharePost> findAllByOrderByCreatedAtDesc();

    /**
     * 특정 사용자의 공유 게시물 조회
     */
    List<SharePost> findByUserOrderByCreatedAtDesc(Users user);

    /**
     * 특정 소스(Story/Gallery)에서 생성된 게시물 확인
     */
    boolean existsBySourceTypeAndSourceId(String sourceType, Long sourceId);
}