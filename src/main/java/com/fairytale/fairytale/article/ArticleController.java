package com.fairytale.fairytale.article;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class ArticleController {
    private final ArticleService articleService;
}
