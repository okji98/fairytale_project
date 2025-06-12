package com.fairytale.fairytale.story;

import com.fairytale.fairytale.service.S3Service;  // S3 서비스 추가
import lombok.extern.slf4j.Slf4j;
import com.fairytale.fairytale.baby.Baby;
import com.fairytale.fairytale.baby.BabyRepository;
import com.fairytale.fairytale.story.dto.*;
import com.fairytale.fairytale.users.Users;
import com.fairytale.fairytale.users.UsersRepository;
import com.fairytale.fairytale.coloring.ColoringTemplateService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.scheduling.annotation.Async;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class StoryService {
    private final S3Service s3Service;
    private final StoryRepository storyRepository;
    private final UsersRepository usersRepository;
    private final BabyRepository babyRepository;
    private final Baby baby;

    // 🆕 색칠공부 서비스 추가
    @Autowired
    private ColoringTemplateService coloringTemplateService;

    @Value("${fastapi.base.url:http://localhost:8000}")
    private String fastApiBaseUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // 스토리
    // 🔄 기존 동화 생성 메서드 (수정됨)
    // StoryService.java - baby 정보 디버깅 (findByUser 제거)

    public Story createStory(StoryCreateRequest request, String username) {
        log.info("🔍 스토리 생성 시작 - Username: {}", username);
        log.info("🔍 받은 요청: theme={}, voice={}, babyId={}",
                request.getTheme(), request.getVoice(), request.getBabyId());

        // 1. 사용자 조회
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> {
                    log.error("❌ 사용자를 찾을 수 없음: {}", username);
                    return new RuntimeException("사용자를 찾을 수 없습니다: " + username);
                });

        log.info("🔍 사용자 조회 성공 - ID: {}", user.getId());

        // 2. 🔍 Baby 조회 강화된 디버깅
        Baby baby = null;
        String childName = "우리 아이"; // 기본값

        if (request.getBabyId() != null) {
            log.info("🔍 babyId가 제공됨: {}", request.getBabyId());

            try {
                baby = babyRepository.findById(request.getBabyId())
                        .orElseThrow(() -> new RuntimeException("아기 정보를 찾을 수 없습니다."));

                log.info("✅ Baby 엔티티 찾음 - ID: {}", baby.getId());

                // baby 객체의 모든 필드 확인
                log.info("🔍 Baby 정보 상세:");
                log.info("  - baby.getId(): {}", baby.getId());
                log.info("  - baby.getBabyName(): '{}'", baby.getBabyName());
                log.info("  - baby.getBabyName() == null: {}", baby.getBabyName() == null);

                if (baby.getBabyName() != null) {
                    log.info("  - baby.getBabyName().isEmpty(): {}", baby.getBabyName().isEmpty());
                    log.info("  - baby.getBabyName().trim(): '{}'", baby.getBabyName().trim());
                }

                if (baby.getBabyName() != null && !baby.getBabyName().trim().isEmpty()) {
                    childName = baby.getBabyName().trim();
                    log.info("✅ 유효한 아기 이름 설정: '{}'", childName);
                } else {
                    log.warn("⚠️ baby.getBabyName()이 null이거나 비어있음!");
                    log.warn("⚠️ 기본 이름 사용: '{}'", childName);
                }

            } catch (Exception e) {
                log.error("❌ babyId로 Baby 조회 실패: {}", e.getMessage());
                log.error("❌ 제공된 babyId: {}", request.getBabyId());

                // 🔍 babyRepository에 있는 메서드로 간단한 확인
                try {
                    boolean exists = babyRepository.existsById(request.getBabyId());
                    log.info("🔍 babyId {} 존재 여부: {}", request.getBabyId(), exists);

                    if (!exists) {
                        log.error("❌ 해당 babyId가 데이터베이스에 존재하지 않습니다!");
                    }
                } catch (Exception ex) {
                    log.error("❌ baby 존재 여부 확인 실패: {}", ex.getMessage());
                }
            }
        } else {
            log.warn("⚠️ babyId가 null입니다!");
            log.warn("⚠️ Flutter에서 babyId를 보내지 않았거나 null입니다.");
            log.warn("⚠️ 기본 이름 사용: '{}'", childName);

            // 🔍 StoryCreateRequest의 모든 필드 확인
            log.info("🔍 StoryCreateRequest 전체 정보:");
            log.info("  - getTheme(): '{}'", request.getTheme());
            log.info("  - getVoice(): '{}'", request.getVoice());
            log.info("  - getBabyId(): {}", request.getBabyId());
        }

        // 3. FastAPI 요청 객체 생성
        FastApiStoryRequest fastApiRequest = new FastApiStoryRequest();
        fastApiRequest.setName(childName);
        fastApiRequest.setTheme(request.getTheme() + " 동화");

        log.info("🚀 FastAPI로 전송할 데이터:");
        log.info("  - name: '{}'", childName);
        log.info("  - theme: '{}'", fastApiRequest.getTheme());

        // ❗ 여기서 "기본값" 체크
        if ("기본값".equals(childName)) {
            log.error("🚨 경고: '기본값'으로 FastAPI 호출 예정!");
            log.error("🚨 이는 baby 정보를 찾지 못했음을 의미합니다.");
        }

        // 4. FastAPI 호출
        String url = fastApiBaseUrl + "/generate/story";
        String response = callFastApi(url, fastApiRequest);

        // 5. 응답에서 story 추출
        String storyContent = extractStoryFromResponse(response);

        // 6. Story 엔티티 생성 및 저장
        Story story = new Story();
        story.setTheme(request.getTheme());
        story.setVoice(request.getVoice());
        story.setTitle(request.getTheme() + " 동화");
        story.setContent(storyContent);
        story.setUser(user);
        story.setVoiceContent("");
        story.setImage("");

        if (baby != null) {
            story.setBaby(baby);
            log.info("✅ Story에 baby 연결 완료 - baby ID: {}", baby.getId());
        } else {
            log.warn("⚠️ baby가 null이므로 Story에 baby 연결하지 않음");
        }

        log.info("🔍 스토리 저장 전 - Title: {}", story.getTitle());
        Story saved = storyRepository.save(story);
        log.info("🔍 스토리 저장 완료 - ID: {}", saved.getId());

        return saved;
    }

    // 이미지
    // 🎯 수정된 이미지 생성 메서드 (색칠공부 생성 조건 개선)
    // 🎯 수정된 이미지 생성 메서드 (색칠공부 생성 조건 개선)
    public Story createImage(ImageRequest request) {
        log.info("🔍 이미지 생성 요청 - StoryId: {}", request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        log.info("✅ 스토리 조회 성공 - Title: {}", story.getTitle());
        log.info("🔍 스토리 내용 길이: {}자", story.getContent().length());

        // 2. FastAPI 요청 데이터 (전체 스토리 내용 사용)
        Map<String, Object> fastApiRequest = new HashMap<>();
        fastApiRequest.put("text", story.getContent());

        log.info("🔍 FastAPI 이미지 생성 요청 데이터 길이: {}자", story.getContent().length());

        // 3. FastAPI로 이미지 생성
        String imageUrl = fastApiBaseUrl + "/generate/image";
        boolean isRealImageGenerated = false; // 🆕 실제 이미지 생성 여부 플래그

        try {
            String fastApiResponse = callFastApi(imageUrl, fastApiRequest);
            String localImagePath = extractImagePathFromResponse(fastApiResponse);

            log.info("🎯 로컬 이미지 생성 완료: {}", localImagePath);

            if (localImagePath == null || localImagePath.trim().isEmpty() || "null".equals(localImagePath)) {
                log.warn("❌ FastAPI에서 null 이미지 경로 반환");
                throw new RuntimeException("이미지 생성 실패");
            }

            // 🆕 4. 로컬 파일을 S3에 업로드
            String s3ImageUrl;
            try {
                s3ImageUrl = processLocalImageWithS3(localImagePath, story.getId());
                log.info("✅ S3 이미지 업로드 완료: {}", s3ImageUrl);
                isRealImageGenerated = true; // 🆕 실제 이미지 생성 성공
            } catch (Exception e) {
                log.error("❌ S3 이미지 업로드 실패: {}", e.getMessage());
                // 🔄 S3 업로드 실패시 더미 이미지 사용
                s3ImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
                isRealImageGenerated = false; // 🆕 더미 이미지 사용
            }

            // 5. Story에 S3 URL 저장
            story.setImage(s3ImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("✅ 이미지 저장 완료");

            // 🎨 6. 색칠공부 템플릿 비동기 생성 (실제 이미지인 경우만)
            if (isRealImageGenerated) {
                log.info("🎨 실제 이미지로 색칠공부 템플릿 생성 시작");
                createColoringTemplateAsync(savedStory, s3ImageUrl);
            } else {
                log.info("⚠️ 더미 이미지이므로 색칠공부 템플릿 생성 건너뜀");
            }

            return savedStory;

        } catch (Exception e) {
            log.error("❌ 이미지 생성 실패: {}", e.getMessage());

            // 실패 시 더미 이미지 사용
            String dummyImageUrl = "https://picsum.photos/800/600?random=" + System.currentTimeMillis();
            story.setImage(dummyImageUrl);
            Story savedStory = storyRepository.save(story);

            log.info("🔄 더미 이미지로 저장 완료: {}", dummyImageUrl);
            log.info("⚠️ 더미 이미지이므로 색칠공부 템플릿 생성 건너뜀");

            // 🚫 더미 이미지인 경우 색칠공부 템플릿 생성하지 않음
            return savedStory;
        }
    }

    // 🆕 로컬 이미지 파일 S3 처리 메서드 (경로 해결 개선)
    private String processLocalImageWithS3(String localImagePath, Long storyId) {
        try {
            if (localImagePath == null || localImagePath.trim().isEmpty()) {
                log.warn("⚠️ 로컬 이미지 경로가 null이거나 비어있음");
                return "";
            }

            // 🔍 파일 경로 해결 시도
            java.io.File imageFile = resolveImageFile(localImagePath);

            if (!imageFile.exists()) {
                log.error("❌ 해결된 경로에서도 파일을 찾을 수 없음: {}", imageFile.getAbsolutePath());
                throw new RuntimeException("이미지 파일을 찾을 수 없습니다: " + localImagePath);
            }

            log.info("✅ 이미지 파일 발견: {}", imageFile.getAbsolutePath());

            // 🔒 로컬 파일 경로 보안 검사
            if (!isValidImagePath(imageFile.getAbsolutePath())) {
                log.error("❌ 유효하지 않은 이미지 파일 경로: {}", imageFile.getAbsolutePath());
                throw new RuntimeException("유효하지 않은 이미지 파일 경로");
            }

            // 🎯 로컬 파일을 S3에 업로드
            log.info("📤 로컬 이미지 S3 업로드 시작: {}", imageFile.getAbsolutePath());
            String s3Url = s3Service.uploadImageFromLocalFile(imageFile.getAbsolutePath(), "story-images");
            log.info("✅ 로컬 이미지 S3 업로드 완료: {}", s3Url);

            return s3Url;

        } catch (Exception e) {
            log.error("❌ S3 로컬 이미지 처리 실패: {}", e.getMessage());
            throw new RuntimeException("S3 이미지 처리 실패", e);
        }
    }

    // 🆕 이미지 파일 경로 해결 메서드
    private java.io.File resolveImageFile(String imagePath) {
        log.info("🔍 이미지 파일 경로 해결 시작: {}", imagePath);

        // 1. 절대경로인 경우 그대로 사용
        java.io.File file = new java.io.File(imagePath);
        if (file.isAbsolute() && file.exists()) {
            log.info("✅ 절대경로로 파일 발견: {}", file.getAbsolutePath());
            return file;
        }

        // 2. 상대경로인 경우 여러 위치에서 시도
        String[] searchPaths = {
                "./",                           // 현재 작업 디렉토리
                "../python/",                   // Python 디렉토리 (상대경로)
                System.getProperty("user.dir"), // Java 실행 디렉토리
                "/tmp/",                        // 임시 디렉토리
        };

        for (String searchPath : searchPaths) {
            java.io.File searchFile = new java.io.File(searchPath, imagePath.startsWith("./") ? imagePath.substring(2) : imagePath);
            log.info("🔍 검색 시도: {}", searchFile.getAbsolutePath());

            if (searchFile.exists()) {
                log.info("✅ 파일 발견: {}", searchFile.getAbsolutePath());
                return searchFile;
            }
        }

        // 3. 파일명만 추출해서 검색
        String fileName = new java.io.File(imagePath).getName();
        for (String searchPath : searchPaths) {
            java.io.File searchFile = new java.io.File(searchPath, fileName);
            log.info("🔍 파일명으로 검색 시도: {}", searchFile.getAbsolutePath());

            if (searchFile.exists()) {
                log.info("✅ 파일명으로 파일 발견: {}", searchFile.getAbsolutePath());
                return searchFile;
            }
        }

        log.warn("❌ 모든 경로에서 파일을 찾을 수 없음");
        return file; // 원본 반환 (에러 처리는 호출자에서)
    }

    // 🔒 이미지 파일 경로 보안 검사
    private boolean isValidImagePath(String filePath) {
        try {
            log.info("🔍 이미지 경로 보안 검사: {}", filePath);

            // 1. 절대경로로 정규화 (.. 경로 해결)
            java.io.File file = new java.io.File(filePath);
            String canonicalPath = file.getCanonicalPath();
            log.info("🔍 정규화된 경로: {}", canonicalPath);

            // 2. 허용된 디렉토리 패턴들
            String[] allowedPatterns = {
                    "/tmp/",           // 임시 파일
                    "/var/folders/",   // macOS 임시 폴더
                    "/temp/",          // Windows 임시 폴더
                    "temp",            // 상대 경로 temp
                    ".png",            // png 확장자
                    ".jpg",            // jpg 확장자
                    ".jpeg",           // jpeg 확장자
                    "fairytale",       // 🆕 프로젝트 디렉토리 허용
                    "python",          // 🆕 Python 디렉토리 허용
                    "spring_boot"      // 🆕 Spring Boot 디렉토리 허용
            };

            // 3. 허용된 패턴 확인
            boolean patternMatched = false;
            for (String pattern : allowedPatterns) {
                if (canonicalPath.contains(pattern)) {
                    patternMatched = true;
                    break;
                }
            }

            if (!patternMatched) {
                log.error("❌ 허용되지 않은 디렉토리: {}", canonicalPath);
                return false;
            }

            // 4. 위험한 경로 차단 (시스템 디렉토리)
            String[] dangerousPaths = {
                    "/etc/",
                    "/bin/",
                    "/usr/bin/",
                    "/System/",
                    "C:\\Windows\\",
                    "C:\\Program Files\\",
                    "/root/",
                    "/home/",  // 🎯 다른 사용자 홈 디렉토리 차단
            };

            String lowerCanonicalPath = canonicalPath.toLowerCase();
            for (String dangerousPath : dangerousPaths) {
                if (lowerCanonicalPath.startsWith(dangerousPath.toLowerCase())) {
                    log.error("❌ 위험한 시스템 경로 접근 차단: {}", canonicalPath);
                    return false;
                }
            }

            // 5. 파일 확장자 검사
            String lowerPath = canonicalPath.toLowerCase();
            if (!lowerPath.endsWith(".png") && !lowerPath.endsWith(".jpg") &&
                    !lowerPath.endsWith(".jpeg") && !lowerPath.endsWith(".webp")) {
                log.error("❌ 허용되지 않은 파일 확장자: {}", canonicalPath);
                return false;
            }

            log.info("✅ 이미지 경로 보안 검사 통과: {}", canonicalPath);
            return true;

        } catch (Exception e) {
            log.error("❌ 이미지 경로 검사 중 오류: {}", e.getMessage());
            return false;
        }
    }


    // 🆕 색칠공부 템플릿 비동기 생성 (안전성 강화)
    @Async
    public CompletableFuture<Void> createColoringTemplateAsync(Story story, String colorImageUrl) {
        try {
            log.info("🎨 색칠공부 템플릿 비동기 생성 시작 - StoryId: {}", story.getId());

            // 🔍 URL 유효성 검사 (더미 이미지 제외)
            if (!isValidImageUrlForColoring(colorImageUrl)) {
                log.warn("⚠️ 색칠공부에 적합하지 않은 이미지 URL: {}", colorImageUrl);
                return CompletableFuture.completedFuture(null);
            }

            // ColoringTemplateService를 통해 PIL+OpenCV 변환 및 템플릿 생성
            coloringTemplateService.createColoringTemplate(
                    story.getId().toString(),
                    story.getTitle() + " 색칠하기",
                    colorImageUrl,
                    null  // 흑백 이미지는 자동 변환
            );

            log.info("✅ 색칠공부 템플릿 비동기 생성 완료");
        } catch (Exception e) {
            log.error("❌ 색칠공부 템플릿 생성 실패: {}", e.getMessage());
            // 색칠공부 템플릿 생성 실패해도 Story는 정상 처리
        }
        return CompletableFuture.completedFuture(null);
    }

    // 🔍 색칠공부에 적합한 이미지 URL 검사
    private boolean isValidImageUrlForColoring(String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return false;
        }

        // 🚫 더미 이미지 URL 제외
        if (imageUrl.contains("picsum.photos")) {
            log.info("🚫 Picsum 더미 이미지는 색칠공부에서 제외: {}", imageUrl);
            return false;
        }

        // 🚫 다른 더미/테스트 이미지 서비스들 제외
        String lowerUrl = imageUrl.toLowerCase();
        String[] dummyServices = {
                "placeholder.com",
                "via.placeholder.com",
                "dummyimage.com",
                "fakeimg.pl",
                "lorempixel.com"
        };

        for (String dummyService : dummyServices) {
            if (lowerUrl.contains(dummyService)) {
                log.info("🚫 더미 이미지 서비스 감지, 색칠공부에서 제외: {}", imageUrl);
                return false;
            }
        }

        // ✅ S3 URL이거나 유효한 외부 이미지 URL
        if (lowerUrl.contains("amazonaws.com") ||
                lowerUrl.contains("cloudfront.net") ||
                (lowerUrl.startsWith("http") &&
                        (lowerUrl.contains(".jpg") || lowerUrl.contains(".png") ||
                                lowerUrl.contains(".jpeg") || lowerUrl.contains(".webp")))) {
            return true;
        }

        log.warn("⚠️ 알 수 없는 이미지 URL 형식: {}", imageUrl);
        return false;
    }

    /**
     * 🖤 흑백 변환 및 S3 업로드 처리 (컨트롤러에서 이동)
     */
    public String convertToBlackWhiteAndUpload(String colorImageUrl) {
        try {
            log.info("🎨 흑백 변환 및 S3 업로드 시작: {}", colorImageUrl);

            if (colorImageUrl == null || colorImageUrl.isEmpty()) {
                log.warn("❌ 컬러 이미지 URL이 비어있음");
                return null;
            }

            // 1. FastAPI 흑백 변환 요청
            Map<String, String> fastApiRequest = new HashMap<>();
            fastApiRequest.put("text", colorImageUrl);

            log.info("🔍 FastAPI 흑백 변환 요청: {}", fastApiRequest);

            @SuppressWarnings("unchecked")
            Map<String, String> response = restTemplate.postForObject(
                    fastApiBaseUrl + "/convert/bwimage",
                    fastApiRequest,
                    Map.class
            );

            log.info("🔍 FastAPI 응답: {}", response);

            if (response != null && response.containsKey("image_url")) {
                String convertedUrl = response.get("image_url");

                // 2. 변환 결과 처리
                String finalImageUrl = processConvertedImageUrlForService(convertedUrl, colorImageUrl);

                log.info("✅ 흑백 변환 최종 결과: {}", finalImageUrl);
                return finalImageUrl;
            } else {
                throw new RuntimeException("FastAPI에서 유효한 응답을 받지 못했습니다.");
            }

        } catch (Exception e) {
            log.error("❌ 흑백 변환 처리 실패: {}", e.getMessage());
            return colorImageUrl; // 실패시 원본 반환
        }
    }

    /**
     * 🔧 Python 변환 결과 URL 처리 메서드 (서비스용)
     */
    private String processConvertedImageUrlForService(String convertedUrl, String originalUrl) {
        log.info("🔍 URL 처리 - 변환됨: {}, 원본: {}", convertedUrl, originalUrl);

        // 1. 완전한 URL인 경우 (S3 URL, HTTP URL, Base64 등)
        if (convertedUrl.startsWith("http://") ||
                convertedUrl.startsWith("https://") ||
                convertedUrl.startsWith("data:image/")) {
            log.info("✅ 완전한 URL 확인");
            return convertedUrl;
        }

        // 2. 로컬 파일명인 경우 - FastAPI에서 다운로드 시도
        if (convertedUrl.equals("bw_image.png") ||
                convertedUrl.endsWith(".png") ||
                convertedUrl.endsWith(".jpg")) {
            log.info("🔍 로컬 파일명 감지, FastAPI에서 다운로드 시도: {}", convertedUrl);

            // FastAPI에서 흑백 파일 다운로드 후 S3 업로드 시도
            String s3BwUrl = downloadAndUploadBwImageForService(convertedUrl, originalUrl);
            if (s3BwUrl != null) {
                log.info("✅ 흑백 이미지 S3 업로드 성공: {}", s3BwUrl);
                return s3BwUrl;
            }

            log.warn("⚠️ 흑백 이미지 처리 실패, 원본 이미지 사용");
            return originalUrl;
        }

        log.info("⚠️ 알 수 없는 형식, 원본 이미지 사용");
        return originalUrl;
    }

    /**
     * 📥 FastAPI에서 흑백 파일 다운로드 후 S3 업로드 (서비스용)
     */
    private String downloadAndUploadBwImageForService(String fileName, String originalUrl) {
        try {
            log.info("📥 FastAPI에서 흑백 파일 다운로드 시도: {}", fileName);

            // 1. FastAPI에서 흑백 파일 다운로드 요청
            String fastApiDownloadUrl = fastApiBaseUrl + "/download/bwimage/" + fileName;

            ResponseEntity<byte[]> response = restTemplate.getForEntity(fastApiDownloadUrl, byte[].class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                byte[] imageData = response.getBody();
                log.info("✅ FastAPI에서 흑백 파일 다운로드 완료: {} bytes", imageData.length);

                // 2. 임시 파일에 저장
                java.io.File tempFile = java.io.File.createTempFile("bw_temp_", ".png");
                try (java.io.FileOutputStream fos = new java.io.FileOutputStream(tempFile)) {
                    fos.write(imageData);
                }

                // 3. S3에 업로드
                String s3Url = s3Service.uploadImageFromLocalFile(tempFile.getAbsolutePath(), "bw-images");

                // 4. 임시 파일 삭제
                tempFile.delete();

                log.info("✅ 흑백 이미지 S3 업로드 완료: {}", s3Url);
                return s3Url;
            }

            log.warn("⚠️ FastAPI 흑백 파일 다운로드 실패");
            return null;

        } catch (Exception e) {
            log.error("❌ 흑백 파일 처리 실패: {}", e.getMessage());
            return null;
        }
    }

    // 🎯 s3 변경 보이스
    public Story createVoice(VoiceRequest request) {
        log.info("🔍 음성 생성 시작 - StoryId: {}", request.getStoryId());

        // 1. 기존 스토리 조회
        Story story = storyRepository.findById(request.getStoryId())
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

        log.info("🔍 스토리 조회 성공 - Content 길이: {}", story.getContent().length());

        // 2. FastAPI 요청 객체 생성 (voice, speed 추가)
        FastApiVoiceRequest fastApiRequest = new FastApiVoiceRequest();
        fastApiRequest.setText(story.getContent());
        fastApiRequest.setVoice(request.getVoice() != null ? request.getVoice() : "alloy"); // 기본값
        fastApiRequest.setSpeed(1.0); // 기본 속도

        log.info("🔍 FastAPI 음성 요청: text 길이 = {}, voice = {}",
                fastApiRequest.getText().length(), fastApiRequest.getVoice());

        // 3. FastAPI 호출
        String url = fastApiBaseUrl + "/generate/voice";
        String fastApiResponse = callFastApi(url, fastApiRequest);

        // 🆕 4. Base64 응답 파싱 및 S3 업로드
        String voiceUrl = processBase64VoiceWithS3(fastApiResponse, story.getId());
        log.info("🔍 S3 처리된 음성 URL: {}", voiceUrl);

        // 5. 저장
        story.setVoiceContent(voiceUrl);
        return storyRepository.save(story);
    }

    // 🆕 Base64 음성 데이터를 S3에 업로드하는 메서드
    private String processBase64VoiceWithS3(String fastApiResponse, Long storyId) {
        try {
            log.info("🔍 Base64 음성 처리 시작");

            // FastAPI 응답 파싱
            JsonNode jsonNode = objectMapper.readTree(fastApiResponse);

            if (!jsonNode.has("audio_base64")) {
                throw new RuntimeException("응답에 audio_base64 필드가 없습니다.");
            }

            String audioBase64 = jsonNode.get("audio_base64").asText();
            String voice = jsonNode.has("voice") ? jsonNode.get("voice").asText() : "alloy";

            log.info("🔍 Base64 데이터 길이: {} 문자", audioBase64.length());
            log.info("🔍 음성 타입: {}", voice);

            // Base64 디코딩
            byte[] audioBytes = java.util.Base64.getDecoder().decode(audioBase64);
            log.info("🔍 디코딩된 오디오 크기: {} bytes", audioBytes.length);

            // 🎯 임시 파일에 저장 후 S3 업로드
            String tempFileName = "temp_voice_" + storyId + "_" + System.currentTimeMillis() + ".mp3";
            java.io.File tempFile = new java.io.File(tempFileName);

            try (java.io.FileOutputStream fos = new java.io.FileOutputStream(tempFile)) {
                fos.write(audioBytes);
            }

            log.info("📝 임시 파일 저장 완료: {}", tempFile.getAbsolutePath());

            // S3에 업로드
            String s3Url = s3Service.uploadAudioFileWithPresignedUrl(tempFile.getAbsolutePath());
            log.info("✅ S3 업로드 완료: {}", s3Url);

            // 임시 파일 삭제
            tempFile.delete();
            log.info("🧹 임시 파일 삭제 완료");

            return s3Url;

        } catch (Exception e) {
            log.error("❌ Base64 음성 처리 실패: {}", e.getMessage());
            throw new RuntimeException("Base64 음성 처리 실패: " + e.getMessage(), e);
        }
    }


    //S3 기반 유틸리티 메서드들 추가
    /**
     * 📥 S3에서 음성 파일 직접 다운로드 (관리자용)
     */
    public byte[] downloadVoiceFromS3(String s3Url) {
        try {
            String s3Key = s3Service.extractS3KeyFromUrl(s3Url);
            if (s3Key != null) {
                return s3Service.downloadAudioFile(s3Key);
            }
            throw new RuntimeException("S3 키를 추출할 수 없습니다: " + s3Url);
        } catch (Exception e) {
            log.error("❌ S3 음성 파일 다운로드 실패: {}", e.getMessage());
            throw new RuntimeException("S3 음성 파일 다운로드 실패", e);
        }
    }

    /**
     * 🔗 임시 접근 URL 생성 (보안이 필요한 경우)
     */
    public String generateTemporaryVoiceUrl(Long storyId, int expirationMinutes) {
        try {
            Story story = storyRepository.findById(storyId)
                    .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

            String voiceUrl = story.getVoiceContent();
            if (voiceUrl == null || voiceUrl.isEmpty()) {
                throw new RuntimeException("음성 파일이 없습니다.");
            }

            String s3Key = s3Service.extractS3KeyFromUrl(voiceUrl);
            if (s3Key != null) {
                return s3Service.generateAudioPresignedUrl(s3Key, expirationMinutes);
            }

            // S3 URL이 아닌 경우 원본 반환
            return voiceUrl;

        } catch (Exception e) {
            log.error("❌ 임시 URL 생성 실패: {}", e.getMessage());
            throw new RuntimeException("임시 URL 생성 실패", e);
        }
    }

    /**
     * 🗑️ 스토리 삭제시 S3 음성 파일도 함께 삭제
     */
    public void deleteStoryWithVoiceFile(Long storyId, String username) {
        try {
            Story story = getStoryById(storyId, username);

            // S3에서 음성 파일 삭제
            String voiceUrl = story.getVoiceContent();
            if (voiceUrl != null && !voiceUrl.isEmpty()) {
                String s3Key = s3Service.extractS3KeyFromUrl(voiceUrl);
                if (s3Key != null) {
                    s3Service.deleteFile(s3Key);
                    log.info("✅ S3 음성 파일 삭제 완료: {}", s3Key);
                }
            }

            // 스토리 삭제
            storyRepository.delete(story);
            log.info("✅ 스토리 삭제 완료: {}", storyId);

        } catch (Exception e) {
            log.error("❌ 스토리 삭제 실패: {}", e.getMessage());
            throw new RuntimeException("스토리 삭제 실패", e);
        }
    }

    // 🎯 오디오 파일 경로 보안 검사 (Controller와 동일한 로직)
    private boolean isValidAudioPath(String filePath) {
        try {
            // 허용된 디렉토리 패턴들
            String[] allowedPatterns = {
                    "/tmp/",           // 임시 파일
                    "/var/folders/",   // macOS 임시 폴더
                    "/temp/",          // Windows 임시 폴더
                    "temp",            // 상대 경로 temp
                    ".mp3",            // mp3 확장자
                    ".wav",            // wav 확장자
                    ".m4a"             // m4a 확장자
            };

            // 경로에 허용된 패턴이 포함되어 있는지 확인
            for (String pattern : allowedPatterns) {
                if (filePath.contains(pattern)) {
                    // 🔥 추가 보안: 상위 디렉토리 접근 차단
                    if (filePath.contains("../") || filePath.contains("..\\")) {
                        System.out.println("❌ 상위 디렉토리 접근 시도 차단: " + filePath);
                        return false;
                    }
                    return true;
                }
            }

            return false;

        } catch (Exception e) {
            System.err.println("❌ 경로 검사 중 오류: " + e.getMessage());
            return false;
        }
    }

    // 🎯 개선된 FastAPI 호출 메서드 (더 상세한 로깅)
    private String callFastApi(String url, Object request) {
        try {
            log.info("🔍 FastAPI 호출 시작");
            log.info("🔍 URL: {}", url);
            log.info("🔍 요청 객체 타입: {}", request.getClass().getSimpleName());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            String jsonRequest = objectMapper.writeValueAsString(request);
            log.debug("🔍 FastAPI 전송 JSON: {}", jsonRequest);

            HttpEntity<String> entity = new HttpEntity<>(jsonRequest, headers);

            log.info("🔍 HTTP 요청 전송 중...");

            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            log.info("🔍 FastAPI 응답 상태코드: {}", response.getStatusCode());
            log.debug("🔍 FastAPI 응답 헤더: {}", response.getHeaders());
            log.debug("🔍 FastAPI 응답 본문: {}", response.getBody());

            if (response.getStatusCode().is2xxSuccessful()) {
                return response.getBody();
            } else {
                throw new RuntimeException("FastAPI 호출 실패. 상태코드: " + response.getStatusCode());
            }

        } catch (Exception e) {
            log.error("❌ FastAPI 호출 실패: {}", e.getMessage());
            throw new RuntimeException("FastAPI 호출 실패: " + e.getMessage(), e);
        }
    }

    // FastAPI 응답 파싱 메서드들
    private String extractStoryFromResponse(String response) {
        try {
            JsonNode jsonNode = objectMapper.readTree(response);
            return jsonNode.get("story").asText();
        } catch (Exception e) {
            // JSON 파싱 실패 시 응답 전체를 스토리로 사용
            return response;
        }
    }

    // 🎯 수정된 이미지 경로 파싱 메서드 (로컬 파일 경로 처리)
    private String extractImagePathFromResponse(String response) {
        try {
            log.info("🔍 이미지 경로 파싱 시작");
            log.info("🔍 FastAPI 응답 원문: {}", response);

            JsonNode jsonNode = objectMapper.readTree(response);
            log.info("🔍 JSON 파싱 성공");

            // 🎯 여러 가능한 필드명 확인 (경로 관련)
            String[] possibleFields = {"image_path", "image_url", "file_path", "path", "save_path"};

            for (String field : possibleFields) {
                if (jsonNode.has(field)) {
                    String imagePath = jsonNode.get(field).asText();
                    log.info("🔍 {} 필드에서 추출: {}", field, imagePath);

                    if (imagePath != null && !imagePath.trim().isEmpty() && !"null".equals(imagePath)) {
                        // 🎯 URL과 로컬 경로 모두 처리
                        if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
                            log.info("✅ HTTP URL 이미지: {}", imagePath);
                            return imagePath;
                        } else {
                            log.info("✅ 로컬 파일 경로: {}", imagePath);
                            return imagePath;
                        }
                    }
                }
            }

            log.error("❌ 유효한 이미지 경로를 찾을 수 없음");
            log.info("🔍 사용 가능한 필드들: {}", jsonNode.fieldNames());
            throw new RuntimeException("응답에서 유효한 이미지 경로를 찾을 수 없습니다.");

        } catch (Exception e) {
            log.error("❌ 이미지 경로 파싱 실패: {}", e.getMessage());
            log.error("❌ 응답 내용: {}", response);
            throw new RuntimeException("이미지 경로 파싱 실패: " + e.getMessage(), e);
        }
    }

    // 🎯 음성 URL 파싱 (로컬 파일 경로 처리 포함)
    private String extractVoiceUrlFromResponse(String response) {
        try {
            System.out.println("🔍 음성 URL 파싱 시작");
            System.out.println("🔍 FastAPI 음성 응답: " + response);

            JsonNode jsonNode = objectMapper.readTree(response);

            // 🎯 여러 가능한 필드명 확인
            String[] possibleFields = {"audio_path", "voice_url", "file_path", "audio_url", "path"};

            for (String field : possibleFields) {
                if (jsonNode.has(field)) {
                    String audioPath = jsonNode.get(field).asText();
                    System.out.println("🔍 " + field + " 필드에서 추출: " + audioPath);

                    if (audioPath != null && !audioPath.trim().isEmpty() && !"null".equals(audioPath)) {
                        return audioPath;
                    }
                }
            }

            System.out.println("❌ 유효한 음성 경로를 찾을 수 없음");
            System.out.println("🔍 사용 가능한 필드들: " + jsonNode.fieldNames());
            throw new RuntimeException("응답에서 유효한 음성 경로를 찾을 수 없습니다.");

        } catch (Exception e) {
            System.err.println("❌ 음성 URL 파싱 실패: " + e.getMessage());
            System.err.println("❌ 응답 내용: " + response);
            throw new RuntimeException("음성 URL 파싱 실패: " + e.getMessage(), e);
        }
    }

    // 기존 조회 메서드
    public Story getStoryById(Long id, String username) {
        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return storyRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));
    }

    // 🎯 PIL+OpenCV 흑백 변환 프록시 메서드 (null 체크 추가)
    public ResponseEntity<String> convertToBlackWhite(Map<String, String> request) {
        try {
            String imageUrl = request.get("text");
            System.out.println("🔍 PIL+OpenCV 흑백 변환 요청: " + imageUrl);

            // 🔥 null 체크 추가
            if (imageUrl == null || imageUrl.trim().isEmpty() || "null".equals(imageUrl)) {
                System.out.println("❌ 이미지 URL이 null이거나 비어있음: " + imageUrl);

                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("image_url", null);
                errorResponse.put("error", "이미지 URL이 null입니다.");
                errorResponse.put("conversion_method", "Flutter_Filter");

                String errorJson = objectMapper.writeValueAsString(errorResponse);
                return ResponseEntity.ok(errorJson);
            }

            // 🎯 Python의 convert_bw_image 함수와 동일한 FastAPI 호출
            String url = fastApiBaseUrl + "/convert/bwimage";
            String response = callFastApi(url, request);

            System.out.println("🔍 FastAPI PIL+OpenCV 변환 응답: " + response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            System.out.println("❌ PIL+OpenCV 변환 실패: " + e.getMessage());

            // 🎯 실패 시 Flutter 필터링 안내 응답
            Map<String, Object> fallbackResponse = new HashMap<>();
            fallbackResponse.put("image_url", request.get("text"));
            fallbackResponse.put("conversion_method", "Flutter_Filter");
            fallbackResponse.put("message", "PIL+OpenCV 변환 실패로 Flutter에서 필터링 처리됩니다.");

            try {
                String fallbackJson = objectMapper.writeValueAsString(fallbackResponse);
                return ResponseEntity.ok(fallbackJson);
            } catch (Exception jsonError) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("{\"error\": \"" + e.getMessage() + "\"}");
            }
        }
    }

    // 🆕 색칠공부 템플릿 수동 생성 메서드
    public void createColoringTemplateForExistingStory(Long storyId) {
        try {
            Story story = storyRepository.findById(storyId)
                    .orElseThrow(() -> new RuntimeException("스토리를 찾을 수 없습니다."));

            if (story.getImage() != null && !story.getImage().isEmpty()) {
                System.out.println("🎨 기존 스토리의 색칠공부 템플릿 수동 생성 - StoryId: " + storyId);

                coloringTemplateService.createColoringTemplate(
                        story.getId().toString(),
                        story.getTitle() + " 색칠하기",
                        story.getImage(),
                        null  // PIL+OpenCV 자동 변환
                );

                System.out.println("✅ 기존 스토리의 색칠공부 템플릿 생성 완료");
            } else {
                System.out.println("⚠️ 스토리에 이미지가 없어서 색칠공부 템플릿을 생성할 수 없습니다.");
            }
        } catch (Exception e) {
            System.err.println("❌ 색칠공부 템플릿 수동 생성 실패: " + e.getMessage());
            throw new RuntimeException("색칠공부 템플릿 생성 실패", e);
        }
    }
}