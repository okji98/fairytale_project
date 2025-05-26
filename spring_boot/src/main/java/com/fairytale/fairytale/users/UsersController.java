package com.fairytale.fairytale.users;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class UsersController {
    private final UsersService usersService;
}
