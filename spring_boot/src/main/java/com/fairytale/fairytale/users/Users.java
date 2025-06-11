package com.fairytale.fairytale.users;

import com.fairytale.fairytale.article.Article;
import com.fairytale.fairytale.baby.Baby;
import com.fairytale.fairytale.like.Like;
import com.fairytale.fairytale.role.Role;
import com.fairytale.fairytale.story.Story;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_user_username", columnList = "username"),
        @Index(name = "idx_user_nickname", columnList = "nickname"),
        @Index(name = "idx_user_email", columnList = "email"),
        @Index(name = "idx_user_google_id", columnList = "googleId"),
        @Index(name = "idx_user_kakao_id", columnList = "kakaoId"),
//        @Index(name = "idx_user_apple_id", columnList = "appleId")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Users {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String username;

    @Column(nullable = false, unique = true, length = 100)
    private String nickname;

    @Column(unique = true, length = 200)
    private String email;

    @Column(length = 512)
    private String hashedPassword;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id")
    private Role role;

    @Column(unique = true, length = 100)
    private String googleId;

    @Column(unique = true, length = 100)
    private String kakaoId;

    // 🆕 프로필 이미지 URL 필드 추가
    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Story> stories;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Article> articles;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Baby> babies;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Like> likes;
}