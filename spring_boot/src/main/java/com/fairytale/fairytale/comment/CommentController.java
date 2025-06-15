// src/main/java/com/fairytale/fairytale/comment/CommentController.java
package com.fairytale.fairytale.comment;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/share/comments") // 🎯 경로 확인
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    /**
     * 🗨️ 댓글 작성
     */
    @PostMapping("/{sharePostId}")
    public ResponseEntity<?> createComment(
            @PathVariable Long sharePostId,
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        try {
            String username = authentication.getName();
            String content = request.get("content");

            log.info("🗨️ 댓글 작성 - SharePostId: {}, Username: {}", sharePostId, username);

            if (content == null || content.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("success", false, "error", "댓글 내용을 입력해주세요"));
            }

            Comment comment = commentService.createComment(sharePostId, username, content.trim());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("comment", convertCommentToDTO(comment));
            response.put("message", "댓글이 작성되었습니다");

            log.info("✅ 댓글 작성 완료 - CommentId: {}", comment.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 작성 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 📖 특정 게시물의 댓글 조회
     */
    @GetMapping("/{sharePostId}")
    public ResponseEntity<?> getComments(
            @PathVariable Long sharePostId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        try {
            log.info("📖 댓글 조회 - SharePostId: {}", sharePostId);

            Page<Comment> comments = commentService.getCommentsBySharePostId(
                    sharePostId, PageRequest.of(page, size));

            List<Map<String, Object>> commentDTOs = comments.getContent()
                    .stream()
                    .map(this::convertCommentToDTO)
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("comments", commentDTOs);
            response.put("totalElements", comments.getTotalElements());
            response.put("totalPages", comments.getTotalPages());
            response.put("currentPage", page);

            log.info("✅ 댓글 조회 완료 - {}개", commentDTOs.size());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 조회 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * ✏️ 댓글 수정
     */
    @PutMapping("/{commentId}")
    public ResponseEntity<?> updateComment(
            @PathVariable Long commentId,
            @RequestBody Map<String, String> request,
            Authentication authentication) {

        try {
            String username = authentication.getName();
            String content = request.get("content");

            log.info("✏️ 댓글 수정 - CommentId: {}, Username: {}", commentId, username);

            if (content == null || content.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("success", false, "error", "댓글 내용을 입력해주세요"));
            }

            Comment comment = commentService.updateComment(commentId, username, content.trim());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("comment", convertCommentToDTO(comment));
            response.put("message", "댓글이 수정되었습니다");

            log.info("✅ 댓글 수정 완료 - CommentId: {}", comment.getId());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 수정 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 🗑️ 댓글 삭제
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<?> deleteComment(
            @PathVariable Long commentId,
            Authentication authentication) {

        try {
            String username = authentication.getName();

            log.info("🗑️ 댓글 삭제 - CommentId: {}, Username: {}", commentId, username);

            commentService.deleteComment(commentId, username);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "댓글이 삭제되었습니다");

            log.info("✅ 댓글 삭제 완료 - CommentId: {}", commentId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 삭제 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 🔢 게시물별 댓글 개수 조회
     */
    @GetMapping("/count/{sharePostId}")
    public ResponseEntity<?> getCommentCount(@PathVariable Long sharePostId) {
        try {
            long count = commentService.getCommentCount(sharePostId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("commentCount", count);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ 댓글 개수 조회 실패: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    /**
     * 🔧 Comment 엔티티를 DTO로 변환 (수정됨)
     */
    /**
     * 🔧 Comment 엔티티를 DTO로 변환 (가장 간단한 수정)
     */
    private Map<String, Object> convertCommentToDTO(Comment comment) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", comment.getId());
        dto.put("content", comment.getContent());
        dto.put("username", comment.getUsername());

        // 🎯 getUserName() 대신 임시로 username 사용
        String displayName = comment.getUsername() + "님";
        dto.put("userName", displayName);

        dto.put("createdAt", comment.getCreatedAt().toString());
        dto.put("updatedAt", comment.getUpdatedAt() != null ?
                comment.getUpdatedAt().toString() : null);
        dto.put("isEdited", comment.getUpdatedAt() != null);

        return dto;
    }
}