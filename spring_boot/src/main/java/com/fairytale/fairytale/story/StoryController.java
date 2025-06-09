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
import org.springframework.util.StreamUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
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

  // 🎯 로컬 오디오 파일 다운로드 API (새로 추가)
  @PostMapping("/download/audio")
  public ResponseEntity<byte[]> downloadAudioFile(@RequestBody Map<String, String> request) {
    try {
      String filePath = request.get("filePath");
      System.out.println("🔍 [오디오 다운로드] 요청된 파일 경로: " + filePath);

      if (filePath == null || filePath.trim().isEmpty()) {
        System.out.println("❌ 파일 경로가 비어있음");
        return ResponseEntity.badRequest()
                .body("파일 경로가 제공되지 않았습니다.".getBytes());
      }

      // 🔥 보안 검사: 허용된 경로만 접근 가능
      if (!isValidAudioPath(filePath)) {
        System.out.println("❌ 허용되지 않은 파일 경로: " + filePath);
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body("접근이 허용되지 않은 파일 경로입니다.".getBytes());
      }

      File audioFile = new File(filePath);

      if (!audioFile.exists()) {
        System.out.println("❌ 파일이 존재하지 않음: " + filePath);
        return ResponseEntity.notFound().build();
      }

      if (!audioFile.canRead()) {
        System.out.println("❌ 파일을 읽을 수 없음: " + filePath);
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body("파일에 대한 읽기 권한이 없습니다.".getBytes());
      }

      System.out.println("✅ 파일 존재 확인: " + audioFile.getAbsolutePath());
      System.out.println("🔍 파일 크기: " + audioFile.length() + " bytes");

      // 🎯 파일을 바이트 배열로 읽기
      try (FileInputStream fileInputStream = new FileInputStream(audioFile)) {
        byte[] audioBytes = StreamUtils.copyToByteArray(fileInputStream);

        System.out.println("✅ 파일 읽기 완료: " + audioBytes.length + " bytes");

        // 🎯 HTTP 응답 헤더 설정
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(getAudioMediaType(filePath));
        headers.setContentLength(audioBytes.length);
        headers.setCacheControl("no-cache");

        // 🔥 CORS 헤더 추가 (Flutter 웹에서 접근 가능하도록)
        headers.add("Access-Control-Allow-Origin", "*");
        headers.add("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization");

        System.out.println("✅ 오디오 파일 다운로드 성공");
        return ResponseEntity.ok()
                .headers(headers)
                .body(audioBytes);

      } catch (IOException e) {
        System.err.println("❌ 파일 읽기 실패: " + e.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(("파일 읽기 실패: " + e.getMessage()).getBytes());
      }

    } catch (Exception e) {
      System.err.println("❌ 오디오 다운로드 처리 실패: " + e.getMessage());
      e.printStackTrace();
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
              .body(("서버 오류: " + e.getMessage()).getBytes());
    }
  }

  // 🎯 오디오 파일 경로 보안 검사
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
          System.out.println("✅ 허용된 경로 패턴 발견: " + pattern);

          // 🔥 추가 보안: 상위 디렉토리 접근 차단
          if (filePath.contains("../") || filePath.contains("..\\")) {
            System.out.println("❌ 상위 디렉토리 접근 시도 차단: " + filePath);
            return false;
          }

          return true;
        }
      }

      System.out.println("❌ 허용되지 않은 경로 패턴: " + filePath);
      return false;

    } catch (Exception e) {
      System.err.println("❌ 경로 검사 중 오류: " + e.getMessage());
      return false;
    }
  }

  // 🎯 파일 확장자에 따른 MediaType 반환
  private MediaType getAudioMediaType(String filePath) {
    String lowerPath = filePath.toLowerCase();

    if (lowerPath.endsWith(".mp3")) {
      return MediaType.valueOf("audio/mpeg");
    } else if (lowerPath.endsWith(".wav")) {
      return MediaType.valueOf("audio/wav");
    } else if (lowerPath.endsWith(".m4a")) {
      return MediaType.valueOf("audio/mp4");
    } else if (lowerPath.endsWith(".ogg")) {
      return MediaType.valueOf("audio/ogg");
    } else {
      // 기본값
      return MediaType.APPLICATION_OCTET_STREAM;
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

  // 🆕 추후 S3 업로드를 위한 메서드 (주석 처리)
  /*
  @PostMapping("/upload/audio/s3")
  public ResponseEntity<Map<String, String>> uploadAudioToS3(@RequestBody Map<String, String> request) {
    try {
      String localFilePath = request.get("filePath");

      // S3 업로드 로직
      // String s3Url = s3Service.uploadAudioFile(localFilePath);

      Map<String, String> response = new HashMap<>();
      // response.put("s3Url", s3Url);
      // response.put("status", "uploaded");

      return ResponseEntity.ok(response);
    } catch (Exception e) {
      Map<String, String> errorResponse = new HashMap<>();
      errorResponse.put("error", e.getMessage());
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }
  }
  */
}