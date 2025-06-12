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

        SharePost savedPost = sharePostRepository.save(sharePost);
        log.info("✅ Stories 공유 완료 - SharePostId: {}", savedPost.getId());

        return convertToDTO(savedPost);
    }

    /**
     * Gallery에서 공유
     */
    public SharePostDTO shareFromGallery(Long galleryId, String username) {
        log.info("🎬 Gallery에서 공유 시작 - GalleryId: {}, 사용자: {}", galleryId, username);

        // 1. 사용자 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        // 2. Gallery 조회
        Gallery gallery = galleryRepository.findById(galleryId)
                .orElseThrow(() -> new RuntimeException("갤러리 항목을 찾을 수 없습니다: " + galleryId));

        if (!gallery.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("갤러리 항목에 대한 권한이 없습니다.");
        }

        // 3. 원본 스토리 조회 (음성 파일 필요)
        Story story = storyRepository.findById(gallery.getStoryId())
                .orElseThrow(() -> new RuntimeException("원본 스토리를 찾을 수 없습니다: " + gallery.getStoryId()));

        // 4. 사용할 이미지 결정 (색칠한 이미지 우선, 없으면 컬러 이미지)
        String imageUrl = gallery.getColoringImageUrl() != null ?
                gallery.getColoringImageUrl() : gallery.getColorImageUrl();

        if (imageUrl == null || imageUrl.isEmpty()) {
            throw new RuntimeException("공유할 이미지가 없습니다.");
        }

        if (story.getVoiceContent() == null || story.getVoiceContent().isEmpty()) {
            throw new RuntimeException("음성이 없는 갤러리 항목은 공유할 수 없습니다.");
        }

        // 5. 비디오 생성
        String videoUrl = videoService.createVideoFromImageAndAudio(
                imageUrl,
                story.getVoiceContent(),
                gallery.getStoryTitle()
        );

        // 6. 썸네일 생성
        String thumbnailUrl = imageUrl; // 기본적으로 갤러리 이미지 사용
        try {
            String generatedThumbnail = videoService.createThumbnail(videoUrl);
            if (generatedThumbnail != null) {
                thumbnailUrl = generatedThumbnail;
            }
        } catch (Exception e) {
            log.warn("⚠️ 썸네일 생성 실패, 원본 이미지 사용: {}", e.getMessage());
        }

        // 7. SharePost 생성 및 저장
        SharePost sharePost = new SharePost();
        sharePost.setUser(user);
        sharePost.setStoryTitle(gallery.getStoryTitle());
        sharePost.setVideoUrl(videoUrl);
        sharePost.setThumbnailUrl(thumbnailUrl);
        sharePost.setSourceType("GALLERY");
        sharePost.setSourceId(galleryId);

        SharePost savedPost = sharePostRepository.save(sharePost);
        log.info("✅ Gallery 공유 완료 - SharePostId: {}", savedPost.getId());

        return convertToDTO(savedPost);
    }

    /**
     * 모든 공유 게시물 조회
     */
    public List<SharePostDTO> getAllSharePosts() {
        log.info("🔍 모든 공유 게시물 조회");

        List<SharePost> posts = sharePostRepository.findAllByOrderByCreatedAtDesc();
        return posts.stream()
                .map(this::convertToDTO)
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
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * 공유 게시물 삭제
     */
    public boolean deleteSharePost(Long postId, String username) {
        log.info("🗑️ 공유 게시물 삭제 - PostId: {}, 사용자: {}", postId, username);

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + username));

        SharePost post = sharePostRepository.findById(postId).orElse(null);

        if (post != null && post.getUser().getId().equals(user.getId())) {
            sharePostRepository.delete(post);
            log.info("✅ 공유 게시물 삭제 완료");
            return true;
        } else {
            log.warn("⚠️ 삭제할 게시물이 없거나 권한이 없음");
            return false;
        }
    }

    /**
     * SharePost를 DTO로 변환
     */
    private SharePostDTO convertToDTO(SharePost post) {
        // Users 엔티티에서 사용자명 가져오기 (getName() 메서드가 없을 수 있으므로 안전하게 처리)
        String userName;
        try {
            userName = post.getUser().getName();
            if (userName == null || userName.isEmpty()) {
                userName = post.getUser().getUsername();
            }
        } catch (Exception e) {
            userName = post.getUser().getUsername();
        }

        return SharePostDTO.builder()
                .id(post.getId())
                .userName(userName)
                .storyTitle(post.getStoryTitle())
                .videoUrl(post.getVideoUrl())
                .thumbnailUrl(post.getThumbnailUrl())
                .sourceType(post.getSourceType())
                .createdAt(post.getCreatedAt())
                .build();
    }
}