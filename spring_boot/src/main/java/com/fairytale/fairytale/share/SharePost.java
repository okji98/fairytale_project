// src/main/java/com/fairytale/fairytale/share/SharePost.java
package com.fairytale.fairytale.share;

import com.fairytale.fairytale.users.Users;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "share_posts")
@Getter
@Setter
@EntityListeners(AuditingEntityListener.class)
public class SharePost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Column(name = "story_title", length = 255)
    private String storyTitle;

    @Column(name = "video_url", length = 1000)
    private String videoUrl; // S3에 저장된 mp4 파일 URL

    @Column(name = "thumbnail_url", length = 1000)
    private String thumbnailUrl; // 썸네일 이미지 URL

    @Column(name = "source_type", length = 50)
    private String sourceType; // "STORY" 또는 "GALLERY"

    @Column(name = "source_id")
    private Long sourceId; // 원본 Story ID 또는 Gallery ID

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}