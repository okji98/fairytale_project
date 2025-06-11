// src/main/java/com/fairytale/fairytale/service/S3Service.java
package com.fairytale.fairytale.service;

import com.amazonaws.HttpMethod;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URL;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3Service {

    private final AmazonS3 amazonS3;

    @Value("${cloud.aws.s3.bucket}")
    private String bucketName;

    @Value("${cloud.aws.region.static}")
    private String region;

    /**
     * 프로필 이미지 업로드
     */
    public String uploadProfileImage(MultipartFile file, Long userId) {
        try {
            // 파일 확장자 검증
            String contentType = file.getContentType();
            if (!isImageFile(contentType)) {
                throw new IllegalArgumentException("이미지 파일만 업로드 가능합니다.");
            }

            // 파일 크기 검증 (5MB 제한)
            if (file.getSize() > 5 * 1024 * 1024) {
                throw new IllegalArgumentException("파일 크기는 5MB를 초과할 수 없습니다.");
            }

            // 파일명 생성
            String fileName = generateProfileImageFileName(userId, getFileExtension(file.getOriginalFilename()));

            // S3에 업로드
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType(contentType);
            metadata.setContentLength(file.getSize());
            metadata.setCacheControl("max-age=31536000"); // 1년 캐시

            PutObjectRequest putObjectRequest = new PutObjectRequest(
                    bucketName,
                    fileName,
                    file.getInputStream(),
                    metadata
            ).withCannedAcl(CannedAccessControlList.PublicRead);

            amazonS3.putObject(putObjectRequest);

            // 업로드된 파일의 URL 반환
            String imageUrl = getPublicUrl(fileName);

            log.info("✅ 프로필 이미지 업로드 성공: userId={}, fileName={}, url={}", userId, fileName, imageUrl);
            return imageUrl;

        } catch (IOException e) {
            log.error("❌ 프로필 이미지 업로드 실패: userId={}, error={}", userId, e.getMessage());
            throw new RuntimeException("파일 업로드 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * Presigned URL 생성 (클라이언트에서 직접 업로드용)
     */
    public Map<String, Object> generatePresignedUrl(Long userId, String contentType) {
        try {
            // 파일명 생성
            String fileName = generateProfileImageFileName(userId, getExtensionFromContentType(contentType));

            // Presigned URL 생성 (10분 유효)
            Date expiration = new Date();
            long expTimeMillis = expiration.getTime();
            expTimeMillis += 1000 * 60 * 10; // 10분
            expiration.setTime(expTimeMillis);

            GeneratePresignedUrlRequest generatePresignedUrlRequest = new GeneratePresignedUrlRequest(bucketName, fileName)
                    .withMethod(HttpMethod.PUT)
                    .withExpiration(expiration);

            generatePresignedUrlRequest.addRequestParameter("Content-Type", contentType);

            URL presignedUrl = amazonS3.generatePresignedUrl(generatePresignedUrlRequest);

            Map<String, Object> result = new HashMap<>();
            result.put("presignedUrl", presignedUrl.toString());
            result.put("fileName", fileName);
            result.put("publicUrl", getPublicUrl(fileName));
            result.put("expiresAt", expiration);

            log.info("✅ Presigned URL 생성 성공: userId={}, fileName={}", userId, fileName);
            return result;

        } catch (Exception e) {
            log.error("❌ Presigned URL 생성 실패: userId={}, error={}", userId, e.getMessage());
            throw new RuntimeException("Presigned URL 생성 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 파일 삭제
     */
    public void deleteFile(String fileName) {
        try {
            amazonS3.deleteObject(bucketName, fileName);
            log.info("✅ 파일 삭제 성공: fileName={}", fileName);
        } catch (Exception e) {
            log.error("❌ 파일 삭제 실패: fileName={}, error={}", fileName, e.getMessage());
            throw new RuntimeException("파일 삭제 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 파일 존재 여부 확인
     */
    public boolean doesFileExist(String fileName) {
        try {
            amazonS3.getObjectMetadata(bucketName, fileName);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // === Private Methods ===

    private String generateProfileImageFileName(Long userId, String extension) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
        String uuid = UUID.randomUUID().toString().substring(0, 8);
        return String.format("profile-images/user-%d-%s-%s%s", userId, timestamp, uuid, extension);
    }

    private String getPublicUrl(String fileName) {
        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucketName, region, fileName);
    }

    private boolean isImageFile(String contentType) {
        return contentType != null && (
                contentType.equals("image/jpeg") ||
                        contentType.equals("image/jpg") ||
                        contentType.equals("image/png") ||
                        contentType.equals("image/gif")
        );
    }

    private String getFileExtension(String fileName) {
        if (fileName != null && fileName.contains(".")) {
            return fileName.substring(fileName.lastIndexOf("."));
        }
        return ".jpg"; // 기본값
    }

    private String getExtensionFromContentType(String contentType) {
        switch (contentType) {
            case "image/jpeg":
            case "image/jpg":
                return ".jpg";
            case "image/png":
                return ".png";
            case "image/gif":
                return ".gif";
            default:
                return ".jpg";
        }
    }
}