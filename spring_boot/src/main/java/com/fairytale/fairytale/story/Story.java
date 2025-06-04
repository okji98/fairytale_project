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

    @Column(length = 500, nullable = false)
    private String theme;

    @Column(length = 100, nullable = false)
    private String voice;

    @Column(length = 100, nullable = true)
    private String imageMode;

    @Column(length = 500, nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    // nullable = true로 변경 (나중에 추가되는 필드들)
    @Column(length = 500, nullable = true)
    private String voiceContent;

    @Column(length = 500, nullable = true)
    private String colorImage;

    @Column(length = 500, nullable = true)
    private String blackImage;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "users_id")
    private Users user;
}

