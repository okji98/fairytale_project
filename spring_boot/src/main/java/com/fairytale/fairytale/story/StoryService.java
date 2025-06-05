package com.fairytale.fairytale.story;

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

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Transactional
public class StoryService {
    private final StoryRepository storyRepository;
    private final UsersRepository usersRepository;

    // 🆕 색칠공부 서비스 추가
    @Autowired
    private ColoringTemplateService coloringTemplateService;

    @Value("${fastapi.base.url:http://localhost:8000}")
    private String fastApiBaseUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // 🎯 수정된 이미지 생성 메서드 (흑백 변환 로직 제거)
    public Story createImage(ImageRequest request) {
        System.out.println("🔍 이미지 생성 요청 - StoryId: " + request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        System.out.println("✅ 스토리 조회 성공 - Title: " + story.getTitle());

        // 2. 🎯 FastAPI로 컬러 이미지만 생성
        FastApiImageRequest fastApiRequest = new FastApiImageRequest();
        fastApiRequest.setMode("cartoon");  // 항상 컬러로 고정
        fastApiRequest.setText(story.getContent());

        System.out.println("🔍 FastAPI 컬러 이미지 생성 요청");

        // 3. FastAPI로 컬러 이미지 생성
        String imageUrl = fastApiBaseUrl + "/generate/image";
        String fastApiResponse = callFastApi(imageUrl, fastApiRequest);
        String colorImageUrl = extractImageUrlFromResponse(fastApiResponse);

        System.out.println("🎯 컬러 이미지 생성 완료: " + colorImageUrl);

        // 4. 🎯 Story의 단일 image 컬럼에 저장
        story.setImage(colorImageUrl);
        Story savedStory = storyRepository.save(story);

        System.out.println("✅ 컬러 이미지 저장 완료");

        // 🔧 흑백 변환 로직 완전 제거 (Flutter에서 직접 처리)
        // createColoringTemplateAsync(savedStory, colorImageUrl); // 주석 처리

        return savedStory;
    }

    // 🔧 FastAPI 기존 /convert/bwimage 엔드포인트 호출
//    private String callFastApiBlackWhiteConversion(String originalImageUrl) {
//        try {
//            System.out.println("🔍 FastAPI 흑백 변환 요청 - URL: " + originalImageUrl);
//
//            // 기존 FastAPI 엔드포인트는 text 필드를 받음
//            Map<String, String> request = new HashMap<>();
//            request.put("text", originalImageUrl);  // image URL을 text 필드로 전달
//
//            // 기존 FastAPI /convert/bwimage 엔드포인트 호출
//            String url = fastApiBaseUrl + "/convert/bwimage";
//            String response = callFastApi(url, request);
//
//            // 응답에서 흑백 이미지 URL 추출
//            JsonNode jsonNode = objectMapper.readTree(response);
//            String blackWhiteUrl = jsonNode.get("image_url").asText();
//
//            System.out.println("✅ FastAPI 흑백 변환 완료: " + blackWhiteUrl);
//            return blackWhiteUrl;
//
//        } catch (Exception e) {
//            System.out.println("❌ FastAPI 흑백 변환 실패: " + e.getMessage());
//            throw new RuntimeException("FastAPI 흑백 변환 실패", e);
//        }
//    }

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

        // 2. FastAPI 동화 생성 요청
        FastApiStoryRequest fastApiRequest = new FastApiStoryRequest();
        fastApiRequest.setName(request.getTheme() + " 동화");
        fastApiRequest.setTheme(request.getTheme());

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
        story.setVoiceContent("");
        story.setImage("");  // 🎯 단일 image 컬럼 사용

        System.out.println("🔍 스토리 저장 전 - Title: " + story.getTitle());
        Story saved = storyRepository.save(story);
        System.out.println("🔍 스토리 저장 완료 - ID: " + saved.getId());

        return saved;
    }

    // 음성 생성 메서드
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

        // 4. 응답 파싱
        String voiceUrl = extractVoiceUrlFromResponse(fastApiResponse);
        System.out.println("🔍 음성 URL: " + voiceUrl);

        // 5. 저장
        story.setVoiceContent(voiceUrl);
        return storyRepository.save(story);
    }

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

    // 공통 FastAPI 호출 메서드
    private String callFastApi(String url, Object request) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            String jsonRequest = objectMapper.writeValueAsString(request);
            System.out.println("🔍 FastAPI 전송 JSON: " + jsonRequest);

            HttpEntity<String> entity = new HttpEntity<>(jsonRequest, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            System.out.println("🔍 FastAPI 응답: " + response.getBody());
            return response.getBody();
        } catch (Exception e) {
            System.out.println("❌ FastAPI 호출 실패: " + e.getMessage());
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

    private String extractImageUrlFromResponse(String response) {
        try {
            JsonNode jsonNode = objectMapper.readTree(response);
            return jsonNode.get("image_url").asText();
        } catch (Exception e) {
            throw new RuntimeException("이미지 URL 파싱 실패 " + e);
        }
    }

    private String extractVoiceUrlFromResponse(String response) {
        try {
            JsonNode jsonNode = objectMapper.readTree(response);
            return jsonNode.get("audio_path").asText();
        } catch (Exception e) {
            throw new RuntimeException("보이스 URL 파싱 실패 " + e);
        }
    }

    // 기존 조회 메서드
    public Story getStoryById(Long id, String username) {
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return storyRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));
    }

    public ResponseEntity<String> convertToBlackWhite(Map<String, String> request) {
        try {
            System.out.println("🔍 흑백 변환 요청: " + request.get("text"));

            // FastAPI로 프록시 요청
            String url = fastApiBaseUrl + "/convert/bwimage";
            String response = callFastApi(url, request);

            System.out.println("🔍 FastAPI 흑백 변환 응답: " + response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.out.println("❌ 흑백 변환 실패: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }
}