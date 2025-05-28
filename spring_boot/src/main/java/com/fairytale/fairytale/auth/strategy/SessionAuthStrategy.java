package com.fairytale.fairytale.auth.strategy;

import com.fairytale.fairytale.users.Users;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component("sessionAuthStrategy") // 스프링 빈으로 등록
@RequiredArgsConstructor
public class SessionAuthStrategy implements AuthStrategy {
    // TODO: 사용자 세션 정보를 저장할 Map 정의 (스레드 세이프한 자료구조로)
    // 세션ID와 유저ID를 넣어야 함. 매칭시키기 위해서
    // 사용자가 이후에 게시글 보기같은 요청을 보낼 때 유저정보를 찾아오기 위해 담아둠.
    Map<String, String> sessionInfo = new ConcurrentHashMap<>();

    // TODO: authenticate(Users user) 구현
    public String authenticate(Users user) {
        // 1. UUID로 고유한 세션 ID 생성
        String sessionId = UUID.randomUUID().toString();
        // 2. 세션 ID를 키로, 사용자 정보를 값으로 Map에 저장
        sessionInfo.put(sessionId, String.valueOf(user.getId()));
        // 3. 세션 ID 반환
        return sessionId;
    }

    // TODO: isValid(String token) 구현
    public boolean isValid(String token) {
        try {
            // 1. Map에 해당 token이 존재하는지 확인
            sessionInfo
            return true;
        } catch (Exception e) {
            // 2. 존재하면 true, 아니면 false
            return false;
        }
    }

    // TODO: extractUsername(String token) 구현
    public String getUsername(String token) {
        // 1. token으로 Map에서 Users 객체 조회
        // 2. Users 객체가 존재하면 사용자 email 또는 username 리턴
        // 3. 없으면 null 리턴
        return "";
    }
}
