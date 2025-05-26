package com.fairytale.fairytale.story;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StoryService {
    private final StoryRepository storyRepository;
}
