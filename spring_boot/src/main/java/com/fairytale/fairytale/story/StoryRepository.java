package com.fairytale.fairytale.story;

import com.fairytale.fairytale.users.Users;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StoryRepository extends JpaRepository<Story,Long> {
    Optional<Story> findByIdAndUser(Long id, Users user);
}
