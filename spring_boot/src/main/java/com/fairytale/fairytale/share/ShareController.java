// src/main/java/com/fairytale/fairytale/share/ShareController.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.share.dto.SharePostDTO;
import com.fairytale.fairytale.share.dto.ShareRequestDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/share")
@RequiredArgsConstructor
public class ShareController {

    private final ShareService shareService;

    /**
     * Stories에서 공유 (비디오 생성 및 업로드)
     */
    @PostMapping("/story/{storyId}")
    public ResponseEntity<SharePostDTO> shareFromStory(
            @PathVariable Long storyId,
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🎬 Stories 공유 요청 - StoryId: {}, 사용자: {}", storyId, username);

            SharePostDTO sharePost = shareService.shareFromStory(storyId, username);

            log.info("✅ Stories 공유 완료 - PostId: {}", sharePost.getId());
            return ResponseEntity.ok(sharePost);

        } catch (Exception e) {
            log.error("❌ Stories 공유 실패: {}", e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * Gallery에서 공유 (비디오 생성 및 업로드)
     */
    @PostMapping("/gallery/{galleryId}")
    public ResponseEntity<SharePostDTO> shareFromGallery(
            @PathVariable Long galleryId,
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🎬 Gallery 공유 요청 - GalleryId: {}, 사용자: {}", galleryId, username);

            SharePostDTO sharePost = shareService.shareFromGallery(galleryId, username);

            log.info("✅ Gallery 공유 완료 - PostId: {}", sharePost.getId());
            return ResponseEntity.ok(sharePost);

        } catch (Exception e) {
            log.error("❌ Gallery 공유 실패: {}", e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 모든 공유 게시물 조회
     */
    @GetMapping("/posts")
    public ResponseEntity<List<SharePostDTO>> getAllSharePosts() {
        try {
            log.info("🔍 모든 공유 게시물 조회 요청");

            List<SharePostDTO> posts = shareService.getAllSharePosts();

            log.info("✅ 공유 게시물 조회 완료 - 개수: {}", posts.size());
            return ResponseEntity.ok(posts);

        } catch (Exception e) {
            log.error("❌ 공유 게시물 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 내 공유 게시물 조회
     */
    @GetMapping("/my-posts")
    public ResponseEntity<List<SharePostDTO>> getMySharePosts(Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🔍 내 공유 게시물 조회 요청 - 사용자: {}", username);

            List<SharePostDTO> posts = shareService.getUserSharePosts(username);

            log.info("✅ 내 공유 게시물 조회 완료 - 개수: {}", posts.size());
            return ResponseEntity.ok(posts);

        } catch (Exception e) {
            log.error("❌ 내 공유 게시물 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }

    /**
     * 공유 게시물 삭제
     */
    @DeleteMapping("/posts/{postId}")
    public ResponseEntity<Map<String, String>> deleteSharePost(
            @PathVariable Long postId,
            Authentication auth) {
        try {
            String username = auth.getName();
            log.info("🗑️ 공유 게시물 삭제 요청 - PostId: {}, 사용자: {}", postId, username);

            boolean deleted = shareService.deleteSharePost(postId, username);

            if (deleted) {
                log.info("✅ 공유 게시물 삭제 완료");
                return ResponseEntity.ok(Map.of("message", "게시물이 삭제되었습니다."));
            } else {
                log.warn("⚠️ 삭제할 게시물 없음 또는 권한 없음");
                return ResponseEntity.status(404).body(Map.of("error", "삭제할 게시물을 찾을 수 없습니다."));
            }

        } catch (Exception e) {
            log.error("❌ 공유 게시물 삭제 실패: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of("error", "게시물 삭제 중 오류가 발생했습니다."));
        }
    }
}