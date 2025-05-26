package com.fairytale.fairytale.baby;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class BabyController {
    private final BabyService babyService;
}
