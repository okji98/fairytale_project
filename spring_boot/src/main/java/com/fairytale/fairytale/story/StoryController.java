package com.fairytale.fairytale.story;

import com.fairytale.fairytale.story.dto.*;
import com.nimbusds.oauth2.sdk.http.HTTPRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/fairytale")
@RequiredArgsConstructor
public class StoryController {
  private final StoryService storyService;

  @PostMapping("/generate/story")
  public ResponseEntity<?> createStory(@RequestBody StoryCreateRequest request) {
    System.out.println("Theme: " + request.getTheme());
    System.out.println("Voice: " + request.getVoice());
    System.out.println("ImageMode: " + request.getImageMode());
    System.out.println("Title: " + request.getTitle());
    System.out.println("UserId: " + request.getUserId());
    try {
      System.out.println("Controller: Before service call");
      Story result = storyService.createStory(request);
      System.out.println("Controller: After service call, story id: " + result.getId());
      return ResponseEntity.ok(result);
    } catch (Exception e) {
//      return ResponseEntity.badRequest().build();
      System.err.println("Controller Error: " + e.getMessage());
      e.printStackTrace();  // 이 부분이 중요! 전체 스택 트레이스 출력
      return ResponseEntity.badRequest().body("Error: " + e.getMessage());
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
      return ResponseEntity.ok(result);
    } catch (Exception e) {
      return ResponseEntity.badRequest().build();
    }
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
