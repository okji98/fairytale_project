package com.fairytale.fairytale.coloring;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional
@RequiredArgsConstructor
public class ColoringTemplateService {
    private final ColoringTemplateRepository coloringTemplateRepository;

    // 🎨 색칠공부 템플릿 생성 또는 업데이트
    public ColoringTemplate createColoringTemplate(String storyId, String title,
                                                   String originalImageUrl, String blackWhiteImageUrl) {

        System.out.println("🎨 색칠공부 템플릿 저장 시작 - StoryId: " + storyId);

        // 기존 템플릿이 있는지 확인
        Optional<ColoringTemplate> existing = coloringTemplateRepository.findByStoryId(storyId);

        ColoringTemplate template;

        if (existing.isPresent()) {
            // 기존 템플릿 업데이트
            System.out.println("🔄 기존 색칠공부 템플릿 업데이트");
            template = existing.get();
            template.setTitle(title);
            template.setOriginalImageUrl(originalImageUrl);
            template.setBlackWhiteImageUrl(blackWhiteImageUrl);
        } else {
            // 새 템플릿 생성
            System.out.println("🆕 새 색칠공부 템플릿 생성");
            template = ColoringTemplate.builder()
                    .title(title)
                    .storyId(storyId)
                    .originalImageUrl(originalImageUrl)
                    .blackWhiteImageUrl(blackWhiteImageUrl)
                    .build();
        }

        ColoringTemplate savedTemplate = coloringTemplateRepository.save(template);
        System.out.println("✅ 색칠공부 템플릿 저장 완료 - ID: " + savedTemplate.getId());

        return savedTemplate;
    }

    // 🎨 모든 색칠공부 템플릿 조회
    public Page<ColoringTemplate> getAllTemplates(Pageable pageable) {
        System.out.println("🔍 색칠공부 템플릿 목록 조회");
        return coloringTemplateRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    // 🎨 특정 템플릿 조회
    public ColoringTemplate getTemplateById(Long templateId) {
        System.out.println("🔍 색칠공부 템플릿 상세 조회 - ID: " + templateId);
        return coloringTemplateRepository.findById(templateId)
                .orElseThrow(() -> new RuntimeException("색칠공부 템플릿을 찾을 수 없습니다: " + templateId));
    }

    // 🎨 동화 ID로 색칠공부 템플릿 조회
    public Optional<ColoringTemplate> getTemplateByStoryId(String storyId) {
        System.out.println("🔍 동화별 색칠공부 템플릿 조회 - StoryId: " + storyId);
        return coloringTemplateRepository.findByStoryId(storyId);
    }

    // 🎨 제목으로 검색
    public Page<ColoringTemplate> searchTemplatesByTitle(String keyword, Pageable pageable) {
        System.out.println("🔍 색칠공부 템플릿 검색 - 키워드: " + keyword);
        return coloringTemplateRepository.findByTitleContainingOrderByCreatedAtDesc(keyword, pageable);
    }

    // 🎨 템플릿 삭제
    public void deleteTemplate(Long templateId) {
        System.out.println("🗑️ 색칠공부 템플릿 삭제 - ID: " + templateId);

        ColoringTemplate template = getTemplateById(templateId);
        coloringTemplateRepository.delete(template);

        System.out.println("✅ 색칠공부 템플릿 삭제 완료");
    }
}