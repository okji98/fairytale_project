package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StoryCreateRequest {
    private String theme;
    private String voice;
    private String imageMode;
<<<<<<< HEAD
    private String name;
    private String voiceSpeed;
=======
    private String title;
    private Long userId; // 사용자 정보
>>>>>>> ff499d6d3234cd9769f50af99afea5d983c6a701
}
