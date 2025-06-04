package com.fairytale.fairytale.story;

import com.fairytale.fairytale.story.dto.*;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

@Service
@RequiredArgsConstructor
@Transactional
public class StoryService {
    private final StoryRepository storyRepository;
    private final UsersRepository usersRepository;

    @Value("${fastapi.base.url:http://localhost:8000}")
    private String fastApiBaseUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // 동화 생성 메서드
    public Story createStory(StoryCreateRequest request, String username) {
        System.out.println("🔍 스토리 생성 시작 - Username: " + username);
        System.out.println("🔍 받은 요청: theme=" + request.getTheme() + ", voice=" + request.getVoice() + ", voiceSpeed=" + request.getVoiceSpeed());

        // 1. 사용자 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> {
                    System.out.println("❌ 사용자를 찾을 수 없음: " + username);
                    usersRepository.findAll().forEach(u ->
                            System.out.println("  - 존재하는 사용자: " + u.getUsername()));
                    return new RuntimeException("사용자를 찾을 수 없습니다: " + username);
                });

        System.out.println("🔍 사용자 조회 성공 - ID: " + user.getId());

        // 2. FastAPI 전용 요청 객체 생성 (올바른 방법)
        FastApiStoryRequest fastApiRequest = new FastApiStoryRequest();
        fastApiRequest.setName(request.getTheme() + " 동화");    // theme + "동화"로 name 생성
        fastApiRequest.setTheme(request.getTheme());             // theme 설정

        System.out.println("🔍 FastAPI 요청 생성: name=" + fastApiRequest.getName() + ", theme=" + fastApiRequest.getTheme());

        // 3. FastAPI로 동화 생성 요청
        String url = fastApiBaseUrl + "/generate/story";
        String response = callFastApi(url, fastApiRequest);

        // 4. 응답에서 story 추출
        String storyContent = extractStoryFromResponse(response);

        // 5. Story 엔티티 생성 및 저장
        Story story = new Story();
        story.setTheme(request.getTheme());
        story.setVoice(request.getVoice());
        story.setImageMode("color");                           // 기본값
        story.setTitle(request.getTheme() + " 동화");          // theme + "동화"로 제목 생성
        story.setContent(storyContent);
        story.setUser(user);
        story.setVoiceContent("");
        story.setColorImage("");
        story.setBlackImage("");

        // 🆕 image 컬럼이 있다면 기본값 설정
        try {
            // image 컬럼이 있을 경우를 대비해 리플렉션으로 설정
            java.lang.reflect.Method setImageMethod = Story.class.getMethod("setImage", String.class);
            setImageMethod.invoke(story, ""); // 빈 문자열로 기본값 설정
        } catch (Exception e) {
            // image 컬럼이 없으면 무시
            System.out.println("🔍 image 컬럼이 없거나 설정 실패 (정상)");
        }

        System.out.println("🔍 스토리 저장 전 - Title: " + story.getTitle());
        Story saved = storyRepository.save(story);
        System.out.println("🔍 스토리 저장 완료 - ID: " + saved.getId());

        return saved;
    }

    // 음성 생성 메서드
    // 음성 생성 메서드에 로그 추가
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

    // 이미지 생성 메서드
    public Story createImage(ImageRequest request) {
        System.out.println("🔍 Flutter에서 받은 데이터: " + request);
        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));
        System.out.println("🔍 Story 내용 길이: " + story.getContent().length());
        // 2. style을 imageMode로 변환
        String imageMode;
        if ("cartoon".equals(request.getStyle())) {
            imageMode = "color";
        } else if ("line_art".equals(request.getStyle())) {
            imageMode = "black";
        } else {
            // 기본값 또는 에러 처리
            imageMode = "color";
        }

        // 3. FastAPI 요청 객체 생성
        FastApiImageRequest fastApiRequest = new FastApiImageRequest();
        fastApiRequest.setMode(request.getStyle());  // "cartoon" or "line_art"
        fastApiRequest.setText(story.getContent());  // 동화 내용을 텍스트로 사용
        System.out.println("🔍 FastAPI로 보낼 데이터: " + fastApiRequest);
        System.out.println("🔍 FastAPI 전송 JSON: mode=" + request.getStyle() + ", text=" + story.getContent().substring(0, Math.min(50, story.getContent().length())) + "...");

        // 4. FastAPI로 이미지 생성 요청
        String url = fastApiBaseUrl + "/generate/image";
        String fastApiResponse = callFastApi(url, fastApiRequest);

        // 5. 응답에서 이미지 url 추출
        String imageUrl = extractImageUrlFromResponse(fastApiResponse);

        // 6. imageMode에 따라 적절한 컬럼에 저장
        if ("color".equals(imageMode)) {
            story.setColorImage(imageUrl);
        } else if ("black".equals(imageMode)) {
            story.setBlackImage(imageUrl);
        } else {
            throw new IllegalArgumentException("지원하지 않는 이미지 모드: " + imageMode);
        }

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

    // StoryService.java
    public Story getStoryById(Long id, String username) {
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return storyRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));
    }
}
