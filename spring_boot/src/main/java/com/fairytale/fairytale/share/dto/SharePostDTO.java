// src/main/java/com/fairytale/fairytale/share/dto/SharePostDTO.java
package com.fairytale.fairytale.share.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class SharePostDTO {
    private Long id;
    private String userName;
    private String storyTitle;
    private String videoUrl;
    private String thumbnailUrl;
    private String sourceType;
    private LocalDateTime createdAt;
}