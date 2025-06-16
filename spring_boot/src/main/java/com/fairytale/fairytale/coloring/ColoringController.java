package com.fairytale.fairytale.coloring;

import com.fairytale.fairytale.service.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.juli.logging.Log;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/coloring")
public class ColoringController {
    private final ColoringTemplateService coloringTemplateService;
    private final ColoringWorkRepository coloringWorkRepository;
    private final S3Service s3Service;

    // 🎯 색칠공부 템플릿 목록 조회
    @GetMapping("/templates")
    public ResponseEntity<Map<String, Object>> getColoringTemplates(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("🔍 색칠공부 템플릿 목록 조회 요청 - page: {}, size: {}", page, size);

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

            log.info("✅ 색칠공부 템플릿 {}개 조회 성공", templateList.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 조회 오류: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "템플릿 조회 실패"));
        }
    }

    // 🎯 특정 템플릿 상세 조회
    @GetMapping("/templates/{templateId}")
    public ResponseEntity<Map<String, Object>> getTemplateDetail(
            @PathVariable Long templateId) {

        log.info("🔍 색칠공부 템플릿 상세 조회 - ID: {}", templateId);

        try {
            ColoringTemplate template = coloringTemplateService.getTemplateById(templateId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("template", convertToDTO(template));

            log.info("✅ 색칠공부 템플릿 상세 조회 성공: {}", template.getTitle());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 상세 조회 오류: {}", e.getMessage());
            return ResponseEntity.status(404)
                    .body(Map.of("success", false, "error", "템플릿을 찾을 수 없습니다"));
        }
    }

    // 🎯 동화 ID로 색칠공부 템플릿 조회
    @GetMapping("/templates/story/{storyId}")
    public ResponseEntity<Map<String, Object>> getTemplateByStoryId(
            @PathVariable String storyId) {

        log.info("🔍 동화별 색칠공부 템플릿 조회 - StoryId: {}", storyId);

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
            log.error("❌ 동화별 색칠공부 템플릿 조회 오류: {}", e.getMessage());
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

        log.info("🔍 색칠공부 템플릿 검색 - 키워드: {}", keyword);

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

            log.info("✅ 색칠공부 템플릿 검색 완료 - {}개 발견", templateList.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 검색 오류: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "검색 실패"));
        }
    }

    // 🎯 색칠 완성작 저장 (Base64 이미지 받아서 처리) - 수정됨
    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveColoredImage(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {

        log.info("🎨 색칠 완성작 저장 요청");

        try {
            String username;
            if (authentication != null && authentication.isAuthenticated()) {
                username = authentication.getName();
                log.info("✅ 인증된 사용자: {}", username);
            } else {
                log.error("❌ 인증 실패");
                return ResponseEntity.status(401).body(Map.of(
                        "success", false,
                        "error", "사용자 인증이 필요합니다"
                ));
            }

            // 요청 데이터 추출
            String originalImageUrl = (String) request.get("originalImageUrl");
            String completedImageBase64 = (String) request.get("completedImageBase64");
            String storyTitle = (String) request.get("storyTitle");

            log.info("🎨 원본 이미지: {}", originalImageUrl);
            log.info("🎨 Base64 이미지 길이: {}",
                    (completedImageBase64 != null ? completedImageBase64.length() : "null"));

            if (originalImageUrl == null || completedImageBase64 == null) {
                return ResponseEntity.status(400).body(Map.of(
                        "success", false,
                        "error", "필수 파라미터가 누락되었습니다."
                ));
            }

            // 🎯 색칠 완성작 저장 처리
            String savedImageUrl = saveBase64ImageToStorage(completedImageBase64, username);

            // 🎯 DB에 색칠 완성작 정보 저장
            ColoringWork coloringWork = ColoringWork.builder()
                    .username(username)
                    .originalImageUrl(originalImageUrl)
                    .completedImageUrl(savedImageUrl)
                    .storyTitle(storyTitle != null ? storyTitle : "색칠 완성작")
                    .build();

            ColoringWork saved = coloringWorkRepository.save(coloringWork);
            log.info("✅ DB에 색칠 완성작 저장 완료: {}", saved.getId());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠 완성작이 갤러리에 저장되었습니다!");
            response.put("savedImageUrl", savedImageUrl);
            response.put("coloringWorkId", saved.getId());
            response.put("savedAt", java.time.LocalDateTime.now().toString());

            log.info("✅ 색칠 완성작 저장 완료 - URL: {}", savedImageUrl);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠 완성작 저장 오류: {}", e.getMessage());
            e.printStackTrace();

            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "저장 실패: " + e.getMessage()
            ));
        }
    }

    // 🎯 개선된 색칠 완성작 저장 (MultipartFile 방식) - 수정됨
    @PostMapping("/save-coloring-work")
    public ResponseEntity<?> saveColoringWork(
            @RequestParam("storyId") String storyId,
            @RequestParam(value = "originalImageUrl", required = false) String originalImageUrl,
            @RequestParam("coloredImage") MultipartFile coloredImage,
            Authentication authentication) {

        try {
            String username = authentication.getName();
            log.info("🎨 색칠 완성작 저장 요청 - StoryId: {}, User: {}", storyId, username);

            // 1. 템플릿 조회 (없으면 기본 생성)
            ColoringTemplate template = coloringTemplateService.getTemplateByStoryId(storyId)
                    .orElseGet(() -> {
                        log.info("🔄 템플릿이 없어서 기본 템플릿 생성 - StoryId: {}", storyId);
                        try {
                            return coloringTemplateService.createColoringTemplate(
                                    storyId,
                                    "색칠 템플릿 " + storyId,
                                    originalImageUrl != null ? originalImageUrl : "",
                                    null
                            );
                        } catch (Exception e) {
                            log.error("템플릿 생성 실패: {}", e.getMessage());
                            throw new RuntimeException("템플릿 생성에 실패했습니다: " + e.getMessage());
                        }
                    });

            // 2. 색칠 완성작 S3 업로드
            String coloredImageUrl = s3Service.uploadColoringWork(coloredImage, username, storyId);

            // 3. ColoringWork 엔티티 생성 및 저장
            ColoringWork coloringWork = ColoringWork.builder()
                    .username(username)
                    .storyTitle(template.getTitle())
                    .originalImageUrl(template.getOriginalImageUrl())
                    .completedImageUrl(coloredImageUrl)
                    .templateId(template.getId())
                    .build();

            ColoringWork savedWork = coloringWorkRepository.save(coloringWork);

            // 4. 응답 데이터 구성
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("coloringWorkId", savedWork.getId());
            response.put("coloredImageUrl", coloredImageUrl);
            response.put("message", "색칠 완성작이 갤러리에 저장되었습니다!");

            log.info("✅ 색칠 완성작 저장 완료 - ID: {}", savedWork.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠 완성작 저장 실패: {}", e.getMessage());

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "색칠 완성작 저장 실패: " + e.getMessage());

            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    // 🎯 Base64 이미지를 저장소에 저장
    private String saveBase64ImageToStorage(String base64Image, String username) {
        try {
            log.info("🔍 Base64 이미지 저장 시작");

            // Base64 디코딩
            byte[] imageBytes = java.util.Base64.getDecoder().decode(base64Image);

            // 파일명 생성
            String fileName = "coloring_" + username + "_" + System.currentTimeMillis() + ".png";

            // 로컬 저장소에 저장
            return saveToLocalStorage(imageBytes, fileName);

        } catch (Exception e) {
            log.error("❌ 이미지 저장 실패: {}", e.getMessage());
            throw new RuntimeException("이미지 저장에 실패했습니다", e);
        }
    }

    // 🏠 로컬 저장소에 저장
    private String saveToLocalStorage(byte[] imageBytes, String fileName) {
        try {
            String uploadDir = "src/main/resources/static/coloring/";
            java.nio.file.Path uploadPath = java.nio.file.Paths.get(uploadDir);

            if (!java.nio.file.Files.exists(uploadPath)) {
                java.nio.file.Files.createDirectories(uploadPath);
            }

            java.nio.file.Path filePath = uploadPath.resolve(fileName);
            try (java.io.FileOutputStream fos = new java.io.FileOutputStream(filePath.toFile())) {
                fos.write(imageBytes);
            }

            log.info("✅ 로컬 저장 완료: {}", fileName);
            return "http://localhost:8080/coloring/" + fileName;

        } catch (Exception e) {
            log.error("❌ 로컬 저장 실패: {}", e.getMessage());
            throw new RuntimeException("로컬 이미지 저장에 실패했습니다", e);
        }
    }

    // 🎯 색칠공부 템플릿 삭제 (새로 추가)
    @DeleteMapping("/templates/{templateId}")
    public ResponseEntity<Map<String, Object>> deleteTemplate(
            @PathVariable Long templateId,
            Authentication authentication) {

        log.info("🗑️ 색칠공부 템플릿 삭제 요청 - ID: {}", templateId);

        try {
            String username = authentication.getName();
            log.info("🔍 요청 사용자: {}", username);

            // 템플릿 삭제
            coloringTemplateService.deleteTemplate(templateId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "템플릿이 삭제되었습니다.");

            log.info("✅ 색칠공부 템플릿 삭제 완료 - ID: {}", templateId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 삭제 실패: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body(Map.of("success", false, "error", "템플릿 삭제 실패: " + e.getMessage()));
        }
    }

    // 🔧 ColoringTemplate을 DTO로 변환
    private Map<String, Object> convertToDTO(ColoringTemplate template) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", template.getId().toString());
        dto.put("title", template.getTitle());
        dto.put("storyId", template.getStoryId());
        dto.put("imageUrl", template.getBlackWhiteImageUrl());
        dto.put("originalImageUrl", template.getOriginalImageUrl());
        dto.put("storyTitle", template.getTitle());
        dto.put("createdAt", template.getCreatedAt().format(
                DateTimeFormatter.ofPattern("yyyy-MM-dd")));

        return dto;
    }

    // ColoringController.java에 추가할 메서드

    /**
     * 🎯 색칠공부 템플릿 생성 API (동화에서 호출) - 새로 추가
     */
    @PostMapping("/create-template")
    public ResponseEntity<Map<String, Object>> createColoringTemplate(
            @RequestBody Map<String, String> request,
            Authentication auth
    ) {
        try {
            String storyId = request.get("storyId");
            String title = request.get("title");
            String originalImageUrl = request.get("originalImageUrl");
            String blackWhiteImageUrl = request.get("blackWhiteImageUrl");

            log.info("🎨 색칠공부 템플릿 생성 요청 - StoryId: {}, Title: {}", storyId, title);
            log.info("🔍 원본 이미지: {}", originalImageUrl);
            log.info("🔍 흑백 이미지: {}", blackWhiteImageUrl);

            // 입력 검증
            if (storyId == null || storyId.trim().isEmpty()) {
                return ResponseEntity.status(400).body(Map.of(
                        "success", false,
                        "error", "storyId는 필수입니다."
                ));
            }

            if (originalImageUrl == null || originalImageUrl.trim().isEmpty()) {
                return ResponseEntity.status(400).body(Map.of(
                        "success", false,
                        "error", "originalImageUrl은 필수입니다."
                ));
            }

            // 🎯 ColoringTemplateService에 템플릿 생성 위임
            ColoringTemplate template = coloringTemplateService.createColoringTemplate(
                    storyId,
                    title != null ? title : "색칠공부 템플릿",
                    originalImageUrl,
                    blackWhiteImageUrl
            );

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠공부 템플릿이 생성되었습니다.");
            response.put("template", Map.of(
                    "id", template.getId(),
                    "title", template.getTitle(),
                    "storyId", template.getStoryId(),
                    "originalImageUrl", template.getOriginalImageUrl(),
                    "blackWhiteImageUrl", template.getBlackWhiteImageUrl() != null ? template.getBlackWhiteImageUrl() : "",
                    "createdAt", template.getCreatedAt()
            ));

            log.info("✅ 색칠공부 템플릿 생성 완료 - TemplateId: {}", template.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 생성 실패: {}", e.getMessage());

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            errorResponse.put("message", "색칠공부 템플릿 생성에 실패했습니다.");

            return ResponseEntity.status(500).body(errorResponse);
        }
    }
}