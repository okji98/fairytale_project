package com.fairytale.fairytale.story.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ImageRequest {
    private Long storyId;
    private String description;
    private String imageMode; // "color" or "black"
<<<<<<< HEAD
    private String prompt;
=======
>>>>>>> ff499d6d3234cd9769f50af99afea5d983c6a701
}
