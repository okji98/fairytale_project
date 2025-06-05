package com.fairytale.fairytale.coloring;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/coloring")
public class ColoringController {

    @Autowired
    private ColoringTemplateService coloringTemplateService;

    // 🎯 색칠공부 템플릿 목록 조회
    @GetMapping("/templates")
    public ResponseEntity<Map<String, Object>> getColoringTemplates(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        System.out.println("🔍 색칠공부 템플릿 목록 조회 요청 - page: " + page + ", size: " + size);

        try {
            Page<ColoringTemplate> templates = coloringTemplateService
                    .getAllTemplates(PageRequest.of(page, size));

            List<Map<String, Object>> templateList = templates.getContent()
                    .stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("templates", templateList);
            response.put("totalElements", templates.getTotalElements());
            response.put("totalPages", templates.getTotalPages());
            response.put("currentPage", page);

            System.out.println("✅ 색칠공부 템플릿 " + templateList.size() + "개 조회 성공");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.out.println("❌ 색칠공부 템플릿 조회 오류: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "템플릿 조회 실패"));
        }
    }

    // 🎯 특정 템플릿 상세 조회
    @GetMapping("/templates/{templateId}")
    public ResponseEntity<Map<String, Object>> getTemplateDetail(
            @PathVariable Long templateId) {

        System.out.println("🔍 색칠공부 템플릿 상세 조회 - ID: " + templateId);

        try {
            ColoringTemplate template = coloringTemplateService.getTemplateById(templateId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("template", convertToDTO(template));

            System.out.println("✅ 색칠공부 템플릿 상세 조회 성공: " + template.getTitle());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.out.println("❌ 색칠공부 템플릿 상세 조회 오류: " + e.getMessage());
            return ResponseEntity.status(404)
                    .body(Map.of("success", false, "error", "템플릿을 찾을 수 없습니다"));
        }
    }

    // 🎯 동화 ID로 색칠공부 템플릿 조회
    @GetMapping("/templates/story/{storyId}")
    public ResponseEntity<Map<String, Object>> getTemplateByStoryId(
            @PathVariable String storyId) {

        System.out.println("🔍 동화별 색칠공부 템플릿 조회 - StoryId: " + storyId);

        try {
            return coloringTemplateService.getTemplateByStoryId(storyId)
                    .map(template -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("template", convertToDTO(template));
                        return ResponseEntity.ok(response);
                    })
                    .orElse(ResponseEntity.status(404)
                            .body(Map.of("success", false, "error", "해당 동화의 색칠공부 템플릿이 없습니다")));

        } catch (Exception e) {
            System.out.println("❌ 동화별 색칠공부 템플릿 조회 오류: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "조회 실패"));
        }
    }

    // 🎯 제목으로 색칠공부 템플릿 검색
    @GetMapping("/templates/search")
    public ResponseEntity<Map<String, Object>> searchTemplates(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        System.out.println("🔍 색칠공부 템플릿 검색 - 키워드: " + keyword);

        try {
            Page<ColoringTemplate> templates = coloringTemplateService
                    .searchTemplatesByTitle(keyword, PageRequest.of(page, size));

            List<Map<String, Object>> templateList = templates.getContent()
                    .stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("templates", templateList);
            response.put("totalElements", templates.getTotalElements());
            response.put("keyword", keyword);

            System.out.println("✅ 색칠공부 템플릿 검색 완료 - " + templateList.size() + "개 발견");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.out.println("❌ 색칠공부 템플릿 검색 오류: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "검색 실패"));
        }
    }

    // 🎯 색칠 완성작 저장 (추후 구현용)
    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveColoredImage(
            @RequestBody Map<String, Object> request) {

        System.out.println("🎨 색칠 완성작 저장 요청");

        try {
            // TODO: 실제 색칠 완성작 저장 로직 구현
            // 현재는 성공 응답만 반환

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠 완성작이 갤러리에 저장되었습니다!");
            response.put("savedAt", java.time.LocalDateTime.now().toString());

            System.out.println("✅ 색칠 완성작 저장 완료 (시뮬레이션)");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.out.println("❌ 색칠 완성작 저장 오류: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "저장 실패"));
        }
    }

    // 🔧 ColoringTemplate을 DTO로 변환
    private Map<String, Object> convertToDTO(ColoringTemplate template) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", template.getId().toString());
        dto.put("title", template.getTitle());
        dto.put("storyId", template.getStoryId());
        dto.put("imageUrl", template.getBlackWhiteImageUrl());  // 🎯 흑백 이미지 URL
        dto.put("originalImageUrl", template.getOriginalImageUrl());  // 원본 컬러 이미지
        dto.put("storyTitle", template.getTitle());  // 동화 제목과 동일
        dto.put("createdAt", template.getCreatedAt().format(
                DateTimeFormatter.ofPattern("yyyy-MM-dd")));

        return dto;
    }
}