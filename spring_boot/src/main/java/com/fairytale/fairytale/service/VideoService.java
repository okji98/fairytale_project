// src/main/java/com/fairytale/fairytale/service/VideoService.java
package com.fairytale.fairytale.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class VideoService {

    private final S3Service s3Service;
    private final RestTemplate restTemplate;

    @Value("${fastapi.base.url}")
    private String fastApiBaseUrl;

    /**
     * 이미지와 오디오를 결합하여 비디오 생성
     */
    public String createVideoFromImageAndAudio(String imageUrl, String audioUrl, String storyTitle) {
        try {
            log.info("🎬 비디오 생성 시작 - 이미지: {}, 오디오: {}", imageUrl, audioUrl);

            // 1. Python FastAPI로 비디오 생성 요청
            Map<String, Object> requestData = new HashMap<>();
            requestData.put("image_url", imageUrl);
            requestData.put("audio_url", audioUrl);
            requestData.put("story_title", storyTitle);

            String pythonVideoEndpoint = fastApiBaseUrl + "/video/create-from-image-audio";
            log.info("🔍 Python API 호출: {}", pythonVideoEndpoint);

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    pythonVideoEndpoint,
                    requestData,
                    Map.class
            );

            if (response != null && response.containsKey("video_path")) {
                String localVideoPath = (String) response.get("video_path");
                log.info("✅ Python에서 비디오 생성 완료: {}", localVideoPath);

                // 2. 생성된 비디오를 S3에 업로드
                String s3VideoUrl = s3Service.uploadVideoFromLocalFile(localVideoPath, "videos");
                log.info("✅ S3 비디오 업로드 완료: {}", s3VideoUrl);

                return s3VideoUrl;
            } else {
                throw new RuntimeException("Python API에서 유효한 비디오 경로를 반환하지 않았습니다.");
            }

        } catch (Exception e) {
            log.error("❌ 비디오 생성 실패: {}", e.getMessage());
            throw new RuntimeException("비디오 생성 중 오류가 발생했습니다: " + e.getMessage(), e);
        }
    }

    /**
     * 썸네일 이미지 생성 (첫 번째 프레임 추출)
     */
    public String createThumbnail(String videoUrl) {
        try {
            log.info("🖼️ 썸네일 생성 시작 - 비디오: {}", videoUrl);

            Map<String, Object> requestData = new HashMap<>();
            requestData.put("video_url", videoUrl);

            String pythonThumbnailEndpoint = fastApiBaseUrl + "/video/create-thumbnail";

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    pythonThumbnailEndpoint,
                    requestData,
                    Map.class
            );

            if (response != null && response.containsKey("thumbnail_path")) {
                String localThumbnailPath = (String) response.get("thumbnail_path");
                log.info("✅ Python에서 썸네일 생성 완료: {}", localThumbnailPath);

                // S3에 썸네일 업로드
                String s3ThumbnailUrl = s3Service.uploadImageFromLocalFile(localThumbnailPath, "thumbnails");
                log.info("✅ S3 썸네일 업로드 완료: {}", s3ThumbnailUrl);

                return s3ThumbnailUrl;
            } else {
                log.warn("⚠️ 썸네일 생성 실패, 기본 이미지 사용");
                return null; // 썸네일 생성 실패 시 null 반환
            }

        } catch (Exception e) {
            log.error("❌ 썸네일 생성 실패: {}", e.getMessage());
            return null; // 썸네일 생성 실패해도 비디오 공유는 가능하도록
        }
    }
}