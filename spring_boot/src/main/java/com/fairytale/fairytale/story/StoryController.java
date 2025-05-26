package com.fairytale.fairytale.story;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class StoryController {
  private final StoryService storyService;
}
