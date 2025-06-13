package com.fairytale.fairytale.gallery.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GalleryImageDTO {
    private Long storyId;
    private String storyTitle;
    private String colorImageUrl;      // 컬러 이미지 URL (Story 테이블에서)
    private String coloringImageUrl;   // 색칠한 이미지 URL (Gallery 테이블에서)
    private LocalDateTime createdAt;
    @Builder.Default
    private boolean isColoringWork = false; // 색칠 완성작 여부
}