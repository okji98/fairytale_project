// src/main/java/com/fairytale/fairytale/share/ShareService.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.gallery.Gallery;
import com.fairytale.fairytale.gallery.GalleryRepository;
import com.fairytale.fairytale.service.VideoService;
import com.fairytale.fairytale.share.dto.SharePostDTO;
import com.fairytale.fairytale.story.Story;
import com.fairytale.fairytale.story.StoryRepository;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ShareService {

    private final SharePostRepository sharePostRepository;
    private final StoryRepository storyRepository;
    private final GalleryRepository galleryRepository;
    private final UsersRepository usersRepository;
    private final VideoService videoService;

    /**
     * Stories에서 비디오 생성 및 공유
     */
    public SharePostDTO shareFromStory(Long storyId, String username) {
        log.info("🎬 Stories에서 공유 시작 - StoryId: {}, 사용자: {}", storyId, username);

        // 1. 사용자 및 스토리 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        Story story = storyRepository.findByIdAndUser(storyId, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다: " + storyId));

        // 2. 필수 데이터 검증
        if (story.getImage() == null || story.getImage().isEmpty()) {
            throw new RuntimeException("이미지가 없는 스토리는 공유할 수 없습니다.");
        }

        if (story.getVoiceContent() == null || story.getVoiceContent().isEmpty()) {
            throw new RuntimeException("음성이 없는 스토리는 공유할 수 없습니다.");
        }

        // 3. 비디오 생성
        String videoUrl = videoService.createVideoFromImageAndAudio(
                story.getImage(),
                story.getVoiceContent(),
                story.getTitle()
        );

        // 4. 썸네일 생성 (실패해도 진행)
        String thumbnailUrl = story.getImage(); // 기본적으로 스토리 이미지 사용
        try {
            String generatedThumbnail = videoService.createThumbnail(videoUrl);
            if (generatedThumbnail != null) {
                thumbnailUrl = generatedThumbnail;
            }
        } catch (Exception e) {
            log.warn("⚠️ 썸네일 생성 실패, 원본 이미지 사용: {}", e.getMessage());
        }

        // 5. SharePost 생성 및 저장
        SharePost sharePost = new SharePost();
        sharePost.setUser(user);
        sharePost.setStoryTitle(story.getTitle());
        sharePost.setVideoUrl(videoUrl);
        sharePost.setThumbnailUrl(thumbnailUrl);
        sharePost.setSourceType("STORY");
        sharePost.setSourceId(storyId);
        sharePost.setChildName(story.getChildName()); // 아이 이름 설정

        SharePost savedPost = sharePostRepository.save(sharePost);
        log.info("✅ Stories 공유 완료 - SharePostId: {}", savedPost.getId());

        return convertToDTO(savedPost, user);
    }

    /**
     * Gallery에서 공유 (이미지만 업로드)
     */
    public SharePostDTO shareFromGallery(Long storyId, String username) {
        log.info("🖼️ Gallery에서 공유 시작 - StoryId: {}, 사용자: {}", storyId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        Gallery gallery = galleryRepository.findByStoryId(storyId)
                .orElseThrow(() -> new RuntimeException("갤러리 항목을 찾을 수 없습니다: " + storyId));

        String imageUrl = gallery.getColoringImageUrl() != null ?
                gallery.getColoringImageUrl() : gallery.getColorImageUrl();

        if (imageUrl == null || imageUrl.isEmpty()) {
            throw new RuntimeException("공유할 이미지가 없습니다.");
        }

        SharePost sharePost = new SharePost();
        sharePost.setUser(user);
        sharePost.setStoryTitle(gallery.getStoryTitle());
        sharePost.setImageUrl(imageUrl); // 이미지 URL 설정
        sharePost.setThumbnailUrl(imageUrl); // 썸네일도 같은 이미지 사용
        sharePost.setSourceType("GALLERY");
        sharePost.setSourceId(gallery.getId());         // ← 실제 갤러리 PK!
        sharePost.setChildName(gallery.getChildName()); // 아이 이름 설정
        sharePost.setUserName(gallery.getChildName() + "의 부모"); // 부모 정보
        sharePost.setVideoUrl("");

        SharePost savedPost = sharePostRepository.save(sharePost);
        log.info("✅ Gallery 공유 완료 - SharePostId: {}", savedPost.getId());

        return convertToDTO(savedPost, user);
    }


    /**
     * 모든 공유 게시물 조회 (모든 사용자의 게시물)
     */
    public List<SharePostDTO> getAllSharePosts(String currentUsername) {
        log.info("🔍 모든 공유 게시물 조회");

        Users currentUser = usersRepository.findByUsername(currentUsername).orElse(null);

        List<SharePost> posts = sharePostRepository.findAllByOrderByCreatedAtDesc();
        return posts.stream()
                .map(post -> convertToDTO(post, currentUser))
                .collect(Collectors.toList());
    }

    /**
     * 특정 사용자의 공유 게시물 조회
     */
    public List<SharePostDTO> getUserSharePosts(String username) {
        log.info("🔍 사용자 공유 게시물 조회 - 사용자: {}", username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        List<SharePost> posts = sharePostRepository.findByUserOrderByCreatedAtDesc(user);
        return posts.stream()
                .map(post -> convertToDTO(post, user))
                .collect(Collectors.toList());
    }

    /**
     * 공유 게시물 삭제 (작성자만 가능)
     */
    public boolean deleteSharePost(Long postId, String username) {
        log.info("🗑️ 공유 게시물 삭제 - PostId: {}, 사용자: {}", postId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        SharePost post = sharePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시물을 찾을 수 없습니다: " + postId));

        // 작성자 확인
        if (!post.getUser().getId().equals(user.getId())) {
            log.warn("⚠️ 삭제 권한 없음 - 작성자가 아님");
            throw new RuntimeException("게시물을 삭제할 권한이 없습니다.");
        }

        sharePostRepository.delete(post);
        log.info("✅ 공유 게시물 삭제 완료");
        return true;
    }

    /**
     * 좋아요 토글
     */
    public SharePostDTO toggleLike(Long postId, String username) {
        log.info("❤️ 좋아요 토글 - PostId: {}, 사용자: {}", postId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        SharePost post = sharePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시물을 찾을 수 없습니다: " + postId));

        if (post.isLikedBy(user)) {
            post.removeLike(user);
            log.info("💔 좋아요 취소");
        } else {
            post.addLike(user);
            log.info("❤️ 좋아요 추가");
        }

        SharePost savedPost = sharePostRepository.save(post);
        return convertToDTO(savedPost, user);
    }

    /**
     * SharePost를 DTO로 변환
     */
    private SharePostDTO convertToDTO(SharePost post, Users currentUser) {
        // 작성자 이름 포맷팅: "아이이름의 부모"
        String displayName = post.getChildName() != null && !post.getChildName().isEmpty()
                ? post.getChildName() + "의 부모"
                : post.getUser().getName();

        boolean isLiked = currentUser != null && post.isLikedBy(currentUser);
        boolean isOwner = currentUser != null && post.getUser().getId().equals(currentUser.getId());

        return SharePostDTO.builder()
                .id(post.getId())
                .userName(displayName)
                .storyTitle(post.getStoryTitle())
                .videoUrl(post.getVideoUrl())
                .imageUrl(post.getImageUrl())
                .thumbnailUrl(post.getThumbnailUrl())
                .sourceType(post.getSourceType())
                .likeCount(post.getLikeCount())
                .isLiked(isLiked)
                .isOwner(isOwner)
                .createdAt(post.getCreatedAt())
                .build();
    }
}