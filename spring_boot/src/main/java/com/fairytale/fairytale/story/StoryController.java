package com.fairytale.fairytale.story;

import com.fairytale.fairytale.story.dto.*;
import com.nimbusds.oauth2.sdk.http.HTTPRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class StoryController {
  private final StoryService storyService;

  @PostMapping("/generate/story")
  public ResponseEntity<Story> createStory(@RequestBody StoryCreateRequest request) {
    try {
      Story result = storyService.createStory(request);
      return ResponseEntity.ok(result);
    } catch (Exception e) {
      return ResponseEntity.badRequest().build();
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
