package com.fairytale.fairytale.coloring;

import java.io.File;
import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;
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

    // 🎯 완전히 개선된 convertImageToColoringBook 메서드
    private String convertImageToColoringBook(String originalImageUrl) {
        String localImagePath = null;
        String downloadedImagePath = null;

        try {
            System.out.println("🔍 [ColoringTemplateService] PIL+OpenCV 색칠공부 변환 시작: " + originalImageUrl);

            // 1. 로컬 파일 경로 확보
            if (originalImageUrl.startsWith("http")) {
                System.out.println("🔍 [ColoringTemplateService] URL 감지, 처리 시작");

                // 먼저 로컬에서 찾기 시도
                localImagePath = findLocalImageFile(originalImageUrl);

                if (localImagePath == null) {
                    System.out.println("🌐 [ColoringTemplateService] 로컬 파일 없음, URL 다운로드 진행");
                    downloadedImagePath = downloadImageToLocal(originalImageUrl);
                    if (downloadedImagePath == null) {
                        throw new RuntimeException("이미지 다운로드 실패");
                    }
                    localImagePath = downloadedImagePath;
                } else {
                    System.out.println("✅ [ColoringTemplateService] 로컬 파일 발견: " + localImagePath);
                }
            } else {
                System.out.println("🔍 [ColoringTemplateService] 로컬 파일 경로로 인식: " + originalImageUrl);
                localImagePath = originalImageUrl;

                if (!isValidLocalFile(localImagePath)) {
                    System.out.println("❌ [ColoringTemplateService] 로컬 파일이 존재하지 않음: " + localImagePath);
                    throw new RuntimeException("로컬 이미지 파일을 찾을 수 없습니다: " + localImagePath);
                }
            }

            System.out.println("🔍 [ColoringTemplateService] 최종 사용할 로컬 경로: " + localImagePath);

            // 2. FastAPI 호출
            String fastApiUrl = fastApiServerUrl + "/convert/bwimage";
            System.out.println("🔍 [ColoringTemplateService] FastAPI URL: " + fastApiUrl);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> request = new HashMap<>();
            request.put("text", localImagePath);

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
            System.out.println("🔍 [ColoringTemplateService] FastAPI 전체 응답: " + response.getBody());

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();

                String convertedImagePath = null;
                if (responseBody.containsKey("image_url")) {
                    convertedImagePath = (String) responseBody.get("image_url");
                    System.out.println("🔍 [ColoringTemplateService] image_url 필드에서 추출: " + convertedImagePath);
                } else if (responseBody.containsKey("path")) {
                    convertedImagePath = (String) responseBody.get("path");
                    System.out.println("🔍 [ColoringTemplateService] path 필드에서 추출: " + convertedImagePath);
                }

                if (convertedImagePath != null && !convertedImagePath.isEmpty()) {
                    System.out.println("✅ [ColoringTemplateService] PIL+OpenCV 색칠공부 변환 성공: " + convertedImagePath);

                    // TODO: 여기서 변환된 이미지를 S3에 업로드하고 URL 반환
                    // 현재는 개발 단계이므로 원본 URL 반환
                    return originalImageUrl;
                }
            }

            throw new RuntimeException("FastAPI 응답 오류: " + response.getStatusCode());

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] PIL+OpenCV 변환 실패: " + e.getMessage());
            e.printStackTrace();
            return originalImageUrl; // 실패 시 원본 반환

        } finally {
            // 3. 다운로드한 임시 파일 정리
            if (downloadedImagePath != null) {
                deleteLocalFile(downloadedImagePath);
            }
        }
    }

    // 🔍 로컬 이미지 파일 찾기 (기존과 동일)
    private String findLocalImageFile(String originalUrl) {
        try {
            System.out.println("🔍 [ColoringTemplateService] 로컬 이미지 파일 검색 시작");

            String[] searchPaths = {
                    "./",
                    "../python/",
                    "../",
                    System.getProperty("user.dir"),
                    "/tmp/",
            };

            String[] imageExtensions = {".png", ".jpg", ".jpeg", ".webp"};

            for (String searchPath : searchPaths) {
                System.out.println("🔍 [ColoringTemplateService] 검색 경로: " + searchPath);

                File dir = new File(searchPath);
                if (!dir.exists() || !dir.isDirectory()) {
                    continue;
                }

                File[] files = dir.listFiles();
                if (files == null) continue;

                // 최근 생성된 이미지 파일 찾기 (5분 이내)
                long fiveMinutesAgo = System.currentTimeMillis() - (5 * 60 * 1000);

                for (File file : files) {
                    if (file.isFile() && file.lastModified() > fiveMinutesAgo) {
                        String fileName = file.getName().toLowerCase();

                        boolean isImageFile = false;
                        for (String ext : imageExtensions) {
                            if (fileName.endsWith(ext)) {
                                isImageFile = true;
                                break;
                            }
                        }

                        if (isImageFile &&
                                (fileName.contains("fairy_tale") ||
                                        fileName.contains("image") ||
                                        fileName.contains("story"))) {

                            System.out.println("✅ [ColoringTemplateService] 로컬 이미지 파일 발견: " + file.getAbsolutePath());
                            return file.getAbsolutePath();
                        }
                    }
                }
            }

            System.out.println("❌ [ColoringTemplateService] 로컬 이미지 파일을 찾을 수 없음");
            return null;

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 로컬 파일 검색 실패: " + e.getMessage());
            return null;
        }
    }

    // 🔍 로컬 파일 유효성 검사
    private boolean isValidLocalFile(String filePath) {
        try {
            File file = new File(filePath);

            // 파일 존재 여부 확인
            if (!file.exists()) {
                System.out.println("❌ [ColoringTemplateService] 파일이 존재하지 않음: " + filePath);
                return false;
            }

            // 파일인지 확인 (디렉토리가 아닌)
            if (!file.isFile()) {
                System.out.println("❌ [ColoringTemplateService] 디렉토리임, 파일이 아님: " + filePath);
                return false;
            }

            // 이미지 파일 확장자 확인
            String fileName = file.getName().toLowerCase();
            if (!fileName.endsWith(".png") && !fileName.endsWith(".jpg") &&
                    !fileName.endsWith(".jpeg") && !fileName.endsWith(".webp")) {
                System.out.println("❌ [ColoringTemplateService] 이미지 파일이 아님: " + filePath);
                return false;
            }

            // 파일 크기 확인 (0바이트가 아닌지)
            if (file.length() == 0) {
                System.out.println("❌ [ColoringTemplateService] 빈 파일: " + filePath);
                return false;
            }

            System.out.println("✅ [ColoringTemplateService] 유효한 로컬 파일: " + filePath);
            return true;

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 파일 검증 실패: " + e.getMessage());
            return false;
        }
    }

    // 🌐 URL에서 이미지 다운로드 (개선된 버전)
    private String downloadImageToLocal(String imageUrl) {
        try {
            System.out.println("🌐 [ColoringTemplateService] 이미지 다운로드 시작: " + imageUrl);

            // 임시 디렉토리 생성
            String tempDir = System.getProperty("java.io.tmpdir") + File.separator + "coloring_images";
            Path tempDirPath = Paths.get(tempDir);

            if (!Files.exists(tempDirPath)) {
                Files.createDirectories(tempDirPath);
                System.out.println("📁 [ColoringTemplateService] 임시 디렉토리 생성: " + tempDir);
            }

            // 고유한 파일명 생성
            String fileName = "downloaded_" + System.currentTimeMillis();
            String fileExtension = getFileExtension(imageUrl);
            String localFileName = fileName + fileExtension;
            String localFilePath = tempDir + File.separator + localFileName;

            System.out.println("📁 [ColoringTemplateService] 로컬 저장 경로: " + localFilePath);

            // RestTemplate로 이미지 다운로드 (더 안정적)
            try {
                byte[] imageBytes = restTemplate.getForObject(imageUrl, byte[].class);
                if (imageBytes == null || imageBytes.length == 0) {
                    throw new RuntimeException("다운로드된 이미지가 비어있습니다");
                }

                System.out.println("🔍 [ColoringTemplateService] 다운로드된 이미지 크기: " + imageBytes.length + " bytes");

                // 파일로 저장
                Files.write(Paths.get(localFilePath), imageBytes);

            } catch (Exception e) {
                System.err.println("❌ [ColoringTemplateService] RestTemplate 다운로드 실패, URL 스트림 시도: " + e.getMessage());

                // 백업 방법: URL 스트림 사용
                URL url = new URL(imageUrl);
                try (InputStream inputStream = url.openStream()) {
                    Path targetPath = Paths.get(localFilePath);
                    Files.copy(inputStream, targetPath, StandardCopyOption.REPLACE_EXISTING);
                }
            }

            // 다운로드 결과 검증
            File downloadedFile = new File(localFilePath);
            if (!downloadedFile.exists() || downloadedFile.length() == 0) {
                throw new RuntimeException("다운로드 실패 또는 빈 파일");
            }

            System.out.println("✅ [ColoringTemplateService] 이미지 다운로드 완료: " + localFilePath);
            System.out.println("✅ [ColoringTemplateService] 다운로드된 파일 크기: " + downloadedFile.length() + " bytes");

            return localFilePath;

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 이미지 다운로드 실패: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    // 🔍 URL에서 파일 확장자 추출 (기존 메서드)
    private String getFileExtension(String url) {
        try {
            String fileName = url.substring(url.lastIndexOf('/') + 1);

            if (fileName.contains("?")) {
                fileName = fileName.substring(0, fileName.indexOf("?"));
            }

            if (fileName.contains(".")) {
                String extension = fileName.substring(fileName.lastIndexOf("."));
                System.out.println("🔍 [ColoringTemplateService] 추출된 확장자: " + extension);
                return extension;
            }

            System.out.println("⚠️ [ColoringTemplateService] 확장자를 찾을 수 없음, 기본값 사용: .jpg");
            return ".jpg";

        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 확장자 추출 실패: " + e.getMessage());
            return ".jpg";
        }
    }

    // 🗑️ 파일 삭제 (정리용)
    private void deleteLocalFile(String filePath) {
        try {
            if (filePath != null && !filePath.isEmpty()) {
                Path path = Paths.get(filePath);
                if (Files.exists(path)) {
                    Files.delete(path);
                    System.out.println("🗑️ [ColoringTemplateService] 임시 파일 삭제: " + filePath);
                }
            }
        } catch (Exception e) {
            System.err.println("❌ [ColoringTemplateService] 파일 삭제 실패: " + e.getMessage());
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