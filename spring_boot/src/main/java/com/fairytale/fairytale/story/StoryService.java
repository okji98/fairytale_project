package com.fairytale.fairytale.story;

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

@Service
@RequiredArgsConstructor
@Transactional
public class StoryService {
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

    // 🎯 수정된 이미지 생성 메서드 (FastAPI 요청 구조 수정 + 오류 처리 개선)
    public Story createImage(ImageRequest request) {
        System.out.println("🔍 이미지 생성 요청 - StoryId: " + request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        System.out.println("✅ 스토리 조회 성공 - Title: " + story.getTitle());
        System.out.println("🔍 스토리 내용 길이: " + story.getContent().length() + "자");

        // 2. 🎯 FastAPI 요청 데이터 (Python ImageRequest 클래스에 맞춤)
        Map<String, Object> fastApiRequest = new HashMap<>();
        fastApiRequest.put("text", story.getContent()); // FastAPI ImageRequest.text에 맞춤

        System.out.println("🔍 FastAPI 이미지 생성 요청 데이터: " + fastApiRequest);

        // 3. FastAPI로 컬러 이미지 생성
        String imageUrl = fastApiBaseUrl + "/generate/image";

        try {
            String fastApiResponse = callFastApi(imageUrl, fastApiRequest);
            String colorImageUrl = extractImageUrlFromResponse(fastApiResponse);

            System.out.println("🎯 컬러 이미지 생성 완료: " + colorImageUrl);

            if (colorImageUrl == null || colorImageUrl.trim().isEmpty() || "null".equals(colorImageUrl)) {
                System.out.println("❌ FastAPI에서 null 이미지 URL 반환");

                // 🎯 실패 시 더미 이미지 사용
                colorImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
                System.out.println("🔄 더미 이미지 URL 사용: " + colorImageUrl);
            }

            // 4. Story의 단일 image 컬럼에 저장
            story.setImage(colorImageUrl);
            Story savedStory = storyRepository.save(story);

            System.out.println("✅ 컬러 이미지 저장 완료");

            // 5. 🆕 색칠공부 템플릿 비동기 생성 (PIL+OpenCV 변환 포함)
            createColoringTemplateAsync(savedStory, colorImageUrl);

            return savedStory;

        } catch (Exception e) {
            System.err.println("❌ 이미지 생성 실패: " + e.getMessage());

            // 🎯 실패 시 더미 이미지 사용
            String dummyImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
            story.setImage(dummyImageUrl);
            Story savedStory = storyRepository.save(story);

            System.out.println("🔄 더미 이미지로 저장 완료: " + dummyImageUrl);

            return savedStory;
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
            fastApiRequest.setName("친구");  // 기본값
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

        System.out.println("🔍 스토리 저장 전 - Title: " + story.getTitle());
        Story saved = storyRepository.save(story);
        System.out.println("🔍 스토리 저장 완료 - ID: " + saved.getId());

        return saved;
    }

    // 🎯 로컬 파일 경로 처리가 가능한 음성 생성 메서드
    public Story createVoice(VoiceRequest request) {
        System.out.println("🔍 음성 생성 시작 - StoryId: " + request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        System.out.println("🔍 스토리 조회 성공 - Content 길이: " + story.getContent().length());

        // 2. FastAPI 요청 객체 생성
        FastApiVoiceRequest fastApiRequest = new FastApiVoiceRequest();
        fastApiRequest.setText(story.getContent());

        System.out.println("🔍 FastAPI 음성 요청: text 길이 = " + fastApiRequest.getText().length());

        // 3. FastAPI 호출
        String url = fastApiBaseUrl + "/generate/voice";
        String fastApiResponse = callFastApi(url, fastApiRequest);

        // 4. 응답 파싱 (로컬 파일 경로 처리)
        String voiceUrl = extractVoiceUrlFromResponse(fastApiResponse);
        System.out.println("🔍 FastAPI에서 받은 음성 경로: " + voiceUrl);

        // 🎯 로컬 파일 경로와 HTTP URL 모두 처리
        String processedVoiceUrl = processVoiceUrl(voiceUrl);
        System.out.println("🔍 처리된 음성 URL: " + processedVoiceUrl);

        // 5. 저장
        story.setVoiceContent(processedVoiceUrl);
        return storyRepository.save(story);
    }

    // 🎯 음성 URL 처리 (로컬 파일 경로와 HTTP URL 구분)
    private String processVoiceUrl(String voiceUrl) {
        if (voiceUrl == null || voiceUrl.trim().isEmpty()) {
            System.out.println("⚠️ 음성 URL이 null이거나 비어있음");
            return "";
        }

        // HTTP URL인 경우 그대로 반환
        if (voiceUrl.startsWith("http://") || voiceUrl.startsWith("https://")) {
            System.out.println("✅ HTTP URL 음성 파일: " + voiceUrl);
            return voiceUrl;
        }

        // 로컬 파일 경로인 경우
        if (voiceUrl.startsWith("/") || voiceUrl.contains("/tmp/") || voiceUrl.contains("/var/")) {
            System.out.println("🔍 로컬 파일 경로 감지: " + voiceUrl);

            // 🔥 보안 검사
            if (isValidAudioPath(voiceUrl)) {
                System.out.println("✅ 유효한 로컬 오디오 파일 경로");
                return voiceUrl; // 로컬 경로 그대로 반환 (Flutter에서 다운로드 API 호출)
            } else {
                System.out.println("❌ 유효하지 않은 오디오 파일 경로");
                return "";
            }
        }

        // 🎯 추후 S3 업로드 처리 (주석으로 준비)
        /*
        if (voiceUrl.startsWith("/") || voiceUrl.contains("tmp")) {
            // S3에 업로드하고 URL 반환
            try {
                String s3Url = uploadToS3(voiceUrl);
                System.out.println("✅ S3 업로드 완료: " + s3Url);
                return s3Url;
            } catch (Exception e) {
                System.err.println("❌ S3 업로드 실패: " + e.getMessage());
                return voiceUrl; // 실패 시 원본 경로 반환
            }
        }
        */

        System.out.println("⚠️ 알 수 없는 음성 URL 형식: " + voiceUrl);
        return voiceUrl;
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

    // 🆕 추후 S3 업로드를 위한 메서드 (주석 처리)
    /*
    private String uploadToS3(String localFilePath) {
        try {
            // S3 업로드 로직
            // 1. 로컬 파일 읽기
            // 2. S3에 업로드
            // 3. 공개 URL 반환

            // 예시:
            // File localFile = new File(localFilePath);
            // String s3Key = "audio/" + UUID.randomUUID() + ".mp3";
            // s3Client.putObject(bucketName, s3Key, localFile);
            // return "https://" + bucketName + ".s3.amazonaws.com/" + s3Key;

            return "https://example-bucket.s3.amazonaws.com/audio/example.mp3";
        } catch (Exception e) {
            throw new RuntimeException("S3 업로드 실패: " + e.getMessage(), e);
        }
    }
    */

    // 음악 검색 메서드
    public String searchMusic(MusicRequest request) {
        String url = fastApiBaseUrl + "/search/url";
        return callFastApi(url, request);
    }

    // 비디오 검색 메서드
    public String searchVideo(VideoRequest request) {
        String url = fastApiBaseUrl + "/search/video";
        return callFastApi(url, request);
    }

    // 🎯 개선된 FastAPI 호출 메서드 (더 상세한 로깅)
    private String callFastApi(String url, Object request) {
        try {
            System.out.println("🔍 FastAPI 호출 시작");
            System.out.println("🔍 URL: " + url);
            System.out.println("🔍 요청 객체 타입: " + request.getClass().getSimpleName());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            String jsonRequest = objectMapper.writeValueAsString(request);
            System.out.println("🔍 FastAPI 전송 JSON: " + jsonRequest);

            HttpEntity<String> entity = new HttpEntity<>(jsonRequest, headers);

            System.out.println("🔍 HTTP 요청 전송 중...");

            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            System.out.println("🔍 FastAPI 응답 상태코드: " + response.getStatusCode());
            System.out.println("🔍 FastAPI 응답 헤더: " + response.getHeaders());
            System.out.println("🔍 FastAPI 응답 본문: " + response.getBody());

            if (response.getStatusCode().is2xxSuccessful()) {
                return response.getBody();
            } else {
                throw new RuntimeException("FastAPI 호출 실패. 상태코드: " + response.getStatusCode());
            }

        } catch (Exception e) {
            System.err.println("❌ FastAPI 호출 실패: " + e.getMessage());
            e.printStackTrace();
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