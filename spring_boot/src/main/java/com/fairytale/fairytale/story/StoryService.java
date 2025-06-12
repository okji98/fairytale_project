package com.fairytale.fairytale.story;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import com.fairytale.fairytale.service.S3Service;
import lombok.extern.slf4j.Slf4j;
import com.fairytale.fairytale.baby.Baby;
import com.fairytale.fairytale.baby.BabyRepository;
import com.fairytale.fairytale.story.dto.*;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fairytale.fairytale.coloring.ColoringTemplateService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.scheduling.annotation.Async;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class StoryService {
    private final S3Service s3Service;
    private final StoryRepository storyRepository;
    private final UsersRepository usersRepository;
    private final BabyRepository babyRepository;

    @Autowired
    private ColoringTemplateService coloringTemplateService;

    @Value("${fastapi.base.url:http://localhost:8000}")
    private String fastApiBaseUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // ====== 스토리 생성 ======
    public Story createStory(StoryCreateRequest request, String username) {
        log.info("🔍 스토리 생성 시작 - Username: {}", username);
        log.info("🔍 받은 요청: theme={}, voice={}, babyId={}",
                request.getTheme(), request.getVoice(), request.getBabyId());

        // 1. 사용자 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> {
                    log.error("❌ 사용자를 찾을 수 없음: {}", username);
                    return new RuntimeException("사용자를 찾을 수 없습니다: " + username);
                });

        log.info("🔍 사용자 조회 성공 - ID: {}", user.getId());

        // 2. Baby 조회
        Baby baby = null;
        String childName = "우리 아이"; // 기본값

        if (request.getBabyId() != null) {
            log.info("🔍 babyId가 제공됨: {}", request.getBabyId());

            try {
                baby = babyRepository.findById(request.getBabyId())
                        .orElseThrow(() -> new RuntimeException("아기 정보를 찾을 수 없습니다."));

                log.info("✅ Baby 엔티티 찾음 - ID: {}", baby.getId());
                log.info("🔍 Baby 정보: ID={}, Name='{}'", baby.getId(), baby.getBabyName());

                if (baby.getBabyName() != null && !baby.getBabyName().trim().isEmpty()) {
                    childName = baby.getBabyName().trim();
                    log.info("✅ 유효한 아기 이름 설정: '{}'", childName);
                } else {
                    log.warn("⚠️ baby.getBabyName()이 null이거나 비어있음, 기본 이름 사용: '{}'", childName);
                }

            } catch (Exception e) {
                log.error("❌ babyId로 Baby 조회 실패: {}", e.getMessage());
            }
        } else {
            log.warn("⚠️ babyId가 null, 기본 이름 사용: '{}'", childName);
        }

        // 3. FastAPI 요청 객체 생성
        FastApiStoryRequest fastApiRequest = new FastApiStoryRequest();
        fastApiRequest.setName(childName);
        fastApiRequest.setTheme(request.getTheme() + " 동화");

        log.info("🚀 FastAPI로 전송할 데이터: name='{}', theme='{}'", childName, fastApiRequest.getTheme());

        // 4. FastAPI 호출
        String url = fastApiBaseUrl + "/generate/story";
        String response = callFastApi(url, fastApiRequest);
        String storyContent = extractStoryFromResponse(response);

        // 5. Story 엔티티 생성 및 저장
        Story story = new Story();
        story.setTheme(request.getTheme());
        story.setVoice(request.getVoice());
        story.setTitle(request.getTheme() + " 동화");
        story.setContent(storyContent);
        story.setUser(user);
        story.setVoiceContent("");
        story.setImage("");

        if (baby != null) {
            story.setBaby(baby);
            log.info("✅ Story에 baby 연결 완료 - baby ID: {}", baby.getId());
        }

        Story saved = storyRepository.save(story);
        log.info("🔍 스토리 저장 완료 - ID: {}", saved.getId());

        return saved;
    }

    // ====== 스토리 삭제 ======
    public void deleteStoryWithVoiceFile(Long storyId, String username) {
        try {
            Story story = getStoryById(storyId, username);

            String voiceUrl = story.getVoiceContent();
            if (voiceUrl != null && !voiceUrl.isEmpty()) {
                String s3Key = s3Service.extractS3KeyFromUrl(voiceUrl);
                if (s3Key != null) {
                    s3Service.deleteFile(s3Key);
                    log.info("✅ S3 음성 파일 삭제 완료: {}", s3Key);
                }
            }

            storyRepository.delete(story);
            log.info("✅ 스토리 삭제 완료: {}", storyId);

        } catch (Exception e) {
            log.error("❌ 스토리 삭제 실패: {}", e.getMessage());
            throw new RuntimeException("스토리 삭제 실패", e);
        }
    }

    // ====== 스토리 조회 ======
    public Story getStoryById(Long id, String username) {
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return storyRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));
    }

    // ====== 기존 스토리 색칠공부 템플릿 생성 ======
    public void createColoringTemplateForExistingStory(Long storyId) {
        try {
            Story story = storyRepository.findById(storyId)
                    .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

            if (story.getImage() != null && !story.getImage().isEmpty()) {
                log.info("🎨 기존 스토리의 색칠공부 템플릿 수동 생성 - StoryId: {}", storyId);

                coloringTemplateService.createColoringTemplate(
                        story.getId().toString(),
                        story.getTitle() + " 색칠하기",
                        story.getImage(),
                        null
                );

                log.info("✅ 기존 스토리의 색칠공부 템플릿 생성 완료");
            } else {
                log.warn("⚠️ 스토리에 이미지가 없어서 색칠공부 템플릿을 생성할 수 없습니다.");
            }
        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 수동 생성 실패: {}", e.getMessage());
            throw new RuntimeException("색칠공부 템플릿 생성 실패", e);
        }
    }

    // ====== 이미지 생성 ======
    public Story createImage(ImageRequest request) {
        log.info("🔍 이미지 생성 요청 - StoryId: {}", request.getStoryId());

        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        log.info("✅ 스토리 조회 성공 - Title: {}", story.getTitle());
        log.info("🔍 스토리 내용 길이: {}자", story.getContent().length());

        Map<String, Object> fastApiRequest = new HashMap<>();
        fastApiRequest.put("text", story.getContent());

        String imageUrl = fastApiBaseUrl + "/generate/image";
        boolean isRealImageGenerated = false;

        try {
            String fastApiResponse = callFastApi(imageUrl, fastApiRequest);
            String localImagePath = extractImagePathFromResponse(fastApiResponse);

            log.info("🎯 로컬 이미지 생성 완료: {}", localImagePath);

            if (localImagePath == null || localImagePath.trim().isEmpty() || "null".equals(localImagePath)) {
                log.warn("❌ FastAPI에서 null 이미지 경로 반환");
                throw new RuntimeException("이미지 생성 실패");
            }

            String s3ImageUrl;
            try {
                s3ImageUrl = processLocalImageWithS3(localImagePath, story.getId());
                log.info("✅ S3 이미지 업로드 완료: {}", s3ImageUrl);
                isRealImageGenerated = true;
            } catch (Exception e) {
                log.error("❌ S3 이미지 업로드 실패: {}", e.getMessage());
                s3ImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
                isRealImageGenerated = false;
            }

            story.setImage(s3ImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("✅ 이미지 저장 완료");

            if (isRealImageGenerated) {
                log.info("🎨 실제 이미지로 색칠공부 템플릿 생성 시작");
                createColoringTemplateAsync(savedStory, s3ImageUrl);
            } else {
                log.info("⚠️ 더미 이미지이므로 색칠공부 템플릿 생성 건너뜀");
            }

            return savedStory;

        } catch (Exception e) {
            log.error("❌ 이미지 생성 실패: {}", e.getMessage());

            String dummyImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
            story.setImage(dummyImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("🔄 더미 이미지로 저장 완료: {}", dummyImageUrl);
            log.info("⚠️ 더미 이미지이므로 색칠공부 템플릿 생성 건너뜀");

            return savedStory;
        }
    }

    // ====== 음성 생성 ======
    public Story createVoice(VoiceRequest request) {
        log.info("🔍 음성 생성 시작 - StoryId: {}", request.getStoryId());

        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        log.info("🔍 스토리 조회 성공 - Content 길이: {}", story.getContent().length());

        FastApiVoiceRequest fastApiRequest = new FastApiVoiceRequest();
        fastApiRequest.setText(story.getContent());
        fastApiRequest.setVoice(request.getVoice() != null ? request.getVoice() : "alloy");
        fastApiRequest.setSpeed(1.0);

        log.info("🔍 FastAPI 음성 요청: text 길이 = {}, voice = {}",
                fastApiRequest.getText().length(), fastApiRequest.getVoice());

        String url = fastApiBaseUrl + "/generate/voice";
        String fastApiResponse = callFastApi(url, fastApiRequest);

        String voiceUrl = processBase64VoiceWithS3(fastApiResponse, story.getId());
        log.info("🔍 S3 처리된 음성 URL: {}", voiceUrl);

        story.setVoiceContent(voiceUrl);
        return storyRepository.save(story);
    }

    // ====== 흑백 변환 ======
    public ResponseEntity<String> convertToBlackWhite(Map<String, String> request) {
        try {
            String imageUrl = request.get("text");
            log.info("🔍 PIL+OpenCV 흑백 변환 요청: {}", imageUrl);

            if (imageUrl == null || imageUrl.trim().isEmpty() || "null".equals(imageUrl)) {
                log.warn("❌ 이미지 URL이 null이거나 비어있음: {}", imageUrl);

                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("image_url", null);
                errorResponse.put("error", "이미지 URL이 null입니다.");
                errorResponse.put("conversion_method", "Flutter_Filter");

                String errorJson = objectMapper.writeValueAsString(errorResponse);
                return ResponseEntity.ok(errorJson);
            }

            String url = fastApiBaseUrl + "/convert/bwimage";
            String response = callFastApi(url, request);

            log.info("🔍 FastAPI PIL+OpenCV 변환 응답: {}", response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("❌ PIL+OpenCV 변환 실패: {}", e.getMessage());

            Map<String, Object> fallbackResponse = new HashMap<>();
            fallbackResponse.put("image_url", request.get("text"));
            fallbackResponse.put("conversion_method", "Flutter_Filter");
            fallbackResponse.put("message", "PIL+OpenCV 변환 실패로 Flutter에서 필터링 처리됩니다.");

            try {
                String fallbackJson = objectMapper.writeValueAsString(fallbackResponse);
                return ResponseEntity.ok(fallbackJson);
            } catch (Exception jsonError) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("{\"error\": \"" + e.getMessage() + "\"}");
            }
        }
    }

    public String convertToBlackWhiteAndUpload(String colorImageUrl) {
        try {
            log.info("🎨 흑백 변환 및 S3 업로드 시작: {}", colorImageUrl);

            if (colorImageUrl == null || colorImageUrl.isEmpty()) {
                log.warn("❌ 컬러 이미지 URL이 비어있음");
                return null;
            }

            if (isS3Url(colorImageUrl)) {
                log.info("🎯 S3 URL 감지, 직접 처리");
                return processS3ImageForBlackWhite(colorImageUrl);
            } else {
                log.info("🎯 일반 URL, FastAPI 흑백 변환 사용");
                return processImageWithFastAPI(colorImageUrl);
            }

        } catch (Exception e) {
            log.error("❌ 흑백 변환 처리 실패: {}", e.getMessage());
            return colorImageUrl;
        }
    }

    // ====== FastAPI 호출 및 응답 파싱 ======
    private String callFastApi(String url, Object request) {
        try {
            log.info("🔍 FastAPI 호출 시작");
            log.info("🔍 URL: {}", url);
            log.info("🔍 요청 객체 타입: {}", request.getClass().getSimpleName());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            String jsonRequest = objectMapper.writeValueAsString(request);
            log.debug("🔍 FastAPI 전송 JSON: {}", jsonRequest);

            HttpEntity<String> entity = new HttpEntity<>(jsonRequest, headers);

            log.info("🔍 HTTP 요청 전송 중...");

            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            log.info("🔍 FastAPI 응답 상태코드: {}", response.getStatusCode());
            log.debug("🔍 FastAPI 응답 헤더: {}", response.getHeaders());
            log.debug("🔍 FastAPI 응답 본문: {}", response.getBody());

            if (response.getStatusCode().is2xxSuccessful()) {
                return response.getBody();
            } else {
                throw new RuntimeException("FastAPI 호출 실패. 상태코드: " + response.getStatusCode());
            }

        } catch (Exception e) {
            log.error("❌ FastAPI 호출 실패: {}", e.getMessage());
            throw new RuntimeException("FastAPI 호출 실패: " + e.getMessage(), e);
        }
    }

    private String extractStoryFromResponse(String response) {
        try {
            JsonNode jsonNode = objectMapper.readTree(response);
            return jsonNode.get("story").asText();
        } catch (Exception e) {
            return response;
        }
    }

    private String extractImagePathFromResponse(String response) {
        try {
            log.info("🔍 이미지 경로 파싱 시작");
            log.info("🔍 FastAPI 응답 원문: {}", response);

            JsonNode jsonNode = objectMapper.readTree(response);
            log.info("🔍 JSON 파싱 성공");

            String[] possibleFields = {"image_path", "image_url", "file_path", "path", "save_path"};

            for (String field : possibleFields) {
                if (jsonNode.has(field)) {
                    String imagePath = jsonNode.get(field).asText();
                    log.info("🔍 {} 필드에서 추출: {}", field, imagePath);

                    if (imagePath != null && !imagePath.trim().isEmpty() && !"null".equals(imagePath)) {
                        if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
                            log.info("✅ HTTP URL 이미지: {}", imagePath);
                            return imagePath;
                        } else {
                            log.info("✅ 로컬 파일 경로: {}", imagePath);
                            return imagePath;
                        }
                    }
                }
            }

            log.error("❌ 유효한 이미지 경로를 찾을 수 없음");
            log.info("🔍 사용 가능한 필드들: {}", jsonNode.fieldNames());
            throw new RuntimeException("응답에서 유효한 이미지 경로를 찾을 수 없습니다.");

        } catch (Exception e) {
            log.error("❌ 이미지 경로 파싱 실패: {}", e.getMessage());
            log.error("❌ 응답 내용: {}", response);
            throw new RuntimeException("이미지 경로 파싱 실패: " + e.getMessage(), e);
        }
    }

    // ====== Private 메서드들 ======
    // 🌐 S3 이미지를 로컬로 다운로드
    private String downloadS3ImageToLocal(String s3Url) {
        try {
            log.info("🌐 S3 이미지 다운로드 시작: {}", s3Url);

            // 임시 디렉토리 생성
            String tempDir = System.getProperty("java.io.tmpdir") + java.io.File.separator + "s3_images";
            Path tempDirPath = Paths.get(tempDir);

            if (!Files.exists(tempDirPath)) {
                Files.createDirectories(tempDirPath);
                log.info("📁 임시 디렉토리 생성: {}", tempDir);
            }

            // 고유한 파일명 생성
            String fileName = "s3_downloaded_" + System.currentTimeMillis();
            String fileExtension = extractFileExtensionFromUrl(s3Url);
            String localFileName = fileName + fileExtension;
            String localFilePath = tempDir + java.io.File.separator + localFileName;

            log.info("📁 로컬 저장 경로: {}", localFilePath);

            // RestTemplate로 S3 이미지 다운로드
            byte[] imageBytes = restTemplate.getForObject(s3Url, byte[].class);
            if (imageBytes == null || imageBytes.length == 0) {
                throw new RuntimeException("다운로드된 S3 이미지가 비어있습니다");
            }

            log.info("🔍 다운로드된 이미지 크기: {} bytes", imageBytes.length);

            // 파일로 저장
            Files.write(Paths.get(localFilePath), imageBytes);

            // 다운로드 결과 검증
            java.io.File downloadedFile = new java.io.File(localFilePath);
            if (!downloadedFile.exists() || downloadedFile.length() == 0) {
                throw new RuntimeException("S3 다운로드 실패 또는 빈 파일");
            }

            log.info("✅ S3 이미지 다운로드 완료: {}", localFilePath);
            log.info("✅ 다운로드된 파일 크기: {} bytes", downloadedFile.length());

            return localFilePath;

        } catch (Exception e) {
            log.error("❌ S3 이미지 다운로드 실패: {}", e.getMessage());
            return null;
        }
    }

    // 🔍 URL에서 파일 확장자 추출
    private String extractFileExtensionFromUrl(String url) {
        try {
            String fileName = url.substring(url.lastIndexOf('/') + 1);

            if (fileName.contains("?")) {
                fileName = fileName.substring(0, fileName.indexOf("?"));
            }

            if (fileName.contains(".")) {
                String extension = fileName.substring(fileName.lastIndexOf("."));
                log.debug("🔍 추출된 확장자: {}", extension);
                return extension;
            }

            log.warn("⚠️ 확장자를 찾을 수 없음, 기본값 사용: .png");
            return ".png";

        } catch (Exception e) {
            log.error("❌ 확장자 추출 실패: {}", e.getMessage());
            return ".png";
        }
    }

    // 🗑️ 로컬 파일 삭제
    private void deleteLocalFile(String filePath) {
        try {
            if (filePath != null && !filePath.isEmpty()) {
                Path path = Paths.get(filePath);
                if (Files.exists(path)) {
                    Files.delete(path);
                    log.info("🗑️ 임시 파일 삭제: {}", filePath);
                }
            }
        } catch (Exception e) {
            log.warn("⚠️ 파일 삭제 실패: {}", e.getMessage());
        }
    }

    // 🔍 JSON 헤더 생성 (재사용)
    private HttpHeaders createJsonHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    private String processLocalImageWithS3(String localImagePath, Long storyId) {
        try {
            if (localImagePath == null || localImagePath.trim().isEmpty()) {
                log.warn("⚠️ 로컬 이미지 경로가 null이거나 비어있음");
                return "";
            }

            java.io.File imageFile = resolveImageFile(localImagePath);

            if (!imageFile.exists()) {
                log.error("❌ 해결된 경로에서도 파일을 찾을 수 없음: {}", imageFile.getAbsolutePath());
                throw new RuntimeException("이미지 파일을 찾을 수 없습니다: " + localImagePath);
            }

            log.info("✅ 이미지 파일 발견: {}", imageFile.getAbsolutePath());

            if (!isValidImagePath(imageFile.getAbsolutePath())) {
                log.error("❌ 유효하지 않은 이미지 파일 경로: {}", imageFile.getAbsolutePath());
                throw new RuntimeException("유효하지 않은 이미지 파일 경로");
            }

            log.info("📤 로컬 이미지 S3 업로드 시작: {}", imageFile.getAbsolutePath());
            String s3Url = s3Service.uploadImageFromLocalFile(imageFile.getAbsolutePath(), "story-images");
            log.info("✅ 로컬 이미지 S3 업로드 완료: {}", s3Url);

            return s3Url;

        } catch (Exception e) {
            log.error("❌ S3 로컬 이미지 처리 실패: {}", e.getMessage());
            throw new RuntimeException("S3 이미지 처리 실패", e);
        }
    }

    private String processS3ImageForBlackWhite(String s3Url) {
        String downloadedImagePath = null;

        try {
            log.info("📤 S3 URL 흑백 변환 시작: {}", s3Url);

            // 1. S3 이미지를 로컬로 다운로드
            downloadedImagePath = downloadS3ImageToLocal(s3Url);
            if (downloadedImagePath == null) {
                log.error("❌ S3 이미지 다운로드 실패");
                return s3Url; // 실패 시 원본 반환
            }

            log.info("✅ S3 이미지 로컬 다운로드 완료: {}", downloadedImagePath);

            // 2. 로컬 파일 경로를 Python에 전달
            Map<String, String> fastApiRequest = new HashMap<>();
            fastApiRequest.put("text", downloadedImagePath);

            log.info("🔍 FastAPI 흑백 변환 요청 (로컬 파일): {}", fastApiRequest);

            ResponseEntity<Map> response = restTemplate.exchange(
                    fastApiBaseUrl + "/convert/bwimage",
                    HttpMethod.POST,
                    new HttpEntity<>(fastApiRequest, createJsonHeaders()),
                    Map.class
            );

            log.info("🔍 FastAPI 응답: {}", response.getBody());

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();

                if (responseBody.containsKey("image_url")) {
                    String bwImagePath = (String) responseBody.get("image_url");
                    log.info("✅ FastAPI 흑백 변환 완료: {}", bwImagePath);

                    // 3. 흑백 이미지를 S3에 업로드
                    if (bwImagePath != null && !bwImagePath.startsWith("http")) {
                        String bwS3Url = uploadBlackWhiteImageToS3(bwImagePath);
                        if (bwS3Url != null) {
                            log.info("✅ 흑백 이미지 S3 업로드 완료: {}", bwS3Url);
                            return bwS3Url;
                        }
                    } else if (bwImagePath != null && bwImagePath.startsWith("http")) {
                        log.info("✅ 흑백 이미지 URL 반환: {}", bwImagePath);
                        return bwImagePath;
                    }
                }
            }

            log.warn("⚠️ FastAPI 흑백 변환 실패, 원본 반환");
            return s3Url;

        } catch (Exception e) {
            log.error("❌ S3 이미지 흑백 변환 실패: {}", e.getMessage());
            return s3Url;

        } finally {
            // 4. 임시 다운로드 파일 정리
            if (downloadedImagePath != null) {
                deleteLocalFile(downloadedImagePath);
            }
        }
    }

    private String processImageWithFastAPI(String imageUrl) {
        try {
            Map<String, String> fastApiRequest = new HashMap<>();
            fastApiRequest.put("text", imageUrl);

            log.info("🔍 FastAPI 흑백 변환 요청: {}", fastApiRequest);

            @SuppressWarnings("unchecked")
            Map<String, String> response = restTemplate.postForObject(
                    fastApiBaseUrl + "/convert/bwimage",
                    fastApiRequest,
                    Map.class
            );

            log.info("🔍 FastAPI 응답: {}", response);

            if (response != null && response.containsKey("image_url")) {
                String convertedUrl = response.get("image_url");
                return processConvertedImageUrl(convertedUrl, imageUrl);
            } else {
                throw new RuntimeException("FastAPI에서 유효한 응답을 받지 못했습니다.");
            }

        } catch (Exception e) {
            log.error("❌ FastAPI 흑백 변환 실패: {}", e.getMessage());
            throw new RuntimeException("FastAPI 흑백 변환 실패", e);
        }
    }

    private String processConvertedImageUrl(String convertedUrl, String originalUrl) {
        log.info("🔍 변환 결과 URL 처리 - 변환됨: {}, 원본: {}", convertedUrl, originalUrl);

        if (convertedUrl.startsWith("http://") ||
                convertedUrl.startsWith("https://") ||
                convertedUrl.startsWith("data:image/")) {
            log.info("✅ 완전한 URL 확인");
            return convertedUrl;
        }

        if (convertedUrl.equals("bw_image.png") ||
                convertedUrl.endsWith(".png") ||
                convertedUrl.endsWith(".jpg")) {
            log.info("🔍 로컬 파일명 감지, S3 업로드 시도: {}", convertedUrl);

            String s3BwUrl = uploadBlackWhiteImageToS3(convertedUrl);
            if (s3BwUrl != null) {
                log.info("✅ 흑백 이미지 S3 업로드 성공: {}", s3BwUrl);
                return s3BwUrl;
            }

            log.warn("⚠️ 흑백 이미지 처리 실패, 원본 이미지 사용");
            return originalUrl;
        }

        log.info("⚠️ 알 수 없는 형식, 원본 이미지 사용");
        return originalUrl;
    }

    private String uploadBlackWhiteImageToS3(String localBwPath) {
        try {
            log.info("📤 흑백 이미지 S3 업로드 시작: {}", localBwPath);

            java.io.File bwFile = resolveImageFile(localBwPath);
            if (!bwFile.exists()) {
                log.error("❌ 흑백 이미지 파일을 찾을 수 없음: {}", bwFile.getAbsolutePath());
                return null;
            }

            if (!isValidImagePath(bwFile.getAbsolutePath())) {
                log.error("❌ 유효하지 않은 흑백 이미지 경로: {}", bwFile.getAbsolutePath());
                return null;
            }

            String s3Url = s3Service.uploadImageFromLocalFile(bwFile.getAbsolutePath(), "bw-images");
            log.info("✅ 흑백 이미지 S3 업로드 완료: {}", s3Url);

            try {
                boolean deleted = bwFile.delete();
                if (deleted) {
                    log.info("🧹 임시 흑백 파일 삭제 완료: {}", bwFile.getName());
                } else {
                    log.warn("⚠️ 임시 흑백 파일 삭제 실패: {}", bwFile.getName());
                }
            } catch (Exception deleteError) {
                log.warn("⚠️ 파일 삭제 중 오류: {}", deleteError.getMessage());
            }

            return s3Url;

        } catch (Exception e) {
            log.error("❌ 흑백 이미지 S3 업로드 실패: {}", e.getMessage());
            return null;
        }
    }

    private String processBase64VoiceWithS3(String fastApiResponse, Long storyId) {
        try {
            log.info("🔍 Base64 음성 처리 시작");

            JsonNode jsonNode = objectMapper.readTree(fastApiResponse);

            if (!jsonNode.has("audio_base64")) {
                throw new RuntimeException("응답에 audio_base64 필드가 없습니다.");
            }

            String audioBase64 = jsonNode.get("audio_base64").asText();
            String voice = jsonNode.has("voice") ? jsonNode.get("voice").asText() : "alloy";

            log.info("🔍 Base64 데이터 길이: {} 문자", audioBase64.length());
            log.info("🔍 음성 타입: {}", voice);

            byte[] audioBytes = java.util.Base64.getDecoder().decode(audioBase64);
            log.info("🔍 디코딩된 오디오 크기: {} bytes", audioBytes.length);

            String tempFileName = "temp_voice_" + storyId + "_" + System.currentTimeMillis() + ".mp3";
            java.io.File tempFile = new java.io.File(tempFileName);

            try (java.io.FileOutputStream fos = new java.io.FileOutputStream(tempFile)) {
                fos.write(audioBytes);
            }

            log.info("📝 임시 파일 저장 완료: {}", tempFile.getAbsolutePath());

            String s3Url = s3Service.uploadAudioFileWithPresignedUrl(tempFile.getAbsolutePath());
            log.info("✅ S3 업로드 완료: {}", s3Url);

            tempFile.delete();
            log.info("🧹 임시 파일 삭제 완료");

            return s3Url;

        } catch (Exception e) {
            log.error("❌ Base64 음성 처리 실패: {}", e.getMessage());
            throw new RuntimeException("Base64 음성 처리 실패: " + e.getMessage(), e);
        }
    }

    private java.io.File resolveImageFile(String imagePath) {
        log.info("🔍 이미지 파일 경로 해결 시작: {}", imagePath);

        java.io.File file = new java.io.File(imagePath);
        if (file.isAbsolute() && file.exists()) {
            log.info("✅ 절대경로로 파일 발견: {}", file.getAbsolutePath());
            return file;
        }

        String[] searchPaths = {
                "./",
                "../python/",
                System.getProperty("user.dir"),
                "/tmp/",
        };

        for (String searchPath : searchPaths) {
            java.io.File searchFile = new java.io.File(searchPath, imagePath.startsWith("./") ? imagePath.substring(2) : imagePath);
            log.info("🔍 검색 시도: {}", searchFile.getAbsolutePath());

            if (searchFile.exists()) {
                log.info("✅ 파일 발견: {}", searchFile.getAbsolutePath());
                return searchFile;
            }
        }

        String fileName = new java.io.File(imagePath).getName();
        for (String searchPath : searchPaths) {
            java.io.File searchFile = new java.io.File(searchPath, fileName);
            log.info("🔍 파일명으로 검색 시도: {}", searchFile.getAbsolutePath());

            if (searchFile.exists()) {
                log.info("✅ 파일명으로 파일 발견: {}", searchFile.getAbsolutePath());
                return searchFile;
            }
        }

        log.warn("❌ 모든 경로에서 파일을 찾을 수 없음");
        return file;
    }

    private boolean isValidImagePath(String filePath) {
        try {
            log.info("🔍 이미지 경로 보안 검사: {}", filePath);

            java.io.File file = new java.io.File(filePath);
            String canonicalPath = file.getCanonicalPath();
            log.info("🔍 정규화된 경로: {}", canonicalPath);

            String[] allowedPatterns = {
                    "/tmp/", "/var/folders/", "/temp/", "temp", ".png", ".jpg", ".jpeg",
                    "fairytale", "python", "spring_boot"
            };

            boolean patternMatched = false;
            for (String pattern : allowedPatterns) {
                if (canonicalPath.contains(pattern)) {
                    patternMatched = true;
                    break;
                }
            }

            if (!patternMatched) {
                log.error("❌ 허용되지 않은 디렉토리: {}", canonicalPath);
                return false;
            }

            String[] dangerousPaths = {
                    "/etc/", "/bin/", "/usr/bin/", "/System/", "C:\\Windows\\", "C:\\Program Files\\", "/root/", "/home/"
            };

            String lowerCanonicalPath = canonicalPath.toLowerCase();
            for (String dangerousPath : dangerousPaths) {
                if (lowerCanonicalPath.startsWith(dangerousPath.toLowerCase())) {
                    log.error("❌ 위험한 시스템 경로 접근 차단: {}", canonicalPath);
                    return false;
                }
            }

            String lowerPath = canonicalPath.toLowerCase();
            if (!lowerPath.endsWith(".png") && !lowerPath.endsWith(".jpg") &&
                    !lowerPath.endsWith(".jpeg") && !lowerPath.endsWith(".webp")) {
                log.error("❌ 허용되지 않은 파일 확장자: {}", canonicalPath);
                return false;
            }

            log.info("✅ 이미지 경로 보안 검사 통과: {}", canonicalPath);
            return true;

        } catch (Exception e) {
            log.error("❌ 이미지 경로 검사 중 오류: {}", e.getMessage());
            return false;
        }
    }

    private boolean isS3Url(String url) {
        return url != null && (url.contains("amazonaws.com") || url.contains("cloudfront.net"));
    }

    private boolean isValidImageUrlForColoring(String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return false;
        }

        if (imageUrl.contains("picsum.photos")) {
            log.info("🚫 Picsum 더미 이미지는 색칠공부에서 제외: {}", imageUrl);
            return false;
        }

        String lowerUrl = imageUrl.toLowerCase();
        String[] dummyServices = {
                "placeholder.com", "via.placeholder.com", "dummyimage.com", "fakeimg.pl", "lorempixel.com"
        };

        for (String dummyService : dummyServices) {
            if (lowerUrl.contains(dummyService)) {
                log.info("🚫 더미 이미지 서비스 감지, 색칠공부에서 제외: {}", imageUrl);
                return false;
            }
        }

        if (lowerUrl.contains("amazonaws.com") ||
                lowerUrl.contains("cloudfront.net") ||
                (lowerUrl.startsWith("http") &&
                        (lowerUrl.contains(".jpg") || lowerUrl.contains(".png") ||
                                lowerUrl.contains(".jpeg") || lowerUrl.contains(".webp")))) {
            return true;
        }

        log.warn("⚠️ 알 수 없는 이미지 URL 형식: {}", imageUrl);
        return false;
    }

    @Async
    public CompletableFuture<Void> createColoringTemplateAsync(Story story, String colorImageUrl) {
        try {
            log.info("🎨 색칠공부 템플릿 비동기 생성 시작 - StoryId: {}", story.getId());

            if (!isValidImageUrlForColoring(colorImageUrl)) {
                log.warn("⚠️ 색칠공부에 적합하지 않은 이미지 URL: {}", colorImageUrl);
                return CompletableFuture.completedFuture(null);
            }

            coloringTemplateService.createColoringTemplate(
                    story.getId().toString(),
                    story.getTitle() + " 색칠하기",
                    colorImageUrl,
                    null
            );

            log.info("✅ 색칠공부 템플릿 비동기 생성 완료");
        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 생성 실패: {}", e.getMessage());
        }
        return CompletableFuture.completedFuture(null);
    }

    // ====== Utility 메서드들 ======
    public byte[] downloadVoiceFromS3(String s3Url) {
        try {
            String s3Key = s3Service.extractS3KeyFromUrl(s3Url);
            if (s3Key != null) {
                return s3Service.downloadAudioFile(s3Key);
            }
            throw new RuntimeException("S3 키를 추출할 수 없습니다: " + s3Url);
        } catch (Exception e) {
            log.error("❌ S3 음성 파일 다운로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 음성 파일 다운로드 실패", e);
        }
    }

    public String generateTemporaryVoiceUrl(Long storyId, int expirationMinutes) {
        try {
            Story story = storyRepository.findById(storyId)
                    .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

            String voiceUrl = story.getVoiceContent();
            if (voiceUrl == null || voiceUrl.isEmpty()) {
                throw new RuntimeException("음성 파일이 없습니다.");
            }

            String s3Key = s3Service.extractS3KeyFromUrl(voiceUrl);
            if (s3Key != null) {
                return s3Service.generateAudioPresignedUrl(s3Key, expirationMinutes);
            }

            return voiceUrl;

        } catch (Exception e) {
            log.error("❌ 임시 URL 생성 실패: {}", e.getMessage());
            throw new RuntimeException("임시 URL 생성 실패", e);
        }
    }
}