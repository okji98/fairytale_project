from fastapi import FastAPI, Body
from pydantic import BaseModel
from gen_story import generate_fairy_tale, generate_image_from_fairy_tale, play_openai_voice

# FastAPI 애플리케이션 생성
app = FastAPI()

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
def generate_void(req: TTSRequest):
    path = play_openai_voice(generate_fairy_tale(req.text))
    return {"audio_path": path}

# 이미지 생성 클래스
class ImageRequest(BaseModel):
    mode: str
    text: str

# 이미지 생성 라우터
@app.post("/generate/image")
def generate_image(req: ImageRequest):
    image_url = generate_image_from_fairy_tale(req.mode, req.text)
    return {"image_url": image_url}