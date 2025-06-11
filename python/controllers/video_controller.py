import os
import requests
from dotenv import load_dotenv
import streamlit as st
from openai import OpenAI
from langchain.tools import DuckDuckGoSearchRun
from langchain.agents import initialize_agent, AgentType
from langchain.chat_models import ChatOpenAI

load_dotenv()  # .env 파일에서 환경변수 로드

# GOOGLE API 키 가져오기
google_api_key = os.getenv('GOOGLE_API_KEY')

## 1. 변수에 값 할당하기
# google_api_key = st.secrets["GOOGLE"]["GOOGLE_API_KEY"]

## 2. 값이 없으면 에러 처리
# if not google_api_key:
#     raise ValueError("환경변수 'GOOGLE_API_KEY'가 설정되지 않았습니다.")



# 테마 목록과 키워드 매칭
THEME_KEYWORDS = {
    "piano": "piano",
    "guitar": "guitar",
    "nature": "nature",
    "moon": "moon",
    "sky": "sky",
    "classical": "classical",
}

# def search_videos(theme):
#     keyword = THEME_KEYWORDS.get(theme, "")
#     if not keyword:
#         return []

#     query = f"{keyword} baby lullaby"
#     url = (
#         f"https://www.googleapis.com/youtube/v3/search"
#         f"?part=snippet&maxResults=5&type=video&q={query}&key={google_api_key}"
#     )

#     response = requests.get(url)

#     # 응답코드가 200이 아닐 때 (응답 실패)
#     if response.status_code != 200:
#         print(f"YouTube API 요청 실패: {response.status_code}")
#         return []
    
#     data = response.json()
#     results = []

#     for item in data.get("items", []):
#         video_id = item["id"]["videoId"]
#         title = item["snippet"]["title"]
#         thumbnail = item["snippet"]["thumbnails"]["medium"]["url"]
#         video_url = f"https://www.youtube.com/watch?v={video_id}"

#         results.append({
#             "title": title,
#             "url": video_url,
#             "thumbnail": thumbnail
#         })

#     return results
        

def search_videos(theme):
    keyword = THEME_KEYWORDS.get(theme, "")
    if not keyword:
        print(f"⚠️ 테마 '{theme}'에 대한 키워드를 찾을 수 없습니다.")
        return []
    
    # 오타 수정: lullabby → lullaby
    query = f"{keyword} baby lullaby"
    url = (
        f"https://www.googleapis.com/youtube/v3/search"
        f"?part=snippet&maxResults=5&type=video&q={query}&key={google_api_key}"
    )
    
    print(f"🔍 YouTube API 요청: {query}")
    print(f"📍 URL: {url}")
    
    response = requests.get(url)
    
    # 응답코드가 200이 아닐 때 (응답 실패)
    if response.status_code != 200:
        print(f"❌ YouTube API 요청 실패: {response.status_code}")
        print(f"❌ 에러 메시지: {response.text}")
        return []
    
    data = response.json()
    
    # 결과 확인
    items = data.get("items", [])
    print(f"✅ YouTube API 응답: {len(items)}개의 결과")
    
    results = []
    
    for item in items:
        video_id = item["id"]["videoId"]
        title = item["snippet"]["title"]
        thumbnail = item["snippet"]["thumbnails"]["medium"]["url"]
        video_url = f"https://www.youtube.com/watch?v={video_id}"
        
        results.append({
            "title": title,
            "url": video_url,
            "thumbnail": thumbnail
        })
    
    return results


