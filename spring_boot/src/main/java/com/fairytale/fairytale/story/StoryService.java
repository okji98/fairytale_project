package com.fairytale.fairytale.story;

import com.fairytale.fairytale.service.S3Service;  // S3 서비스 추가
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
    private final Baby baby;

    // 🆕 색칠공부 서비스 추가
    @Autowired
    private ColoringTemplateService coloringTemplateService;

    @Value("${fastapi.base.url:http://localhost:8000}")
    private String fastApiBaseUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // 스토리
    // 🔄 기존 동화 생성 메서드 (수정됨)
    public Story createStory(StoryCreateRequest request, String username) {
        System.out.println("🔍 스토리 생성 시작 - Username: " + username);
        System.out.println("🔍 받은 요청: theme=" + request.getTheme() + ", voice=" + request.getVoice());

        // 1. 사용자 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> {
                    System.out.println("❌ 사용자를 찾을 수 없음: " + username);
                    usersRepository.findAll().forEach(u ->
                            System.out.println("  - 존재하는 사용자: " + u.getUsername()));
                    return new RuntimeException("사용자를 찾을 수 없습니다: " + username);
                });

        System.out.println("🔍 사용자 조회 성공 - ID: " + user.getId());

        // 2. Baby 조회 (babyId가 요청에 있다면)
        Baby baby = null;
        if (request.getBabyId() != null) {
            baby = babyRepository.findById(request.getBabyId())
                    .orElseThrow(() -> new RuntimeException("아기 정보를 찾을 수 없습니다."));
        }

        // 3. FastAPI 요청 객체 생성
        FastApiStoryRequest fastApiRequest = new FastApiStoryRequest();
        if (baby != null) {
            fastApiRequest.setName(baby.getBabyName());  // Baby의 이름 사용
        } else {
            fastApiRequest.setName("기본값");  // 기본값
        }
        fastApiRequest.setTheme(request.getTheme() + " 동화");

        System.out.println("🔍 FastAPI 동화 생성 요청: " + fastApiRequest.getName());

        // 3. FastAPI로 동화 생성 요청
        String url = fastApiBaseUrl + "/generate/story";
        String response = callFastApi(url, fastApiRequest);

        // 4. 응답에서 story 추출
        String storyContent = extractStoryFromResponse(response);

        // 5. Story 엔티티 생성 및 저장
        Story story = new Story();
        story.setTheme(request.getTheme());
        story.setVoice(request.getVoice());
        story.setTitle(request.getTheme() + " 동화");
        story.setContent(storyContent);
        story.setUser(user);
        story.setVoiceContent("");  // 🎯 초기값: 빈 문자열
        story.setImage("");  // 🎯 단일 image 컬럼 사용

        if (baby != null) {
            story.setBaby(baby);  // 💥 빠지면 baby_id가 null로 들어감!
        }

        System.out.println("🔍 스토리 저장 전 - Title: " + story.getTitle());
        Story saved = storyRepository.save(story);
        System.out.println("🔍 스토리 저장 완료 - ID: " + saved.getId());

        return saved;
    }

    // 이미지
    // 🎯 수정된 이미지 생성 메서드 (FastAPI 요청 구조 수정 + 오류 처리 개선)
    public Story createImage(ImageRequest request) {
        log.info("🔍 이미지 생성 요청 - StoryId: {}", request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        log.info("✅ 스토리 조회 성공 - Title: {}", story.getTitle());
        log.info("🔍 스토리 내용 길이: {}자", story.getContent().length());

        // 2. FastAPI 요청 데이터
        Map<String, Object> fastApiRequest = new HashMap<>();
        fastApiRequest.put("text", story.getContent());

        log.info("🔍 FastAPI 이미지 생성 요청 데이터: {}", fastApiRequest);

        // 3. FastAPI로 컬러 이미지 생성
        String imageUrl = fastApiBaseUrl + "/generate/image";

        try {
            String fastApiResponse = callFastApi(imageUrl, fastApiRequest);
            String colorImageUrl = extractImageUrlFromResponse(fastApiResponse);

            log.info("🎯 컬러 이미지 생성 완료: {}", colorImageUrl);

            if (colorImageUrl == null || colorImageUrl.trim().isEmpty() || "null".equals(colorImageUrl)) {
                log.warn("❌ FastAPI에서 null 이미지 URL 반환");
                colorImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
                log.info("🔄 더미 이미지 URL 사용: {}", colorImageUrl);
            }

            // 🆕 4. 이미지를 S3에 업로드 (흑백 변환을 위해)
            String s3ImageUrl;
            try {
                s3ImageUrl = processImageWithS3(colorImageUrl, story.getId());
                log.info("✅ S3 이미지 업로드 완료: {}", s3ImageUrl);
            } catch (Exception e) {
                log.error("❌ S3 이미지 업로드 실패, 원본 URL 사용: {}", e.getMessage());
                s3ImageUrl = colorImageUrl; // 실패시 원본 사용
            }

            // 5. Story에 S3 URL(또는 원본 URL) 저장
            story.setImage(s3ImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("✅ 이미지 저장 완료");

            // 6. 🎨 색칠공부 템플릿 비동기 생성 (S3 URL로 안정적 처리)
            createColoringTemplateAsync(savedStory, s3ImageUrl);

            return savedStory;

        } catch (Exception e) {
            log.error("❌ 이미지 생성 실패: {}", e.getMessage());

            // 실패 시 더미 이미지 사용
            String dummyImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
            story.setImage(dummyImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("🔄 더미 이미지로 저장 완료: {}", dummyImageUrl);
            return savedStory;
        }
    }

    // 🆕 이미지 S3 처리 메서드
    private String processImageWithS3(String imageUrl, Long storyId) {
        try {
            if (imageUrl == null || imageUrl.trim().isEmpty()) {
                log.warn("⚠️ 이미지 URL이 null이거나 비어있음");
                return "";
            }

            // 이미 S3 URL인 경우 그대로 반환
            if (imageUrl.contains("amazonaws.com") || imageUrl.contains("cloudfront.net")) {
                log.info("✅ 이미 S3 URL: {}", imageUrl);
                return imageUrl;
            }

            // 🎯 외부 URL을 S3에 업로드 (흑백 변환을 위해 필수)
            log.info("📤 이미지 S3 업로드 시작 (흑백변환용): {}", imageUrl);
            String s3Url = s3Service.uploadImageFromUrl(imageUrl, storyId);
            log.info("✅ 이미지 S3 업로드 완료: {}", s3Url);

            return s3Url;

        } catch (Exception e) {
            log.error("❌ S3 이미지 처리 실패: {}", e.getMessage());
            // 🎯 실패해도 원본 URL 반환 (색칠공부는 안되지만 이미지 표시는 됨)
            log.info("🔄 S3 업로드 실패, 원본 URL 사용 (색칠공부 기능 제한됨): {}", imageUrl);
            return imageUrl;
        }
    }

    // 🆕 색칠공부 템플릿 비동기 생성 (PIL+OpenCV 변환)
    @Async
    public CompletableFuture<Void> createColoringTemplateAsync(Story story, String colorImageUrl) {
        try {
            System.out.println("🎨 색칠공부 템플릿 비동기 생성 시작 - StoryId: " + story.getId());

            // ColoringTemplateService를 통해 PIL+OpenCV 변환 및 템플릿 생성
            coloringTemplateService.createColoringTemplate(
                    story.getId().toString(),
                    story.getTitle() + " 색칠하기",
                    colorImageUrl,
                    null  // 흑백 이미지는 자동 변환
            );

            System.out.println("✅ 색칠공부 템플릿 비동기 생성 완료");
        } catch (Exception e) {
            System.err.println("❌ 색칠공부 템플릿 생성 실패: " + e.getMessage());
            // 색칠공부 템플릿 생성 실패해도 Story는 정상 처리
        }
        return CompletableFuture.completedFuture(null);
    }

    // 🎯 s3 변경 보이스
    public Story createVoice(VoiceRequest request) {
        log.info("🔍 음성 생성 시작 - StoryId: {}", request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        log.info("🔍 스토리 조회 성공 - Content 길이: {}", story.getContent().length());

        // 2. FastAPI 요청 객체 생성
        FastApiVoiceRequest fastApiRequest = new FastApiVoiceRequest();
        fastApiRequest.setText(story.getContent());

        log.info("🔍 FastAPI 음성 요청: text 길이 = {}", fastApiRequest.getText().length());

        // 3. FastAPI 호출
        String url = fastApiBaseUrl + "/generate/voice";
        String fastApiResponse = callFastApi(url, fastApiRequest);

        // 4. 응답 파싱 (로컬 파일 경로 받기)
        String localFilePath = extractVoiceUrlFromResponse(fastApiResponse);
        log.info("🔍 FastAPI에서 받은 로컬 파일 경로: {}", localFilePath);

        // 🎯 5. S3에 파일 업로드 및 URL 처리
        String voiceUrl = processVoiceWithS3(localFilePath);
        log.info("🔍 S3 처리된 음성 URL: {}", voiceUrl);

        // 6. 저장
        story.setVoiceContent(voiceUrl);
        return storyRepository.save(story);
    }

    // S3를 활용한 음성 파일 처리 메서드 추가
    private String processVoiceWithS3(String localFilePath) {
        try {
            if (localFilePath == null || localFilePath.trim().isEmpty()) {
                log.warn("⚠️ 음성 파일 경로가 null이거나 비어있음");
                return "";
            }

            // HTTP URL인 경우 그대로 반환 (이미 외부에서 접근 가능)
            if (localFilePath.startsWith("http://") || localFilePath.startsWith("https://")) {
                log.info("✅ HTTP URL 음성 파일: {}", localFilePath);
                return localFilePath;
            }

            // 🔒 로컬 파일 경로 보안 검사
            if (!isValidAudioPath(localFilePath)) {
                log.error("❌ 유효하지 않은 오디오 파일 경로: {}", localFilePath);
                return "";
            }

            // 🎯 S3에 업로드
            log.info("📤 S3 업로드 시작: {}", localFilePath);
            String s3Url = s3Service.uploadAudioFileWithPresignedUrl(localFilePath);
            log.info("✅ S3 업로드 완료: {}", s3Url);

            // 🧹 선택적: 로컬 파일 삭제 (디스크 공간 절약)
            // cleanupLocalFile(localFilePath);

            return s3Url;

        } catch (Exception e) {
            log.error("❌ S3 음성 파일 처리 실패: {}", e.getMessage());

            // 🎯 폴백: 로컬 파일 경로 그대로 반환 (기존 다운로드 API 사용)
            log.info("🔄 S3 업로드 실패, 로컬 파일 경로 사용: {}", localFilePath);
            return localFilePath;
        }
    }

    //S3 기반 유틸리티 메서드들 추가
    /**
     * 📥 S3에서 음성 파일 직접 다운로드 (관리자용)
     */
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

    /**
     * 🔗 임시 접근 URL 생성 (보안이 필요한 경우)
     */
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

            // S3 URL이 아닌 경우 원본 반환
            return voiceUrl;

        } catch (Exception e) {
            log.error("❌ 임시 URL 생성 실패: {}", e.getMessage());
            throw new RuntimeException("임시 URL 생성 실패", e);
        }
    }

    /**
     * 🗑️ 스토리 삭제시 S3 음성 파일도 함께 삭제
     */
    public void deleteStoryWithVoiceFile(Long storyId, String username) {
        try {
            Story story = getStoryById(storyId, username);

            // S3에서 음성 파일 삭제
            String voiceUrl = story.getVoiceContent();
            if (voiceUrl != null && !voiceUrl.isEmpty()) {
                String s3Key = s3Service.extractS3KeyFromUrl(voiceUrl);
                if (s3Key != null) {
                    s3Service.deleteFile(s3Key);
                    log.info("✅ S3 음성 파일 삭제 완료: {}", s3Key);
                }
            }

            // 스토리 삭제
            storyRepository.delete(story);
            log.info("✅ 스토리 삭제 완료: {}", storyId);

        } catch (Exception e) {
            log.error("❌ 스토리 삭제 실패: {}", e.getMessage());
            throw new RuntimeException("스토리 삭제 실패", e);
        }
    }

    // 🎯 오디오 파일 경로 보안 검사 (Controller와 동일한 로직)
    private boolean isValidAudioPath(String filePath) {
        try {
            // 허용된 디렉토리 패턴들
            String[] allowedPatterns = {
                    "/tmp/",           // 임시 파일
                    "/var/folders/",   // macOS 임시 폴더
                    "/temp/",          // Windows 임시 폴더
                    "temp",            // 상대 경로 temp
                    ".mp3",            // mp3 확장자
                    ".wav",            // wav 확장자
                    ".m4a"             // m4a 확장자
            };

            // 경로에 허용된 패턴이 포함되어 있는지 확인
            for (String pattern : allowedPatterns) {
                if (filePath.contains(pattern)) {
                    // 🔥 추가 보안: 상위 디렉토리 접근 차단
                    if (filePath.contains("../") || filePath.contains("..\\")) {
                        System.out.println("❌ 상위 디렉토리 접근 시도 차단: " + filePath);
                        return false;
                    }
                    return true;
                }
            }

            return false;

        } catch (Exception e) {
            System.err.println("❌ 경로 검사 중 오류: " + e.getMessage());
            return false;
        }
    }

    // 🎯 개선된 FastAPI 호출 메서드 (더 상세한 로깅)
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

    // FastAPI 응답 파싱 메서드들
    private String extractStoryFromResponse(String response) {
        try {
            JsonNode jsonNode = objectMapper.readTree(response);
            return jsonNode.get("story").asText();
        } catch (Exception e) {
            // JSON 파싱 실패 시 응답 전체를 스토리로 사용
            return response;
        }
    }

    // 🎯 개선된 응답 파싱 메서드 (더 상세한 로깅)
    private String extractImageUrlFromResponse(String response) {
        try {
            System.out.println("🔍 이미지 URL 파싱 시작");
            System.out.println("🔍 FastAPI 응답 원문: " + response);

            JsonNode jsonNode = objectMapper.readTree(response);
            System.out.println("🔍 JSON 파싱 성공");

            // image_url 필드 확인
            if (jsonNode.has("image_url")) {
                String imageUrl = jsonNode.get("image_url").asText();
                System.out.println("🔍 추출된 image_url: " + imageUrl);

                if ("null".equals(imageUrl) || imageUrl == null || imageUrl.trim().isEmpty()) {
                    System.out.println("❌ image_url이 null이거나 비어있음");

                    // 오류 메시지 확인
                    if (jsonNode.has("error")) {
                        String error = jsonNode.get("error").asText();
                        System.out.println("❌ FastAPI 오류: " + error);
                        throw new RuntimeException("FastAPI 이미지 생성 오류: " + error);
                    }

                    throw new RuntimeException("FastAPI에서 유효한 이미지 URL을 반환하지 않았습니다.");
                }

                return imageUrl;
            } else {
                System.out.println("❌ 응답에 image_url 필드가 없음");
                System.out.println("🔍 사용 가능한 필드들: " + jsonNode.fieldNames());
                throw new RuntimeException("응답에 image_url 필드가 없습니다.");
            }
        } catch (Exception e) {
            System.err.println("❌ 이미지 URL 파싱 실패: " + e.getMessage());
            System.err.println("❌ 응답 내용: " + response);
            throw new RuntimeException("이미지 URL 파싱 실패: " + e.getMessage(), e);
        }
    }

    // 🎯 음성 URL 파싱 (로컬 파일 경로 처리 포함)
    private String extractVoiceUrlFromResponse(String response) {
        try {
            System.out.println("🔍 음성 URL 파싱 시작");
            System.out.println("🔍 FastAPI 음성 응답: " + response);

            JsonNode jsonNode = objectMapper.readTree(response);

            // 🎯 여러 가능한 필드명 확인
            String[] possibleFields = {"audio_path", "voice_url", "file_path", "audio_url", "path"};

            for (String field : possibleFields) {
                if (jsonNode.has(field)) {
                    String audioPath = jsonNode.get(field).asText();
                    System.out.println("🔍 " + field + " 필드에서 추출: " + audioPath);

                    if (audioPath != null && !audioPath.trim().isEmpty() && !"null".equals(audioPath)) {
                        return audioPath;
                    }
                }
            }

            System.out.println("❌ 유효한 음성 경로를 찾을 수 없음");
            System.out.println("🔍 사용 가능한 필드들: " + jsonNode.fieldNames());
            throw new RuntimeException("응답에서 유효한 음성 경로를 찾을 수 없습니다.");

        } catch (Exception e) {
            System.err.println("❌ 음성 URL 파싱 실패: " + e.getMessage());
            System.err.println("❌ 응답 내용: " + response);
            throw new RuntimeException("음성 URL 파싱 실패: " + e.getMessage(), e);
        }
    }

    // 기존 조회 메서드
    public Story getStoryById(Long id, String username) {
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return storyRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));
    }

    // 🎯 PIL+OpenCV 흑백 변환 프록시 메서드 (null 체크 추가)
    public ResponseEntity<String> convertToBlackWhite(Map<String, String> request) {
        try {
            String imageUrl = request.get("text");
            System.out.println("🔍 PIL+OpenCV 흑백 변환 요청: " + imageUrl);

            // 🔥 null 체크 추가
            if (imageUrl == null || imageUrl.trim().isEmpty() || "null".equals(imageUrl)) {
                System.out.println("❌ 이미지 URL이 null이거나 비어있음: " + imageUrl);

                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("image_url", null);
                errorResponse.put("error", "이미지 URL이 null입니다.");
                errorResponse.put("conversion_method", "Flutter_Filter");

                String errorJson = objectMapper.writeValueAsString(errorResponse);
                return ResponseEntity.ok(errorJson);
            }

            // 🎯 Python의 convert_bw_image 함수와 동일한 FastAPI 호출
            String url = fastApiBaseUrl + "/convert/bwimage";
            String response = callFastApi(url, request);

            System.out.println("🔍 FastAPI PIL+OpenCV 변환 응답: " + response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.out.println("❌ PIL+OpenCV 변환 실패: " + e.getMessage());

            // 🎯 실패 시 Flutter 필터링 안내 응답
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

    // 🆕 색칠공부 템플릿 수동 생성 메서드
    public void createColoringTemplateForExistingStory(Long storyId) {
        try {
            Story story = storyRepository.findById(storyId)
                    .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

            if (story.getImage() != null && !story.getImage().isEmpty()) {
                System.out.println("🎨 기존 스토리의 색칠공부 템플릿 수동 생성 - StoryId: " + storyId);

                coloringTemplateService.createColoringTemplate(
                        story.getId().toString(),
                        story.getTitle() + " 색칠하기",
                        story.getImage(),
                        null  // PIL+OpenCV 자동 변환
                );

                System.out.println("✅ 기존 스토리의 색칠공부 템플릿 생성 완료");
            } else {
                System.out.println("⚠️ 스토리에 이미지가 없어서 색칠공부 템플릿을 생성할 수 없습니다.");
            }
        } catch (Exception e) {
            System.err.println("❌ 색칠공부 템플릿 수동 생성 실패: " + e.getMessage());
            throw new RuntimeException("색칠공부 템플릿 생성 실패", e);
        }
    }
}