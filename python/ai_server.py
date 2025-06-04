from fastapi import FastAPI, Body
from pydantic import BaseModel
from controllers.story_controller import generate_fairy_tale, generate_image_from_fairy_tale, play_openai_voice, convert_bw_image
from controllers.music_controller import search_tracks_by_tag
from controllers.video_controller import search_videos
from datetime import datetime


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
    result = generate_fairy_tale(req.name, req.theme)
    return {"story": result}

# 음성 파일 생성 클래스
class TTSRequest(BaseModel):
    text: str

# 음성 파일 생성 라우터
@app.post("/generate/voice")
def generate_voice(req: TTSRequest):
    path = play_openai_voice(req.text)
    return {"audio_path": path}

# 이미지 생성 클래스
class ImageRequest(BaseModel):
    text: str

# 이미지 생성 라우터
@app.post("/generate/image")
def generate_image(req: ImageRequest):
    image_url = generate_image_from_fairy_tale(req.text)
    return {"image_url": image_url}

# 흑백 이미지 변환 라우터
@app.post("/convert/bwimage")
def convert_image(req: ImageRequest):
    image_url = convert_bw_image(req.text)
    return {"image_url": image_url}


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