package com.fairytale.fairytale.lullaby;

import com.fairytale.fairytale.lullaby.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/lullaby")
@Slf4j
@CrossOrigin(origins = "*")
public class LullabyController {

    private final LullabyService lullabyService;

    public LullabyController(LullabyService lullabyService) {
        this.lullabyService = lullabyService;
    }

    // ==================== 음악 검색 API ====================

    @GetMapping("/themes")
    public ResponseEntity<ApiResponse<List<LullabyTheme>>> getDefaultThemes() {
        try {
            List<LullabyTheme> themes = lullabyService.getDefaultLullabies();
            if (themes.isEmpty()) {
                return ResponseEntity.ok(ApiResponse.success(themes, "자장가를 찾을 수 없습니다."));
            }
            return ResponseEntity.ok(ApiResponse.success(themes,
                    themes.size() + "개의 자장가를 찾았습니다."));
        } catch (Exception e) {
            log.error("기본 자장가 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("자장가 목록을 불러오는 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/theme/{themeName}")
    public ResponseEntity<ApiResponse<List<LullabyTheme>>> searchByTheme(
            @PathVariable String themeName,
            @RequestParam(defaultValue = "5") int limit
    ) {
        try {
            String decodedThemeName = URLDecoder.decode(themeName, StandardCharsets.UTF_8);
            List<LullabyTheme> themes = lullabyService.searchByTheme(decodedThemeName, limit);
            return ResponseEntity.ok(ApiResponse.success(themes,
                    "'" + decodedThemeName + "' 테마에서 " + themes.size() + "개의 음악을 찾았습니다."));
        } catch (Exception e) {
            log.error("테마 검색 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("테마 검색 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<LullabyTheme>>> searchByTag(
            @RequestParam(defaultValue = "lullaby") String tag,
            @RequestParam(defaultValue = "5") int limit
    ) {
        try {
            List<LullabyTheme> themes = lullabyService.searchByTag(tag, limit);
            return ResponseEntity.ok(ApiResponse.success(themes,
                    "'" + tag + "' 태그로 " + themes.size() + "개의 음악을 찾았습니다."));
        } catch (Exception e) {
            log.error("태그 검색 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("태그 검색 중 오류가 발생했습니다."));
        }
    }

    // ==================== 영상 검색 API ====================

    @GetMapping("/videos")
    public ResponseEntity<ApiResponse<List<LullabyVideoTheme>>> getDefaultVideos() {
        try {
            log.info("🔍 [LullabyController] 기본 자장가 영상 목록 조회 요청");
            List<LullabyVideoTheme> videos = lullabyService.getDefaultLullabyVideos();
            if (videos.isEmpty()) {
                return ResponseEntity.ok(ApiResponse.success(videos, "자장가 영상을 찾을 수 없습니다."));
            }
            return ResponseEntity.ok(ApiResponse.success(videos,
                    videos.size() + "개의 자장가 영상을 찾았습니다."));
        } catch (Exception e) {
            log.error("❌ [LullabyController] 기본 자장가 영상 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("자장가 영상 목록을 불러오는 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/videos/theme/{themeName}")
    public ResponseEntity<ApiResponse<List<LullabyVideoTheme>>> searchVideosByTheme(
            @PathVariable String themeName,
            @RequestParam(defaultValue = "5") int limit
    ) {
        try {
            String decodedThemeName = URLDecoder.decode(themeName, StandardCharsets.UTF_8);
            log.info("🔍 [LullabyController] 테마별 영상 검색 요청: {}, limit: {}", decodedThemeName, limit);
            List<LullabyVideoTheme> videos = lullabyService.searchVideosByTheme(decodedThemeName, limit);
            return ResponseEntity.ok(ApiResponse.success(videos,
                    "'" + decodedThemeName + "' 테마에서 " + videos.size() + "개의 영상을 찾았습니다."));
        } catch (Exception e) {
            log.error("❌ [LullabyController] 테마별 영상 검색 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("테마별 영상 검색 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/combined/{themeName}")
    public ResponseEntity<ApiResponse<CombinedLullabyContent>> searchCombinedContent(
            @PathVariable String themeName,
            @RequestParam(defaultValue = "5") int limit
    ) {
        try {
            String decodedThemeName = URLDecoder.decode(themeName, StandardCharsets.UTF_8);
            log.info("🔍 [LullabyController] 통합 검색 요청: {}", decodedThemeName);

            // 음악과 영상을 동시에 검색
            List<LullabyTheme> music = lullabyService.searchByTheme(decodedThemeName, limit);
            List<LullabyVideoTheme> videos = lullabyService.searchVideosByTheme(decodedThemeName, limit);

            CombinedLullabyContent combined = CombinedLullabyContent.builder()
                    .music(music)
                    .videos(videos)
                    .theme(decodedThemeName)
                    .totalCount(music.size() + videos.size())
                    .build();

            return ResponseEntity.ok(ApiResponse.success(combined,
                    "'" + decodedThemeName + "' 테마에서 음악 " + music.size() + "개, 영상 " + videos.size() + "개를 찾았습니다."));
        } catch (Exception e) {
            log.error("❌ [LullabyController] 통합 검색 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("통합 검색 중 오류가 발생했습니다."));
        }
    }

    // ==================== 공통 기능 API ====================

    @GetMapping("/available-themes")
    public ResponseEntity<ApiResponse<List<String>>> getAvailableThemes() {
        try {
            List<String> themes = lullabyService.getAvailableThemes();
            return ResponseEntity.ok(ApiResponse.success(themes,
                    themes.size() + "개의 테마가 있습니다."));
        } catch (Exception e) {
            log.error("테마 목록 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("테마 목록 조회 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/python-health")
    public ResponseEntity<ApiResponse<String>> checkPythonApiHealth() {
        try {
            boolean isHealthy = lullabyService.isPythonApiHealthy();
            if (isHealthy) {
                return ResponseEntity.ok(ApiResponse.success("OK", "파이썬 API 서버가 정상 작동 중입니다."));
            } else {
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                        .body(ApiResponse.error("파이썬 API 서버에 연결할 수 없습니다."));
            }
        } catch (Exception e) {
            log.error("파이썬 API 헬스체크 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("헬스체크 중 오류가 발생했습니다."));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> healthCheck() {
        return ResponseEntity.ok(ApiResponse.success("OK", "스프링부트 서버가 정상 작동 중입니다."));
    }
}