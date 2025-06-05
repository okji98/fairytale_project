package com.fairytale.fairytale.coloring;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ColoringTemplateRepository extends JpaRepository<ColoringTemplate, Long> {
    // 최신순으로 조회
    Page<ColoringTemplate> findAllByOrderByCreatedAtDesc(Pageable pageable);

    // 특정 동화의 색칠공부 템플릿 조회
    Optional<ColoringTemplate> findByStoryId(String storyId);

    // 제목으로 검색
    Page<ColoringTemplate> findByTitleContainingOrderByCreatedAtDesc(String keyword, Pageable pageable);

    // 특정 동화 ID들의 템플릿 조회
    Page<ColoringTemplate> findByStoryIdInOrderByCreatedAtDesc(java.util.List<String> storyIds, Pageable pageable);
}
