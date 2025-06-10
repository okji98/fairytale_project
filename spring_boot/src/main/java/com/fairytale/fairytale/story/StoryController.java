package com.fairytale.fairytale.story;

// 📚 필요한 라이브러리들 import
import com.fairytale.fairytale.story.dto.*;         // 동화 관련 DTO 클래스들 (요청/응답 데이터 구조)
import com.fasterxml.jackson.databind.ObjectMapper;  // JSON과 Java 객체 간 변환을 위한 Jackson 라이브러리
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule; // Java 8 시간 API (LocalDateTime 등) 직렬화 지원
import com.fasterxml.jackson.databind.SerializationFeature;  // JSON 직렬화 옵션 설정
import lombok.RequiredArgsConstructor;               // Lombok - final 필드에 대한 생성자 자동 생성
import org.springframework.http.*;                   // HTTP 관련 클래스들 (ResponseEntity, HttpStatus 등)
import org.springframework.security.core.Authentication; // 스프링 시큐리티 - 사용자 인증 정보
import org.springframework.web.bind.annotation.*;    // REST API 관련 어노테이션들
import org.springframework.web.client.RestTemplate;  // 외부 API 호출을 위한 HTTP 클라이언트
import org.springframework.util.StreamUtils;         // 스트림 유틸리티 (파일 읽기 등)

import java.io.File;           // 파일 시스템 접근
import java.io.FileInputStream; // 파일 입력 스트림
import java.io.IOException;    // 입출력 예외 처리
import java.util.HashMap;      // 해시맵 자료구조
import java.util.Map;          // 맵 인터페이스

/**
 * 🎭 StoryController - 동화 생성 및 관리 REST API 컨트롤러
 *
 * 주요 기능:
 * 1. 동화 텍스트 생성 (AI 기반)
 * 2. 음성 변환 (TTS)
 * 3. 이미지 생성 및 흑백 변환
 * 4. 오디오 파일 다운로드
 * 5. 음악/비디오 검색
 *
 * 왜 이렇게 설계했는가?
 * - 파이썬 FastAPI와 분리하여 Java의 안정성과 보안 기능 활용
 * - 스프링 시큐리티를 통한 사용자 인증/권한 관리
 * - 파일 다운로드 등 시스템 리소스 접근의 안전한 관리
 */
@RestController                    // 이 클래스가 REST API 컨트롤러임을 선언
@RequestMapping("api/fairytale")   // 모든 메서드의 기본 URL 경로: /api/fairytale
@RequiredArgsConstructor           // final 필드들을 매개변수로 하는 생성자 자동 생성
public class StoryController {

  // 🔧 의존성 주입 - 스프링이 자동으로 주입해주는 서비스들
  private final StoryService storyService;  // 동화 관련 비즈니스 로직 처리 서비스
  private final RestTemplate restTemplate;  // 파이썬 FastAPI 호출을 위한 HTTP 클라이언트

  /**
   * 🎯 동화 생성 API
   * POST /api/fairytale/generate/story
   *
   * 왜 POST인가?
   * - 사용자 입력(이름, 테마)을 받아서 새로운 동화를 생성하므로
   * - GET은 데이터 조회용, POST는 데이터 생성/변경용
   */
  @PostMapping("/generate/story")
  public ResponseEntity<Story> createStory(
          @RequestBody StoryCreateRequest request,  // HTTP 요청 본문을 StoryCreateRequest 객체로 변환
          Authentication auth                       // 스프링 시큐리티에서 제공하는 인증된 사용자 정보
  ) {
    try {
      // 🔍 인증된 사용자의 username 추출
      String username = auth.getName();
      System.out.println("🔍 컨트롤러에서 받은 username: " + username);

      // 🎭 StoryService에 동화 생성 요청 위임
      // 왜 Service에 위임하는가? 컨트롤러는 HTTP 처리만, 비즈니스 로직은 Service에서
      Story story = storyService.createStory(request, username);

      // ✅ 성공 응답 반환 (HTTP 200 OK + Story 객체)
      return ResponseEntity.ok(story);

    } catch (Exception e) {
      // ❌ 예외 발생시 에러 로그 출력
      System.out.println("❌ 컨트롤러 에러: " + e.getMessage());
      // HTTP 500 Internal Server Error 반환
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
  }

  /**
   * 📖 특정 동화 조회 API
   * GET /api/fairytale/story/{id}
   *
   * 왜 GET인가? 기존 데이터를 조회만 하므로
   * 왜 @PathVariable인가? URL 경로에 포함된 id 값을 매개변수로 받기 위해
   */
  @GetMapping("/story/{id}")
  public ResponseEntity<Story> getStory(
          @PathVariable Long id,        // URL 경로의 {id} 부분을 Long 타입으로 받음
          Authentication auth           // 인증된 사용자만 자신의 동화를 조회할 수 있도록
  ) {
    try {
      String username = auth.getName();
      // 🔒 보안: 사용자는 자신의 동화만 조회 가능
      Story story = storyService.getStoryById(id, username);
      return ResponseEntity.ok(story);
    } catch (Exception e) {
      // 동화를 찾을 수 없거나 권한이 없으면 HTTP 404 Not Found
      return ResponseEntity.notFound().build();
    }
  }

  /**
   * 🗣️ 음성 변환 API (TTS - Text To Speech)
   * POST /api/fairytale/generate/voice
   *
   * 파이썬 FastAPI의 TTS 기능을 호출하여 텍스트를 음성으로 변환
   */
  @PostMapping("/generate/voice")
  public ResponseEntity<Story> createVoice(@RequestBody VoiceRequest request) {
    try {
      // 🎤 StoryService에서 파이썬 TTS API 호출 처리
      Story result = storyService.createVoice(request);
      return ResponseEntity.ok(result);
    } catch (Exception e) {
      // 음성 생성 실패시 HTTP 400 Bad Request
      return ResponseEntity.badRequest().build();
    }
  }

  /**
   * 📁 로컬 오디오 파일 다운로드 API
   * POST /api/fairytale/download/audio
   *
   * 왜 이 API가 필요한가?
   * - 파이썬에서 생성된 음성 파일을 플러터 앱에서 재생하기 위해
   * - 로컬 파일 시스템에 직접 접근할 수 없으므로 HTTP API로 제공
   * - 보안을 위해 파일 경로 검증 필수
   */
  @PostMapping("/download/audio")
  public ResponseEntity<byte[]> downloadAudioFile(@RequestBody Map<String, String> request) {
    try {
      // 📂 요청에서 파일 경로 추출
      String filePath = request.get("filePath");
      System.out.println("🔍 [오디오 다운로드] 요청된 파일 경로: " + filePath);

      // 🚫 파일 경로가 없으면 에러
      if (filePath == null || filePath.trim().isEmpty()) {
        System.out.println("❌ 파일 경로가 비어있음");
        return ResponseEntity.badRequest()
                .body("파일 경로가 제공되지 않았습니다.".getBytes());
      }

      // 🔒 보안 검사: 허용된 경로만 접근 가능 (매우 중요!)
      // 왜 필요한가? 악의적 사용자가 시스템 파일에 접근하는 것을 방지
      if (!isValidAudioPath(filePath)) {
        System.out.println("❌ 허용되지 않은 파일 경로: " + filePath);
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body("접근이 허용되지 않은 파일 경로입니다.".getBytes());
      }

      // 📄 File 객체 생성 (실제 파일 시스템의 파일을 가리킴)
      File audioFile = new File(filePath);

      // 📂 파일 존재 여부 확인
      if (!audioFile.exists()) {
        System.out.println("❌ 파일이 존재하지 않음: " + filePath);
        return ResponseEntity.notFound().build(); // HTTP 404
      }

      // 🔐 파일 읽기 권한 확인
      if (!audioFile.canRead()) {
        System.out.println("❌ 파일을 읽을 수 없음: " + filePath);
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body("파일에 대한 읽기 권한이 없습니다.".getBytes());
      }

      // ✅ 파일 정보 로깅
      System.out.println("✅ 파일 존재 확인: " + audioFile.getAbsolutePath());
      System.out.println("🔍 파일 크기: " + audioFile.length() + " bytes");

      // 📖 파일을 바이트 배열로 읽기 (try-with-resources로 자동 리소스 해제)
      try (FileInputStream fileInputStream = new FileInputStream(audioFile)) {
        // StreamUtils.copyToByteArray: 스트림 내용을 바이트 배열로 복사
        byte[] audioBytes = StreamUtils.copyToByteArray(fileInputStream);

        System.out.println("✅ 파일 읽기 완료: " + audioBytes.length + " bytes");

        // 📋 HTTP 응답 헤더 설정
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(getAudioMediaType(filePath));    // 파일 확장자에 따른 MIME 타입
        headers.setContentLength(audioBytes.length);            // 파일 크기
        headers.setCacheControl("no-cache");                    // 캐시 비활성화

        // 🌐 CORS 헤더 추가 (Flutter 웹에서 접근 가능하도록)
        // 왜 필요한가? 브라우저의 Same-Origin Policy 때문에 다른 포트의 API 호출이 차단됨
        headers.add("Access-Control-Allow-Origin", "*");
        headers.add("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization");

        System.out.println("✅ 오디오 파일 다운로드 성공");

        // 📤 파일 데이터와 헤더를 포함한 응답 반환
        return ResponseEntity.ok()
                .headers(headers)
                .body(audioBytes);

      } catch (IOException e) {
        // 📁 파일 읽기 실패 처리
        System.err.println("❌ 파일 읽기 실패: " + e.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(("파일 읽기 실패: " + e.getMessage()).getBytes());
      }

    } catch (Exception e) {
      // 🚨 전체적인 예외 처리
      System.err.println("❌ 오디오 다운로드 처리 실패: " + e.getMessage());
      e.printStackTrace(); // 상세한 에러 스택 출력
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
              .body(("서버 오류: " + e.getMessage()).getBytes());
    }
  }

  /**
   * 🔒 오디오 파일 경로 보안 검사 메서드
   *
   * 왜 이 메서드가 중요한가?
   * - Path Traversal 공격 방지 (../../../etc/passwd 같은 공격)
   * - 시스템 중요 파일 접근 차단
   * - 허용된 디렉토리와 파일 형식만 접근 허용
   */
  private boolean isValidAudioPath(String filePath) {
    try {
      // 📂 허용된 디렉토리 패턴들 정의
      String[] allowedPatterns = {
              "/tmp/",           // 유닉스/리눅스 임시 파일 디렉토리
              "/var/folders/",   // macOS 임시 폴더
              "/temp/",          // Windows 임시 폴더
              "temp",            // 상대 경로 temp 폴더
              ".mp3",            // mp3 확장자 파일
              ".wav",            // wav 확장자 파일
              ".m4a"             // m4a 확장자 파일
      };

      // 🔍 경로에 허용된 패턴이 포함되어 있는지 확인
      for (String pattern : allowedPatterns) {
        if (filePath.contains(pattern)) {
          System.out.println("✅ 허용된 경로 패턴 발견: " + pattern);

          // 🚫 추가 보안: 상위 디렉토리 접근 차단
          // "../"나 "..\" 패턴으로 상위 폴더 접근 시도 차단
          if (filePath.contains("../") || filePath.contains("..\\")) {
            System.out.println("❌ 상위 디렉토리 접근 시도 차단: " + filePath);
            return false;
          }

          return true; // 모든 검사 통과
        }
      }

      // ❌ 허용되지 않은 경로
      System.out.println("❌ 허용되지 않은 경로 패턴: " + filePath);
      return false;

    } catch (Exception e) {
      System.err.println("❌ 경로 검사 중 오류: " + e.getMessage());
      return false;
    }
  }

  /**
   * 🎵 파일 확장자에 따른 MediaType 반환
   *
   * 왜 필요한가?
   * - 브라우저가 파일을 올바르게 해석할 수 있도록 MIME 타입 제공
   * - 오디오 플레이어가 파일 형식을 인식할 수 있도록
   */
  private MediaType getAudioMediaType(String filePath) {
    String lowerPath = filePath.toLowerCase(); // 대소문자 구분 없이 확장자 확인

    if (lowerPath.endsWith(".mp3")) {
      return MediaType.valueOf("audio/mpeg");     // MP3 파일용 MIME 타입
    } else if (lowerPath.endsWith(".wav")) {
      return MediaType.valueOf("audio/wav");      // WAV 파일용 MIME 타입
    } else if (lowerPath.endsWith(".m4a")) {
      return MediaType.valueOf("audio/mp4");      // M4A 파일용 MIME 타입
    } else if (lowerPath.endsWith(".ogg")) {
      return MediaType.valueOf("audio/ogg");      // OGG 파일용 MIME 타입
    } else {
      // 🤷‍♂️ 알 수 없는 확장자의 경우 기본값
      return MediaType.APPLICATION_OCTET_STREAM;  // 바이너리 데이터 기본 타입
    }
  }

  /**
   * 🎨 이미지 생성 API
   * POST /api/fairytale/generate/image
   *
   * 파이썬 FastAPI의 이미지 생성 기능 호출
   */
  @PostMapping("/generate/image")
  public ResponseEntity<Story> createImage(@RequestBody ImageRequest request) {
    try {
      // 🖼️ StoryService에서 이미지 생성 처리
      Story result = storyService.createImage(request);

      // 🔍 응답 전 디버깅 로그 (개발 단계에서 문제 해결용)
      System.out.println("=== 컨트롤러 응답 데이터 ===");
      System.out.println("Story ID: " + result.getId());
      System.out.println("Title: " + result.getTitle());
      System.out.println("Image URL: " + result.getImage());
      System.out.println("Image URL 길이: " + (result.getImage() != null ? result.getImage().length() : "null"));
      System.out.println("Voice Content: " + result.getVoiceContent());

      // 🔍 JSON 직렬화 테스트 (JSR310 모듈 포함)
      // 왜 이 테스트가 필요한가? LocalDateTime 등 Java 8 시간 API 직렬화 문제 확인
      try {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());                         // Java 8 시간 API 지원
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);      // 날짜를 타임스탬프가 아닌 문자열로
        String jsonResponse = mapper.writeValueAsString(result);
        System.out.println("🔍 JSON 응답 미리보기: " + jsonResponse.substring(0, Math.min(500, jsonResponse.length())));
      } catch (Exception e) {
        System.out.println("❌ JSON 직렬화 실패: " + e.getMessage());
      }

      return ResponseEntity.ok(result);
    } catch (Exception e) {
      System.out.println("❌ 컨트롤러 에러: " + e.getMessage());
      e.printStackTrace(); // 상세한 에러 추적
      return ResponseEntity.badRequest().build();
    }
  }

  /**
   * 🖤 PIL+OpenCV 흑백 변환 API
   * POST /api/fairytale/convert/bwimage
   *
   * 왜 흑백 변환이 필요한가?
   * - 아이들이 색칠하기 용도로 사용할 수 있도록
   * - 프린터 잉크 절약
   * - 교육적 활용 (색깔 인식 학습 등)
   */
  @PostMapping("/convert/bwimage")
  public ResponseEntity<Map<String, Object>> convertToBlackWhite(@RequestBody Map<String, String> request) {
    System.out.println("🔍 [StoryController] PIL+OpenCV 흑백 변환 요청: " + request);

    try {
      // 🎨 요청에서 컬러 이미지 URL 추출
      String colorImageUrl = request.get("text");

      // 📷 이미지 URL 유효성 검사
      if (colorImageUrl == null || colorImageUrl.isEmpty()) {
        Map<String, Object> errorResponse = new HashMap<>();
        errorResponse.put("error", "이미지 URL이 제공되지 않았습니다.");
        return ResponseEntity.badRequest().body(errorResponse);
      }

      // 🐍 Python 코드의 convert_bw_image와 동일한 FastAPI 호출
      Map<String, String> fastApiRequest = new HashMap<>();
      fastApiRequest.put("text", colorImageUrl);  // 파이썬 API의 파라미터명에 맞춤

      System.out.println("🔍 [StoryController] FastAPI PIL+OpenCV 변환 요청: " + fastApiRequest);

      // 🌐 RestTemplate로 파이썬 FastAPI 호출
      // 왜 @SuppressWarnings? 제네릭 타입 안전성 경고 무시 (Map.class 사용시 발생)
      @SuppressWarnings("unchecked")
      Map<String, String> response = restTemplate.postForObject(
              "http://localhost:8000/convert/bwimage",  // 파이썬 FastAPI 엔드포인트
              fastApiRequest,                           // 요청 데이터
              Map.class                                 // 응답 타입
      );

      System.out.println("🔍 [StoryController] FastAPI 응답: " + response);

      // ✅ 파이썬에서 성공적으로 응답받은 경우
      if (response != null && response.containsKey("image_url")) {
        String imageUrl = response.get("image_url");

        // 🔧 Python과 동일한 URL 처리 로직 적용
        String finalImageUrl = processConvertedImageUrl(imageUrl, colorImageUrl);

        // 📦 최종 응답 데이터 구성
        Map<String, Object> result = new HashMap<>();
        result.put("image_url", finalImageUrl);                   // 최종 이미지 URL
        result.put("original_url", colorImageUrl);                // 원본 이미지 URL
        result.put("conversion_method", "PIL+OpenCV");            // 변환 방법
        result.put("python_response", imageUrl);                  // 원본 Python 응답 포함

        System.out.println("✅ [StoryController] PIL+OpenCV 흑백 변환 성공: " + finalImageUrl);
        return ResponseEntity.ok(result);
      } else {
        throw new RuntimeException("FastAPI에서 유효한 응답을 받지 못했습니다.");
      }

    } catch (Exception e) {
      System.err.println("❌ [StoryController] PIL+OpenCV 변환 실패: " + e.getMessage());

      // 🛡️ 폴백: 원본 이미지 + Flutter 필터링 안내
      // 왜 폴백이 필요한가? 파이썬 서버 오류시에도 사용자 경험 유지
      Map<String, Object> fallbackResponse = new HashMap<>();
      fallbackResponse.put("image_url", request.get("text"));           // 원본 URL 사용
      fallbackResponse.put("original_url", request.get("text"));

      return ResponseEntity.ok(fallbackResponse);
    }
  }

  /**
   * 🔧 Python 변환 결과 URL 처리 메서드
   *
   * 왜 이 처리가 필요한가?
   * - 파이썬에서 다양한 형태로 응답할 수 있음 (완전한 URL, 파일명만, Base64 등)
   * - 플러터에서 사용 가능한 형태로 통일 필요
   */
  private String processConvertedImageUrl(String convertedUrl, String originalUrl) {
    System.out.println("🔍 [StoryController] URL 처리 - 변환됨: " + convertedUrl + ", 원본: " + originalUrl);

    // 1️⃣ 완전한 URL인 경우 (HTTP URL이나 Base64 데이터 URL)
    if (convertedUrl.startsWith("http://") ||
            convertedUrl.startsWith("https://") ||
            convertedUrl.startsWith("data:image/")) {
      System.out.println("✅ [StoryController] 완전한 URL 확인");
      return convertedUrl;
    }

    // 2️⃣ 파일명만 반환된 경우 (Python의 로컬 저장 결과)
    if (convertedUrl.equals("bw_image.png") ||
            convertedUrl.endsWith(".png") ||
            convertedUrl.endsWith(".jpg")) {
      System.out.println("⚠️ [StoryController] 파일명만 반환됨, 원본 이미지 사용");
      return originalUrl; // Flutter에서 클라이언트 사이드 필터링 처리
    }

    // 3️⃣ 기타 경우 (예상하지 못한 응답 형식)
    System.out.println("⚠️ [StoryController] 알 수 없는 형식, 원본 이미지 사용");
    return originalUrl;
  }

  /**
   * 💾 추후 S3 업로드를 위한 메서드 (현재는 주석 처리)
   *
   * 왜 주석 처리되어 있는가?
   * - 현재는 로컬 파일 다운로드로 구현
   * - 추후 AWS S3 연동시 사용할 예정
   * - 확장 가능한 구조로 미리 준비해둠
   */
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