package com.fairytale.fairytale.story;

import com.fairytale.fairytale.users.Users;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "story", indexes = {
        @Index(name = "idx_theme", columnList = "theme"),
        @Index(name = "idx_voice", columnList = "voice"),
        @Index(name = "idx_title", columnList = "title")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Story {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 100, nullable = false)
    private String theme;

    @Column(length = 100, nullable = false)
    private String voice;

    @Column(length = 100, nullable = false)
    private String imageMode;

    @Column(length = 100, nullable = false)
    private String title;

    @Column(length = 100, nullable = false)
    private String content;

    @Column(length = 255, nullable = false)
    private String voiceContent;

    @Column(length = 255, nullable = false)
    private String colorImage;

    @Column(length = 255, nullable = false)
    private String blackImage;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "users_id")
    private Users user;
}

