from fastapi import FastAPI, Body, HTTPException
from pydantic import BaseModel
from controllers.story_controller import generate_fairy_tale, generate_image_from_fairy_tale, convert_bw_image, generate_openai_voice # play_openai_voice
from controllers.music_controller import search_tracks_by_tag
from controllers.video_controller import search_videos
from datetime import datetime
import os
import base64
from fastapi.responses import Response


# FastAPI 애플리케이션 생성
app = FastAPI()

# 헬스체크 엔드포인트
@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "service": "fastapi",
        "timestamp": datetime.now().isoformat()
    }


# 동화 생성 클래스
class StoryRequest(BaseModel):
    name: str
    theme: str

# 동화 생성 라우터
@app.post("/generate/story")
def generate_story(req: StoryRequest):
    try:
        result = generate_fairy_tale(req.name, req.theme)
        return {"story": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"동화 생성 실패: {str(e)}")

# 음성 파일 생성 클래스
class TTSRequest(BaseModel):
    text: str
    voice: str
    speed: float = 1.0  # 기본 속도는 1.0

# # 음성 파일 생성 라우터
# @app.post("/generate/voice")
# def generate_voice(req: TTSRequest):
#     path = play_openai_voice(req.text, req.voice)
#     if path is None:
#         raise HTTPException(status_code=500, detail="음성 파일 생성 실패")
#     return {"audio_path": path}

# 음성 파일 생성 라우터 (바이너리 반환)
@app.post("/generate/voice")
def generate_voice(req: TTSRequest):
    try:
        audio_data = generate_openai_voice(req.text, req.voice, req.speed)
        if audio_data is None:
            raise HTTPException(status_code=500, detail="음성 파일 생성 실패")
        
        # Base64로 인코딩하여 JSON으로 반환 (모바일 앱에서 쉽게 처리)
        audio_base64 = base64.b64encode(audio_data).decode('utf-8')
        
        return {
            "audio_base64": audio_base64,
            "voice": req.voice,
            "speed": req.speed,
            "format": "mp3"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"음성 생성 실패: {str(e)}")

# 음성 파일 직접 다운로드 (바이너리 반환)
@app.post("/generate/voice/binary")
def generate_voice_binary(req: TTSRequest):
    try:
        audio_data = generate_openai_voice(req.text, req.voice, req.speed)
        if audio_data is None:
            raise HTTPException(status_code=500, detail="음성 파일 생성 실패")
        
        # 바이너리 데이터 직접 반환
        return Response(
            content=audio_data,
            media_type="audio/mpeg",
            headers={
                "Content-Disposition": f"attachment; filename=voice_{req.voice}.mp3"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"음성 생성 실패: {str(e)}")


# 이미지 생성 클래스
class ImageRequest(BaseModel):
    text: str

# 이미지 생성 라우터(Dall-E 3 용)
# @app.post("/generate/image")
# def generate_image(req: ImageRequest):
#     image_url = generate_image_from_fairy_tale(req.text)
#     return {"image_url": image_url}

# 흑백 이미지 변환 라우터(Dall-E 3 용)
# @app.post("/convert/bwimage")
# def convert_image(req: ImageRequest):
#     image_url = convert_bw_image(req.text)
#     return {"image_url": image_url}

# 흑백 이미지 변환 클래스 (Stabiliy AI 용)
class ConvertRequest(BaseModel):
    image_path: str  # 로컬 파일 경로

# 이미지 생성 라우터 (Stabiliy AI 용)
@app.post("/generate/image")
def generate_image(req: ImageRequest):
    try:
        image_path = generate_image_from_fairy_tale(req.text)
        if image_path is None:
            raise HTTPException(status_code=500, detail="이미지 생성 실패")
        
        # Spring Boot 호환을 위해 image_url로 반환 (실제로는 파일 경로)
        return {"image_url": image_path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"이미지 생성 실패: {str(e)}")

# 흑백 이미지 변환 라우터 (기존 Spring Boot 코드와 호환)
@app.post("/convert/bwimage")
def convert_image(req: ImageRequest):
    try:
        # req.text는 이제 파일 경로로 사용됨
        image_path = req.text
        
        # 파일 존재 확인
        if not os.path.exists(image_path):
            raise HTTPException(status_code=404, detail="이미지 파일을 찾을 수 없습니다")
        
        bw_image_path = convert_bw_image(image_path)
        if bw_image_path is None:
            raise HTTPException(status_code=500, detail="흑백 변환 실패")
        
        # Spring Boot 호환을 위해 image_url로 반환 (실제로는 파일 경로)
        return {"image_url": bw_image_path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"흑백 변환 실패: {str(e)}")

# 음악 검색
class MusicRequest(BaseModel):
    theme: str

@app.post("/search/url")
def get_music(req: MusicRequest):
    results = search_tracks_by_tag(req.theme)
    return {"music_results": results}


# 영상 검색
class VideoRequest(BaseModel):
    theme: str

@app.post("/search/video")
def get_video(req: VideoRequest):
    results = search_videos(req.theme)
    return {"video_results": results}