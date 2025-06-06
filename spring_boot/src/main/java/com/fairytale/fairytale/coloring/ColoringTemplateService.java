package com.fairytale.fairytale.coloring;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
@RequiredArgsConstructor
public class ColoringTemplateService {
    private final ColoringTemplateRepository coloringTemplateRepository;

    @Value("${fastapi.server.url:http://localhost:8000}")
    private String fastApiServerUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    // 🎨 색칠공부 템플릿 생성 또는 업데이트 (PIL+OpenCV 흑백 변환)
    public ColoringTemplate createColoringTemplate(String storyId, String title,
                                                   String originalImageUrl, String blackWhiteImageUrl) {

        System.out.println("🎨 [ColoringTemplateService] 색칠공부 템플릿 저장 시작 - StoryId: " + storyId);

        // 🎯 흑백 이미지 URL이 없으면 PIL+OpenCV 변환 시도
        if (blackWhiteImageUrl == null || blackWhiteImageUrl.trim().isEmpty() ||
                blackWhiteImageUrl.equals("bw_image.png")) {
            System.out.println("🔄 [ColoringTemplateService] PIL+OpenCV 흑백 변환 시도");
            blackWhiteImageUrl = convertImageToColoringBook(originalImageUrl);
        }

        // 기존 템플릿이 있는지 확인
        Optional<ColoringTemplate> existing = coloringTemplateRepository.findByStoryId(storyId);

        ColoringTemplate template;

        if (existing.isPresent()) {
            // 기존 템플릿 업데이트
            System.out.println("🔄 [ColoringTemplateService] 기존 색칠공부 템플릿 업데이트");
            template = existing.get();
            template.setTitle(title);
            template.setOriginalImageUrl(originalImageUrl);
            template.setBlackWhiteImageUrl(blackWhiteImageUrl);
        } else {
            // 새 템플릿 생성
            System.out.println("🆕 [ColoringTemplateService] 새 색칠공부 템플릿 생성");
            template = ColoringTemplate.builder()
                    .title(title)
                    .storyId(storyId)
                    .originalImageUrl(originalImageUrl)
                    .blackWhiteImageUrl(blackWhiteImageUrl)
                    .build();
        }

        ColoringTemplate savedTemplate = coloringTemplateRepository.save(template);
        System.out.println("✅ [ColoringTemplateService] 색칠공부 템플릿 저장 완료 - ID: " + savedTemplate.getId());

        return savedTemplate;
    }

    // 🎯 개선된 PIL+OpenCV 흑백 변환 (더 상세한 로깅 및 오류 처리)
    private String convertImageToColoringBook(String originalImageUrl) {
        try {
            System.out.println("🔍 [ColoringTemplateService] PIL+OpenCV 색칠공부 변환 시작: " + originalImageUrl);

            String fastApiUrl = fastApiServerUrl + "/convert/bwimage";
            System.out.println("🔍 [ColoringTemplateService] FastAPI URL: " + fastApiUrl);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            // 🎯 Python 코드의 convert_bw_image 함수와 동일한 파라미터
            Map<String, Object> request = new HashMap<>();
            request.put("text", originalImageUrl);  // Python에서 'text' 파라미터 사용
            // save_path는 선택적 파라미터이므로 생략 가능

            System.out.println("🔍 [ColoringTemplateService] FastAPI 요청 데이터: " + request);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);

            System.out.println("🔍 [ColoringTemplateService] HTTP 요청 전송 중...");

            ResponseEntity<Map> response = restTemplate.exchange(
                    fastApiUrl,
                    HttpMethod.POST,
                    entity,
                    Map.class
            );

            System.out.println("🔍 [ColoringTemplateService] FastAPI 응답 상태코드: " + response.getStatusCode());
            System.out.println("🔍 [ColoringTemplateService] FastAPI 응답 헤더: " + response.getHeaders());
            System.out.println("🔍 [ColoringTemplateService] FastAPI 전체 응답: " + response.getBody());

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();

                // 🎯 Python 함수에서 반환 가능한 모든 필드 확인
                String convertedImagePath = null;

                if (responseBody.containsKey("image_url")) {
                    convertedImagePath = (String) responseBody.get("image_url");
                    System.out.println("🔍 [ColoringTemplateService] image_url 필드에서 추출: " + convertedImagePath);
                } else if (responseBody.containsKey("path")) {
                    convertedImagePath = (String) responseBody.get("path");
                    System.out.println("🔍 [ColoringTemplateService] path 필드에서 추출: " + convertedImagePath);
                } else if (responseBody.containsKey("file_path")) {
                    convertedImagePath = (String) responseBody.get("file_path");
                    System.out.println("🔍 [ColoringTemplateService] file_path 필드에서 추출: " + convertedImagePath);
                } else if (responseBody.containsKey("save_path")) {
                    convertedImagePath = (String) responseBody.get("save_path");
                    System.out.println("🔍 [ColoringTemplateService] save_path 필드에서 추출: " + convertedImagePath);
                } else {
                    System.out.println("❌ [ColoringTemplateService] 응답에 이미지 경로 필드가 없음");
                    System.out.println("🔍 [ColoringTemplateService] 사용 가능한 키들: " + responseBody.keySet());
                }

                if (convertedImagePath != null && !convertedImagePath.isEmpty() && !"null".equals(convertedImagePath)) {
                    // 🎯 로컬 파일 경로인 경우 처리
                    if (convertedImagePath.equals("bw_image.png") ||
                            convertedImagePath.contains("/tmp/") ||
                            convertedImagePath.startsWith("/") ||
                            !convertedImagePath.startsWith("http")) {

                        System.out.println("✅ [ColoringTemplateService] Python에서 흑백 이미지 생성 완료");
                        System.out.println("⚠️ [ColoringTemplateService] 로컬 파일 경로이므로 원본 이미지 반환");

                        // 🎯 실제 서비스에서는 여기서 S3 업로드 후 URL 반환
                        // 현재는 개발 단계이므로 원본 반환하여 Flutter에서 처리
                        return originalImageUrl;
                    }

                    // 이미 URL 형태라면 그대로 반환
                    if (convertedImagePath.startsWith("http")) {
                        System.out.println("✅ [ColoringTemplateService] PIL+OpenCV 색칠공부 변환 성공: " + convertedImagePath);
                        return convertedImagePath;
                    }
                }

                System.out.println("⚠️ [ColoringTemplateService] 유효한 이미지 경로를 찾을 수 없음, 원본 사용");
                return originalImageUrl; // Flutter에서 필터링 처리
            } else {
                System.out.println("❌ [ColoringTemplateService] FastAPI 응답 오류");
                System.out.println("❌ [ColoringTemplateService] 상태코드: " + response.getStatusCode());
                throw new RuntimeException("FastAPI 응답 오류: " + response.getStatusCode());
            }

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] PIL+OpenCV 변환 실패: " + e.getMessage());
            System.err.println("❌ [ColoringTemplateService] 오류 상세: " + e.getClass().getSimpleName());
            e.printStackTrace();

            System.err.println("⚠️ [ColoringTemplateService] 원본 이미지 URL을 반환 (Flutter 필터링 사용)");

            // 🎯 실패 시 원본 이미지 URL 반환 (Flutter에서 색칠공부 필터 적용)
            return originalImageUrl;
        }
    }

    // 🎨 모든 색칠공부 템플릿 조회
    public Page<ColoringTemplate> getAllTemplates(Pageable pageable) {
        System.out.println("🔍 [ColoringTemplateService] 색칠공부 템플릿 목록 조회");
        return coloringTemplateRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    // 🎨 특정 템플릿 조회
    public ColoringTemplate getTemplateById(Long templateId) {
        System.out.println("🔍 [ColoringTemplateService] 색칠공부 템플릿 상세 조회 - ID: " + templateId);
        return coloringTemplateRepository.findById(templateId)
                .orElseThrow(() -> new RuntimeException("색칠공부 템플릿을 찾을 수 없습니다: " + templateId));
    }

    // 🎨 동화 ID로 색칠공부 템플릿 조회
    public Optional<ColoringTemplate> getTemplateByStoryId(String storyId) {
        System.out.println("🔍 [ColoringTemplateService] 동화별 색칠공부 템플릿 조회 - StoryId: " + storyId);
        return coloringTemplateRepository.findByStoryId(storyId);
    }

    // 🎨 제목으로 검색
    public Page<ColoringTemplate> searchTemplatesByTitle(String keyword, Pageable pageable) {
        System.out.println("🔍 [ColoringTemplateService] 색칠공부 템플릿 검색 - 키워드: " + keyword);
        return coloringTemplateRepository.findByTitleContainingOrderByCreatedAtDesc(keyword, pageable);
    }

    // 🎨 템플릿 삭제
    public void deleteTemplate(Long templateId) {
        System.out.println("🗑️ [ColoringTemplateService] 색칠공부 템플릿 삭제 - ID: " + templateId);

        ColoringTemplate template = getTemplateById(templateId);
        coloringTemplateRepository.delete(template);

        System.out.println("✅ [ColoringTemplateService] 색칠공부 템플릿 삭제 완료");
    }

    // 🎯 수동 PIL+OpenCV 변환 API (필요시 사용)
    public String manualConvertToColoringBook(String originalImageUrl) {
        System.out.println("🔍 [ColoringTemplateService] 수동 색칠공부 변환 요청: " + originalImageUrl);
        return convertImageToColoringBook(originalImageUrl);
    }

    // 🎯 색칠공부 템플릿 자동 생성 (Story 생성 시 비동기 호출)
    public void createColoringTemplateFromStory(String storyId, String storyTitle, String colorImageUrl) {
        try {
            System.out.println("🎨 [ColoringTemplateService] Story에서 색칠공부 템플릿 자동 생성");
            createColoringTemplate(storyId, storyTitle + " 색칠하기", colorImageUrl, null);
        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 색칠공부 템플릿 자동 생성 실패: " + e.getMessage());
            // 실패해도 Story 생성은 계속 진행
        }
    }

    // 🎯 FastAPI 연결 테스트 메서드 (디버깅용)
    public boolean testFastApiConnection() {
        try {
            System.out.println("🔍 [ColoringTemplateService] FastAPI 연결 테스트 시작: " + fastApiServerUrl);

            String testUrl = fastApiServerUrl + "/health";
            ResponseEntity<String> response = restTemplate.getForEntity(testUrl, String.class);

            System.out.println("✅ [ColoringTemplateService] FastAPI 연결 성공: " + response.getStatusCode());
            System.out.println("✅ [ColoringTemplateService] 응답: " + response.getBody());
            return true;
        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] FastAPI 연결 실패: " + e.getMessage());
            return false;
        }
    }
}