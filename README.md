# 엄빠, 읽어도! - Spring Boot Backend

> AI 기반 맞춤형 동화 생성 서비스의 백엔드 시스템

## 프로젝트 개요

**엄빠, 읽어도!**는 아이의 이름을 주인공으로 하는 맞춤형 동화를 AI가 자동으로 생성해주는 서비스입니다. Spring Boot 기반의 RESTful API 서버로, Flutter 모바일 앱과 Python FastAPI AI 서버 간의 중계 역할을 담당합니다.

### 개발 기간
2025.05.26 ~ 2025.06.20 (약 4주)

### 담당 역할
- Spring Boot 기반 REST API 설계 및 구현
- OAuth 2.0 소셜 로그인 시스템 구축
- AI 모델 연동 및 데이터 파이프라인 구축
- AWS S3 기반 파일 스토리지 시스템 구현
- PostgreSQL 데이터베이스 설계 및 최적화

<h2 align="center">
  <a href="https://drive.google.com/file/d/1ZQlYuZHxGLPDVm8vBhs119AdJ2-UDbcF/view?usp=drive_link">
    🐻 발표 프레젠테이션 바로가기 🐻
  </a>
</h2>
**🎬 [전체 기능 시연 영상 보러가기 (Google Drive)](https://drive.google.com/file/d/1HkP3rK_5qtfcg8hXmDyoQNy0OKI3PBoe/preview?autoplay=1)**

## 기술 스택

### Backend
- Java 17
- Spring Boot 3.x
- Spring Security + JWT
- Spring Data JPA / Hibernate
- PostgreSQL
- Gradle

### Infrastructure
- AWS EC2 (t3.large, Ubuntu 20.04)
- AWS RDS (PostgreSQL 14)
- AWS S3

### External Integration
- OAuth 2.0 (Google, Kakao)
- OpenAI API (GPT-4, TTS)
- Stable Diffusion API
- Python FastAPI Server

## 프로젝트 구조

<details>
<summary><strong>⚙️ 백엔드 (RestfulAPI) 폴더 구조 보기</strong></summary>

```
src/main/java/com/fairytale/
├── 📁 auth/                    # 인증/인가 시스템
│   ├── 📁 controller/          # OAuth 엔드포인트
│   ├── 📁 dto/                 # 토큰 관련 DTO
│   ├── 📁 repository/          # Refresh Token 저장소
│   ├── 📁 service/             # 인증 비즈니스 로직
│   └── 📁 strategy/            # 인증 전략 패턴 구현
│       ├── AuthStrategy.java   # 전략 인터페이스
│       ├── JwtAuthStrategy.java # JWT 구현체
│       └── JwtAuthenticationFilter.java # 보안 필터
│
├── 📁 story/                   # 동화 생성 관리
│   ├── Story.java              # 동화 엔티티
│   ├── StoryController.java    # REST API 엔드포인트
│   ├── StoryService.java       # 비즈니스 로직
│   └── 📁 dto/                 # FastAPI 통신 DTO
│       ├── FastApiStoryRequest.java
│       ├── FastApiImageRequest.java
│       └── FastApiVoiceRequest.java
│
├── 📁 coloring/                # 색칠 기능
│   ├── ColoringTemplate.java   # 색칠 템플릿 엔티티
│   ├── ColoringWork.java       # 사용자 작품 엔티티
│   └── ColoringTemplateService.java # 이미지 변환 로직
│
├── 📁 share/                   # 커뮤니티 기능
│   ├── SharePost.java          # 공유 게시물 엔티티
│   ├── ShareService.java       # 좋아요, 권한 관리
│   └── 📁 dto/
│
├── 📁 gallery/                 # 갤러리 시스템
│   └── 📁 dto/
│       └── GalleryStatsDTO.java # 통계 정보
│
├── 📁 service/                 # 공통 서비스
│   ├── S3Service.java          # AWS S3 파일 업로드
│   └── VideoService.java       # 동영상 처리
│
└── 📁 config/                  # 설정 파일
    ├── SecurityConfig.java     # Spring Security 설정
    ├── S3Config.java           # AWS S3 설정
    └── WebConfig.java          # CORS 설정
```

</details>

## 핵심 구현 사항

### 1. OAuth 2.0 소셜 로그인 시스템

#### Strategy Pattern을 활용한 확장 가능한 인증 구조
```java
public interface AuthStrategy {
    String authenticate(Users user, Long durationMs);
    boolean isValid(String token);
    String getUsername(String token);
    Authentication getAuthentication(String token);
}
```

#### 특징
- Google, Kakao OAuth 2.0 구현
- JWT 기반 토큰 관리 (Access Token: 1시간, Refresh Token: 14일)
- 중복 가입 방지 로직 (동일 이메일 체크)
- RestTemplate을 활용한 사용자 정보 조회

### 2. AI 모델 통합 시스템

#### 동화 생성 파이프라인
```java
@Transactional
public Story createStory(StoryCreateRequest request, String username) {
    // 1. 아이 정보 조회
    Baby baby = babyRepository.findById(request.getBabyId())
        .orElseThrow(() -> new RuntimeException("아이 정보를 찾을 수 없습니다"));
    
    // 2. FastAPI로 동화 생성 요청
    String storyContent = callFastApi(fastApiBaseUrl + "/generate/story", 
                                     createStoryRequest(baby, request));
    
    // 3. 이미지 생성 (비동기)
    CompletableFuture<String> imageFuture = generateImage(storyContent);
    
    // 4. 음성 생성 (비동기)
    CompletableFuture<String> voiceFuture = generateVoice(storyContent);
    
    // 5. 결과 저장 및 반환
    return saveStory(story, imageFuture.get(), voiceFuture.get());
}
```

#### 이미지 처리 최적화
- Stable Diffusion API를 통한 고품질 이미지 생성
- OpenCV 기반 흑백 변환으로 색칠 템플릿 자동 생성
- 비동기 처리로 응답 시간 단축

### 3. 파일 스토리지 시스템

#### S3 업로드 서비스
```java
@Service
public class S3Service {
    public String uploadFile(MultipartFile file, String folder) {
        String fileName = generateUniqueFileName(file);
        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentType(file.getContentType());
        
        amazonS3.putObject(new PutObjectRequest(
            bucketName, 
            folder + "/" + fileName, 
            file.getInputStream(), 
            metadata
        ));
        
        return amazonS3.getUrl(bucketName, folder + "/" + fileName).toString();
    }
}
```

#### 특징
- 이미지, 음성 파일 안전한 저장
- 폴더 구조로 체계적 관리
- 메타데이터 보존

### 4. 커뮤니티 기능

#### 좋아요 시스템
```java
@Entity
public class SharePost {
    @ManyToMany
    @JoinTable(name = "share_post_likes")
    private Set<Users> likedUsers = new HashSet<>();
    
    private Integer likeCount = 0;
}
```

#### 특징
- Set 자료구조로 중복 좋아요 방지
- 카운트 필드로 조회 성능 최적화
- 작성자 권한 검증 시스템

## 성능 최적화

### 1. JPA N+1 문제 해결
```java
@Query("SELECT s FROM Story s JOIN FETCH s.baby WHERE s.user = :user")
List<Story> findAllByUserWithBaby(@Param("user") Users user);
```

### 2. 비동기 처리
- 이미지/음성 생성 시 `@Async` 활용
- CompletableFuture로 병렬 처리

### 3. 데이터베이스 인덱싱
- 자주 조회되는 user_id, baby_id에 인덱스 추가
- 복합 인덱스로 조회 성능 개선

## 트러블슈팅

### 1. 소셜 로그인 토큰 처리 문제
**문제**: OAuth accessToken으로 사용자 정보 조회 실패  
**원인**: Provider별 API 엔드포인트와 응답 형식 차이  
**해결**: RestTemplate을 활용한 Provider별 처리 로직 구현

### 2. 대용량 이미지 처리로 인한 타임아웃
**문제**: 동기 처리로 인한 응답 지연 (30초 이상)  
**원인**: 이미지 생성 + 흑백 변환 + S3 업로드 순차 처리  
**해결**: @Async + CompletableFuture로 비동기 병렬 처리

### 3. 동시성 이슈로 인한 중복 좋아요
**문제**: 빠른 클릭 시 중복 좋아요 발생  
**원인**: 트랜잭션 격리 수준 문제  
**해결**: Set 자료구조 + @Transactional 격리 수준 조정

## API 문서

### 인증 관련
| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| POST | `/api/auth/login` | 소셜 로그인 | `{accessToken, provider}` |
| POST | `/api/auth/refresh` | 토큰 갱신 | `{refreshToken}` |

### 동화 관리
| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| POST | `/api/stories` | 동화 생성 | `{babyId, theme}` |
| GET | `/api/stories` | 동화 목록 조회 | - |
| GET | `/api/stories/{id}` | 동화 상세 조회 | - |
| DELETE | `/api/stories/{id}` | 동화 삭제 | - |

### 커뮤니티
| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| GET | `/api/share` | 공유 게시물 목록 | - |
| POST | `/api/share/{id}/like` | 좋아요 토글 | - |
| DELETE | `/api/share/{id}` | 게시물 삭제 | - |

## 프로젝트 성과

- **동화 생성 시간 단축**: 동기 처리 대비 60% 단축 (30초 → 12초)
- **API 응답 시간**: 평균 200ms 이하 유지
- **동시 접속자 처리**: 100명 동시 접속 안정적 처리
- **코드 재사용성**: Strategy Pattern으로 인증 모듈 확장성 확보

## 향후 개선 사항

- Redis 도입으로 캐싱 시스템 구축
- WebSocket을 활용한 실시간 동화 생성 진행률 표시
- 마이크로서비스 아키텍처로 전환
- 테스트 커버리지 80% 이상 달성

## 로컬 실행 방법

```bash
# 1. 저장소 클론
git clone https://github.com/okji98/fairytale_project.git

# 2. 환경 변수 설정
cp application.yml.example application.yml

# 3. 빌드 및 실행
./gradlew build
./gradlew bootRun
```

---

**개발자**: 옥현우  
**이메일**: dnflsmstltk10@gmail.com  
**GitHub**: [github.com/okji98](https://github.com/okji98)
