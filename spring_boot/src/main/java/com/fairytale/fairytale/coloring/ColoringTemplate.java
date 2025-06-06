package com.fairytale.fairytale.coloring;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "coloring_templates")
@Getter
@Setter
public class ColoringTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(name = "story_id", nullable = false)
    private String storyId;

    @Column(name = "original_image_url", nullable = false, length = 500)
    private String originalImageUrl;  // 원본 컬러 이미지 URL

    @Column(name = "black_white_image_url", nullable = false, length = 500)
    private String blackWhiteImageUrl;  // 흑백 변환된 이미지 URL

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // 기본 생성자
    public ColoringTemplate() {
    }

    // Builder 패턴용 생성자
    public ColoringTemplate(String title, String storyId, String originalImageUrl, String blackWhiteImageUrl) {
        this.title = title;
        this.storyId = storyId;
        this.originalImageUrl = originalImageUrl;
        this.blackWhiteImageUrl = blackWhiteImageUrl;
    }

    // Builder 패턴
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private String title;
        private String storyId;
        private String originalImageUrl;
        private String blackWhiteImageUrl;

        public Builder title(String title) {
            this.title = title;
            return this;
        }

        public Builder storyId(String storyId) {
            this.storyId = storyId;
            return this;
        }

        public Builder originalImageUrl(String originalImageUrl) {
            this.originalImageUrl = originalImageUrl;
            return this;
        }

        public Builder blackWhiteImageUrl(String blackWhiteImageUrl) {
            this.blackWhiteImageUrl = blackWhiteImageUrl;
            return this;
        }

        public ColoringTemplate build() {
            return new ColoringTemplate(title, storyId, originalImageUrl, blackWhiteImageUrl);
        }
    }

    @Override
    public String toString() {
        return "ColoringTemplate{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", storyId='" + storyId + '\'' +
                ", originalImageUrl='" + originalImageUrl + '\'' +
                ", blackWhiteImageUrl='" + blackWhiteImageUrl + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
}