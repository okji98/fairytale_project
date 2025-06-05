package com.fairytale.fairytale.story;

import com.fairytale.fairytale.story.dto.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.databind.SerializationFeature;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

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

  // 🆕 흑백 변환 프록시 엔드포인트 (StoryService 사용)
  @PostMapping("/convert/bwimage")
  public ResponseEntity<String> convertToBlackWhite(@RequestBody Map<String, String> request) {
    return storyService.convertToBlackWhite(request);
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