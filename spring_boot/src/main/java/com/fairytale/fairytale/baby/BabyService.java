package com.fairytale.fairytale.baby;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class BabyService {
    private final BabyRepository babyRepository;
}
