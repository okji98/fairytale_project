package com.fairytale.fairytale.story;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import com.fairytale.fairytale.coloring.ColoringTemplate;
import com.fairytale.fairytale.coloring.ColoringTemplateRepository;
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
import org.springframework.context.annotation.Lazy;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.scheduling.annotation.Async;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
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

    // ✅ @Lazy로 순환 의존성 해결!
    @Lazy
    @Autowired
    private ColoringTemplateService coloringTemplateService;

    @Value("${fastapi.base.url:http://localhost:8000}")
    private String fastApiBaseUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private ColoringTemplateRepository coloringTemplateRepository;

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
//                isRealImageGenerated = true;
            } catch (Exception e) {
                log.error("❌ S3 이미지 업로드 실패: {}", e.getMessage());
                s3ImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
//                isRealImageGenerated = false;
            }

            story.setImage(s3ImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("✅ 이미지 저장 완료");

//            if (isRealImageGenerated) {
//                log.info("🎨 실제 이미지로 색칠공부 템플릿 생성 시작");
//                createColoringTemplateAsync(savedStory, s3ImageUrl);
//            } else {
//                log.info("⚠️ 더미 이미지이므로 색칠공부 템플릿 생성 건너뜀");
//            }

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

    // ====== ColoringTemplateService용 공개 메서드 ======

    // ====== 색칠공부 템플릿 비동기 생성 (흑백 변환 완전 제거) ======
    @Async
    public void createColoringTemplateAsync(String storyId, String title, String imageUrl) {
        try {
            log.info("🎨 [StoryService] 색칠공부 템플릿 생성 요청 - StoryId: {}", storyId);

            // 🔥 흑백 변환 없이 ColoringTemplateService에만 위임
            coloringTemplateService.createColoringTemplate(storyId, title, imageUrl, null);

            log.info("✅ 색칠공부 템플릿 생성 완료 (흑백 변환은 필요시 수행)");

        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 비동기 생성 실패: {}", e.getMessage());
        }
    }

    // ====== 흑백변환 버튼 전용 메서드 ======
    public String processImageToBlackWhite(String originalImageUrl) {
        try {
            log.info("🔍 흑백변환 버튼 요청: {}", originalImageUrl);

            // 1. 기존 흑백 이미지 먼저 찾기
            String existingBwUrl = findExistingBlackWhiteImageInS3(originalImageUrl);
            if (existingBwUrl != null) {
                log.info("✅ 기존 흑백 이미지 발견, 즉시 반환: {}", existingBwUrl);
                return existingBwUrl;
            }

            // 2. 없으면 새로 변환
            log.info("📝 기존 흑백 이미지 없음, 새로 변환 시작");
            return performActualBlackWhiteConversion(originalImageUrl);

        } catch (Exception e) {
            log.error("❌ 흑백 변환 처리 실패: {}", e.getMessage());
            return originalImageUrl;
        }
    }

    // ====== 실제 흑백 변환 수행 ======
    private String performActualBlackWhiteConversion(String originalImageUrl) {
        String downloadedImagePath = null;

        try {
            log.info("📤 흑백 변환 시작: {}", originalImageUrl);

            // S3 URL인 경우만 처리
            if (!isS3Url(originalImageUrl)) {
                log.warn("⚠️ S3 URL이 아님, 원본 반환: {}", originalImageUrl);
                return originalImageUrl;
            }

            // S3 연결 상태 확인
            if (!s3Service.isS3Available()) {
                log.warn("⚠️ S3 연결 불가, 원본 URL 반환");
                return originalImageUrl;
            }

            // S3 이미지를 로컬로 다운로드
            downloadedImagePath = downloadS3ImageToLocal(originalImageUrl);
            if (downloadedImagePath == null) {
                log.error("❌ S3 이미지 다운로드 실패");
                return originalImageUrl;
            }

            log.info("✅ S3 이미지 로컬 다운로드 완료: {}", downloadedImagePath);

            // FastAPI로 흑백 변환
            Map<String, String> fastApiRequest = new HashMap<>();
            fastApiRequest.put("text", downloadedImagePath);

            log.info("🔍 FastAPI 흑백 변환 요청: {}", fastApiRequest);

            ResponseEntity<Map> response = restTemplate.exchange(
                    fastApiBaseUrl + "/convert/bwimage",
                    HttpMethod.POST,
                    new HttpEntity<>(fastApiRequest, createJsonHeaders()),
                    Map.class
            );

            log.info("🔍 FastAPI 응답: {}", response.getBody());

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();

                // 🔥 다양한 응답 형식 처리
                String bwImageResult = null;

                // 1. image_url 필드 확인 (기존 방식)
                if (responseBody.containsKey("image_url")) {
                    bwImageResult = (String) responseBody.get("image_url");
                    log.info("✅ image_url 필드에서 추출: {}", bwImageResult);
                }
                // 2. image 필드 확인 (Base64 데이터)
                else if (responseBody.containsKey("image")) {
                    String base64Image = (String) responseBody.get("image");
                    log.info("✅ Base64 이미지 데이터 수신: {}...", base64Image.substring(0, Math.min(50, base64Image.length())));

                    // Base64를 파일로 저장
                    bwImageResult = saveBase64ToFile(base64Image, "bw_image.png");
                }

                if (bwImageResult != null && !bwImageResult.isEmpty()) {
                    log.info("✅ FastAPI 흑백 변환 완료: {}", bwImageResult);

                    // 변환된 흑백 이미지를 S3에 업로드
                    String bwS3Url = uploadBlackWhiteImageToS3(bwImageResult, originalImageUrl);
                    if (bwS3Url != null) {
                        log.info("✅ 흑백 이미지 S3 업로드 완료: {}", bwS3Url);
                        return bwS3Url;
                    }
                }
            }

            log.warn("⚠️ 흑백 변환 실패, 원본 반환");
            return originalImageUrl;

        } catch (Exception e) {
            log.error("❌ 흑백 변환 실패: {}", e.getMessage());
            return originalImageUrl;

        } finally {
            // 임시 다운로드 파일 정리
            if (downloadedImagePath != null) {
                deleteLocalFile(downloadedImagePath);
            }
        }
    }

    // Base64 이미지를 파일로 저장하는 메서드
    private String saveBase64ToFile(String base64Image, String fileName) {
        try {
            log.info("📄 Base64 이미지를 파일로 저장: {}", fileName);

            // Base64 디코딩
            byte[] imageBytes = java.util.Base64.getDecoder().decode(base64Image);

            // 임시 파일 경로 생성
            String tempDir = System.getProperty("java.io.tmpdir");
            String filePath = tempDir + java.io.File.separator + fileName;

            // 파일로 저장
            java.nio.file.Files.write(java.nio.file.Paths.get(filePath), imageBytes);

            log.info("✅ Base64 이미지 파일 저장 완료: {}", filePath);
            return filePath;

        } catch (Exception e) {
            log.error("❌ Base64 이미지 저장 실패: {}", e.getMessage());
            return null;
        }
    }

    // ====== 흑백 이미지 S3 업로드 ======
    private String uploadBlackWhiteImageToS3(String bwImagePath, String originalS3Url) {
        try {
            log.info("📤 흑백 이미지 S3 처리 시작: {}", bwImagePath);

            // 로컬 파일 존재 확인
            java.io.File bwFile = resolveImageFile(bwImagePath);
            if (!bwFile.exists()) {
                log.error("❌ 흑백 이미지 파일을 찾을 수 없음: {}", bwFile.getAbsolutePath());
                return null;
            }

            log.info("✅ 흑백 이미지 파일 확인: {} ({} bytes)", bwFile.getAbsolutePath(), bwFile.length());

            // 원본 기반 S3 키 생성
            String targetS3Key = generateBlackWhiteS3KeyFromOriginal(originalS3Url);
            if (targetS3Key == null) {
                log.warn("⚠️ 원본 기반 S3 키 생성 실패, 기본 방식 사용");
                return s3Service.uploadImageFromLocalFile(bwFile.getAbsolutePath(), "bw-images");
            }

            // 커스텀 키로 S3 업로드
            String bwS3Url = s3Service.uploadImageWithCustomKey(bwFile.getAbsolutePath(), targetS3Key);
            log.info("✅ 원본 기반 흑백 이미지 S3 업로드 성공: {}", bwS3Url);

            // S3 업로드 성공 시 로컬 파일 삭제
            try {
                boolean deleted = bwFile.delete();
                if (deleted) {
                    log.info("🧹 S3 업로드 성공으로 흑백 로컬 파일 삭제: {}", bwFile.getName());
                } else {
                    log.warn("⚠️ 흑백 로컬 파일 삭제 실패 (업로드는 성공): {}", bwFile.getName());
                }
            } catch (Exception deleteError) {
                log.warn("⚠️ 흑백 파일 삭제 중 오류 (업로드는 성공): {}", deleteError.getMessage());
            }

            return bwS3Url;

        } catch (Exception e) {
            log.error("❌ 흑백 이미지 S3 처리 실패: {}", e.getMessage());
            return null;
        }
    }

    // ====== 원본 기반 흑백 S3 키 생성 ======
    private String generateBlackWhiteS3KeyFromOriginal(String originalS3Url) {
        try {
            // S3 키 추출: story-images/2025/06/13/image-6cb8f206.png
            String s3Key = s3Service.extractS3KeyFromUrl(originalS3Url);
            if (s3Key == null || !s3Key.contains("story-images/")) {
                return null;
            }

            // 변환: bw-images/2025/06/13/image-6cb8f206.png (bw- 접두사 제거!)
            String bwS3Key = s3Key.replace("story-images/", "bw-images/");

            log.info("🔑 원본 기반 흑백 S3 키 생성: {} → {}", s3Key, bwS3Key);
            return bwS3Key;

        } catch (Exception e) {
            log.error("❌ 원본 기반 S3 키 생성 실패: {}", e.getMessage());
            return null;
        }
    }

    private boolean isS3Url(String url) {
        return url != null && (url.contains("amazonaws.com") || url.contains("cloudfront.net"));
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

    // 📤 지정된 S3 키로 이미지 업로드
    private String uploadImageWithSpecificKey(String localFilePath, String s3Key) {
        try {
            log.info("📤 지정된 키로 S3 업로드: {} → {}", localFilePath, s3Key);

            java.io.File localFile = new java.io.File(localFilePath);
            if (!localFile.exists()) {
                throw new java.io.FileNotFoundException("로컬 파일이 존재하지 않습니다: " + localFilePath);
            }

            // S3Service에 특정 키로 업로드하는 메서드 호출 필요
            // 임시로 기존 방식 사용 (S3Service 수정 필요)
            String s3Url = s3Service.uploadImageFromLocalFile(localFilePath, "bw-images");

            // 🔧 TODO: S3Service에 uploadImageWithSpecificKey 메서드 추가 필요
            // String s3Url = s3Service.uploadImageWithSpecificKey(localFilePath, s3Key);

            return s3Url;

        } catch (Exception e) {
            log.error("❌ 지정된 키로 S3 업로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 업로드 실패", e);
        }
    }

    // 📤 기본 방식으로 업로드 (폴백)
    private String uploadWithDefaultNaming(java.io.File bwFile) {
        try {
            return s3Service.uploadImageFromLocalFile(bwFile.getAbsolutePath(), "bw-images");
        } catch (Exception e) {
            log.error("❌ 기본 방식 업로드 실패: {}", e.getMessage());
            return bwFile.getAbsolutePath();
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

    // 🎯 개선된 processLocalImageWithS3 - 업로드 후 로컬 파일 관리
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

            log.info("✅ 이미지 파일 발견: {} ({} bytes)", imageFile.getAbsolutePath(), imageFile.length());

            if (!isValidImagePath(imageFile.getAbsolutePath())) {
                log.error("❌ 유효하지 않은 이미지 파일 경로: {}", imageFile.getAbsolutePath());
                throw new RuntimeException("유효하지 않은 이미지 파일 경로");
            }

            // S3 연결 상태 확인
            if (!s3Service.isS3Available()) {
                log.warn("⚠️ S3 연결 불가, 로컬 파일 경로 반환: {}", imageFile.getAbsolutePath());
                return imageFile.getAbsolutePath();
            }

            log.info("📤 로컬 이미지 S3 업로드 시작: {}", imageFile.getAbsolutePath());

            try {
                String s3Url = s3Service.uploadImageFromLocalFile(imageFile.getAbsolutePath(), "story-images");
                log.info("✅ 로컬 이미지 S3 업로드 완료: {}", s3Url);

                // S3 업로드 성공 시 로컬 파일 삭제
                try {
                    boolean deleted = imageFile.delete();
                    if (deleted) {
                        log.info("🧹 S3 업로드 성공으로 컬러 로컬 파일 삭제: {}", imageFile.getName());
                    } else {
                        log.warn("⚠️ 컬러 로컬 파일 삭제 실패 (업로드는 성공): {}", imageFile.getName());
                    }
                } catch (Exception deleteError) {
                    log.warn("⚠️ 컬러 파일 삭제 중 오류 (업로드는 성공): {}", deleteError.getMessage());
                }

                return s3Url;

            } catch (Exception uploadError) {
                log.error("❌ S3 업로드 실패, 로컬 파일 유지: {}", uploadError.getMessage());
                log.info("🔄 로컬 파일 경로 반환: {}", imageFile.getAbsolutePath());
                return imageFile.getAbsolutePath();
            }

        } catch (Exception e) {
            log.error("❌ 이미지 처리 실패: {}", e.getMessage());
            throw new RuntimeException("이미지 처리 실패", e);
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

    // 🔍 기존 흑백 이미지 검색 (단순화)
    private String findExistingBlackWhiteImageInS3(String originalS3Url) {
        try {
            String predictedBwUrl = originalS3Url.replace("story-images/", "bw-images/");

            // HEAD 요청으로 존재 여부 확인
            ResponseEntity<String> response = restTemplate.exchange(
                    predictedBwUrl, HttpMethod.HEAD, null, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("✅ 기존 흑백 이미지 확인: {}", predictedBwUrl);
                return predictedBwUrl;
            }
        } catch (Exception e) {
            log.debug("📝 기존 흑백 이미지 없음: {}", e.getMessage());
        }
        return null;
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