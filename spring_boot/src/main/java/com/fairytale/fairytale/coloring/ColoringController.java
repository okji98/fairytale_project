package com.fairytale.fairytale.coloring;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

// S3 사용 시 주석 해제할 import들
/*
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
*/

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/coloring")
public class ColoringController {
    private final ColoringTemplateService coloringTemplateService;
    private final ColoringWorkRepository coloringWorkRepository;

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

    // 🎯 색칠 완성작 저장 (Base64 이미지 받아서 처리)
    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveColoredImage(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {

        System.out.println("🎨 색칠 완성작 저장 요청");
        System.out.println("🔍 [ColoringController] Authentication: " + authentication);
        System.out.println("🔍 [ColoringController] 인증 여부: " + (authentication != null && authentication.isAuthenticated()));

        try {
            String username;
            if (authentication != null && authentication.isAuthenticated()) {
                username = authentication.getName();
                System.out.println("✅ [ColoringController] 인증된 사용자: " + username);
            } else {
                System.out.println("❌ [ColoringController] 인증 실패 - 401 반환");
                return ResponseEntity.status(401).body(Map.of(
                        "success", false,
                        "error", "사용자 인증이 필요합니다"
                ));
            }

            // 요청 데이터 추출
            String originalImageUrl = (String) request.get("originalImageUrl");
            String completedImageBase64 = (String) request.get("completedImageBase64");
            String timestamp = (String) request.get("timestamp");
            Boolean isBlackAndWhite = (Boolean) request.get("isBlackAndWhite");

            System.out.println("🎨 [ColoringController] 원본 이미지: " + originalImageUrl);
            System.out.println("🎨 [ColoringController] Base64 이미지 길이: " +
                    (completedImageBase64 != null ? completedImageBase64.length() : "null"));

            if (originalImageUrl == null || completedImageBase64 == null) {
                return ResponseEntity.status(400).body(Map.of(
                        "success", false,
                        "error", "필수 파라미터가 누락되었습니다."
                ));
            }

            // 🎯 색칠 완성작 저장 처리
            String savedImageUrl = saveBase64ImageToStorage(completedImageBase64, username);

            // 🎯 DB에 색칠 완성작 정보 저장 (새로 추가)
            ColoringWork coloringWork = ColoringWork.builder()
                    .username(username)
                    .originalImageUrl(originalImageUrl)
                    .completedImageUrl(savedImageUrl)
                    .storyTitle("색칠 완성작") // 또는 실제 동화 제목
                    .build();

            coloringWorkRepository.save(coloringWork);
            System.out.println("✅ [ColoringController] DB에 색칠 완성작 저장 완료: " + coloringWork.getId());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "색칠 완성작이 갤러리에 저장되었습니다!");
            response.put("savedImageUrl", savedImageUrl);
            response.put("savedAt", java.time.LocalDateTime.now().toString());

            System.out.println("✅ 색칠 완성작 저장 완료 - URL: " + savedImageUrl);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.out.println("❌ 색칠 완성작 저장 오류: " + e.getMessage());
            e.printStackTrace();

            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "error", "저장 실패: " + e.getMessage()
            ));
        }
    }

    // 🎯 Base64 이미지를 저장소에 저장 (로컬 + S3 옵션)
    private String saveBase64ImageToStorage(String base64Image, String username) {
        try {
            System.out.println("🔍 [ColoringController] Base64 이미지 저장 시작");

            // Base64 디코딩
            byte[] imageBytes = java.util.Base64.getDecoder().decode(base64Image);

            // 파일명 생성 (로컬/S3 공통)
            String fileName = "coloring_" + username + "_" + System.currentTimeMillis() + ".png";

            // ===========================================
            // 🏠 로컬 저장소 (현재 사용 중)
            // ===========================================
            return saveToLocalStorage(imageBytes, fileName);

            // ===========================================
            // ☁️ S3 저장소 (나중에 사용할 때 주석 해제)
            // ===========================================
            // return saveToS3Storage(imageBytes, fileName);

        } catch (Exception e) {
            System.err.println("❌ [ColoringController] 이미지 저장 실패: " + e.getMessage());
            throw new RuntimeException("이미지 저장에 실패했습니다", e);
        }
    }

    // 🏠 로컬 저장소에 저장
    private String saveToLocalStorage(byte[] imageBytes, String fileName) {
        try {
            // 🎯 static/coloring 폴더에 저장 (웹에서 접근 가능)
            String uploadDir = "src/main/resources/static/coloring/";
            java.nio.file.Path uploadPath = java.nio.file.Paths.get(uploadDir);

            // 디렉토리가 없으면 생성
            if (!java.nio.file.Files.exists(uploadPath)) {
                java.nio.file.Files.createDirectories(uploadPath);
            }

            // 파일 저장
            java.nio.file.Path filePath = uploadPath.resolve(fileName);
            try (java.io.FileOutputStream fos = new java.io.FileOutputStream(filePath.toFile())) {
                fos.write(imageBytes);
            }

            System.out.println("✅ [ColoringController] 로컬 저장 완료: " + fileName);

            // 🎯 로컬 서버에서 접근 가능한 URL 반환
            return "http://localhost:8080/coloring/" + fileName;

        } catch (Exception e) {
            System.err.println("❌ [ColoringController] 로컬 저장 실패: " + e.getMessage());
            throw new RuntimeException("로컬 이미지 저장에 실패했습니다", e);
        }
    }

    // ☁️ S3 저장소에 저장 (나중에 사용)
    /*
    private String saveToS3Storage(byte[] imageBytes, String fileName) {
        try {
            // 🎯 S3 설정 (application.yml에서 설정값 읽어오기)
            String bucketName = "your-fairytale-bucket"; // 실제 버킷명으로 변경
            String s3Region = "ap-northeast-2"; // 서울 리전
            String folderPath = "coloring/" + fileName; // S3 내 경로

            // 🔧 AWS S3 클라이언트 생성
            S3Client s3Client = S3Client.builder()
                    .region(Region.of(s3Region))
                    .credentialsProvider(DefaultCredentialsProvider.create()) // AWS 자격증명
                    .build();

            // 🔧 S3 업로드 요청 생성
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(folderPath)
                    .contentType("image/png")
                    .contentLength((long) imageBytes.length)
                    .build();

            // 🔧 파일 업로드
            PutObjectResponse response = s3Client.putObject(
                    putObjectRequest,
                    RequestBody.fromBytes(imageBytes)
            );

            System.out.println("✅ [ColoringController] S3 업로드 완료: " + fileName);
            System.out.println("✅ [ColoringController] S3 ETag: " + response.eTag());

            // 🎯 S3 공개 URL 반환
            return String.format("https://%s.s3.%s.amazonaws.com/%s",
                    bucketName, s3Region, folderPath);

        } catch (Exception e) {
            System.err.println("❌ [ColoringController] S3 업로드 실패: " + e.getMessage());
            throw new RuntimeException("S3 이미지 업로드에 실패했습니다", e);
        }
    }
    */

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