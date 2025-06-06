package com.fairytale.fairytale.story;

import com.fairytale.fairytale.story.dto.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.databind.SerializationFeature;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("api/fairytale")
@RequiredArgsConstructor
public class StoryController {
  private final StoryService storyService;
  private final RestTemplate restTemplate;

  @PostMapping("/generate/story")
  public ResponseEntity<Story> createStory(@RequestBody StoryCreateRequest request, Authentication auth) {
    try {
      String username = auth.getName();
      System.out.println("🔍 컨트롤러에서 받은 username: " + username);

      Story story = storyService.createStory(request, username);
      return ResponseEntity.ok(story);
    } catch (Exception e) {
      System.out.println("❌ 컨트롤러 에러: " + e.getMessage());
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
  }

  @GetMapping("/story/{id}")
  public ResponseEntity<Story> getStory(@PathVariable Long id, Authentication auth) {
    try {
      String username = auth.getName();
      Story story = storyService.getStoryById(id, username);
      return ResponseEntity.ok(story);
    } catch (Exception e) {
      return ResponseEntity.notFound().build();
    }
  }

  @PostMapping("/generate/voice")
  public ResponseEntity<Story> createVoice(@RequestBody VoiceRequest request) {
    try {
      Story result = storyService.createVoice(request);
      return ResponseEntity.ok(result);
    } catch (Exception e) {
      return ResponseEntity.badRequest().build();
    }
  }

  @PostMapping("/generate/image")
  public ResponseEntity<Story> createImage(@RequestBody ImageRequest request) {
    try {
      Story result = storyService.createImage(request);

      // 🔍 응답 전 디버깅 로그
      System.out.println("=== 컨트롤러 응답 데이터 ===");
      System.out.println("Story ID: " + result.getId());
      System.out.println("Title: " + result.getTitle());
      System.out.println("Image URL: " + result.getImage());
      System.out.println("Image URL 길이: " + (result.getImage() != null ? result.getImage().length() : "null"));
      System.out.println("Voice Content: " + result.getVoiceContent());

      // 🔍 JSON 직렬화 테스트 (JSR310 모듈 포함)
      try {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        String jsonResponse = mapper.writeValueAsString(result);
        System.out.println("🔍 JSON 응답 미리보기: " + jsonResponse.substring(0, Math.min(500, jsonResponse.length())));
      } catch (Exception e) {
        System.out.println("❌ JSON 직렬화 실패: " + e.getMessage());
      }

      return ResponseEntity.ok(result);
    } catch (Exception e) {
      System.out.println("❌ 컨트롤러 에러: " + e.getMessage());
      e.printStackTrace();
      return ResponseEntity.badRequest().build();
    }
  }

  // 🎯 PIL+OpenCV 흑백 변환 API (Python 코드와 동일한 로직)
  @PostMapping("/convert/bwimage")
  public ResponseEntity<Map<String, Object>> convertToBlackWhite(@RequestBody Map<String, String> request) {
    System.out.println("🔍 [StoryController] PIL+OpenCV 흑백 변환 요청: " + request);

    try {
      String colorImageUrl = request.get("text");

      if (colorImageUrl == null || colorImageUrl.isEmpty()) {
        Map<String, Object> errorResponse = new HashMap<>();
        errorResponse.put("error", "이미지 URL이 제공되지 않았습니다.");
        return ResponseEntity.badRequest().body(errorResponse);
      }

      // 🎯 Python 코드의 convert_bw_image와 동일한 FastAPI 호출
      Map<String, String> fastApiRequest = new HashMap<>();
      fastApiRequest.put("text", colorImageUrl);  // image_url 파라미터

      System.out.println("🔍 [StoryController] FastAPI PIL+OpenCV 변환 요청: " + fastApiRequest);

      Map<String, String> response = restTemplate.postForObject(
              "http://localhost:8000/convert/bwimage",
              fastApiRequest,
              Map.class
      );

      System.out.println("🔍 [StoryController] FastAPI 응답: " + response);

      if (response != null && response.containsKey("image_url")) {
        String imageUrl = response.get("image_url");

        // 🎯 Python과 동일한 URL 처리 로직
        String finalImageUrl = processConvertedImageUrl(imageUrl, colorImageUrl);

        Map<String, Object> result = new HashMap<>();
        result.put("image_url", finalImageUrl);
        result.put("original_url", colorImageUrl);
        result.put("conversion_method", "PIL+OpenCV");
        result.put("python_response", imageUrl);  // 원본 Python 응답 포함

        System.out.println("✅ [StoryController] PIL+OpenCV 흑백 변환 성공: " + finalImageUrl);
        return ResponseEntity.ok(result);
      } else {
        throw new RuntimeException("FastAPI에서 유효한 응답을 받지 못했습니다.");
      }

    } catch (Exception e) {
      System.err.println("❌ [StoryController] PIL+OpenCV 변환 실패: " + e.getMessage());

      // 🎯 폴백: 원본 이미지 + Flutter 필터링 안내
      Map<String, Object> fallbackResponse = new HashMap<>();
      fallbackResponse.put("image_url", request.get("text")); // 원본 URL 사용
      fallbackResponse.put("original_url", request.get("text"));
      fallbackResponse.put("conversion_method", "Fallback_Flutter_Filter");
      fallbackResponse.put("warning", "PIL+OpenCV 변환 실패로 Flutter에서 필터링 처리됩니다.");
      fallbackResponse.put("flutter_filter_enabled", true);  // Flutter 필터 사용 플래그

      return ResponseEntity.ok(fallbackResponse);
    }
  }

  // 🎯 Python 변환 결과 URL 처리 (PIL Image 저장 방식 고려)
  private String processConvertedImageUrl(String convertedUrl, String originalUrl) {
    System.out.println("🔍 [StoryController] URL 처리 - 변환됨: " + convertedUrl + ", 원본: " + originalUrl);

    // 1. 완전한 URL인 경우 (Base64 데이터 URL 포함)
    if (convertedUrl.startsWith("http://") ||
            convertedUrl.startsWith("https://") ||
            convertedUrl.startsWith("data:image/")) {
      System.out.println("✅ [StoryController] 완전한 URL 확인");
      return convertedUrl;
    }

    // 2. 파일명만 반환된 경우 (Python의 save_path 결과)
    if (convertedUrl.equals("bw_image.png") ||
            convertedUrl.endsWith(".png") ||
            convertedUrl.endsWith(".jpg")) {
      System.out.println("⚠️ [StoryController] 파일명만 반환됨, 원본 이미지 사용");
      return originalUrl; // Flutter에서 필터링 처리
    }

    // 3. 기타 경우
    System.out.println("⚠️ [StoryController] 알 수 없는 형식, 원본 이미지 사용");
    return originalUrl;
  }

  @PostMapping("/search/url")
  public ResponseEntity<String> searchMusic(@RequestBody MusicRequest request) {
    try {
      String result = storyService.searchMusic(request);
      return ResponseEntity.ok(result);
    } catch (Exception e) {
      return ResponseEntity.badRequest().body("Error: " + e.getMessage());
    }
  }

  @PostMapping("/search/video")
  public ResponseEntity<String> searchVideo(@RequestBody VideoRequest request) {
    try {
      String result = storyService.searchVideo(request);
      return ResponseEntity.ok(result);
    } catch (Exception e) {
      return ResponseEntity.badRequest().body("Error: " + e.getMessage());
    }
  }
}