import os
import openai
import tempfile
from dotenv import load_dotenv
import logging
from openai import OpenAI

load_dotenv()  # .env 파일에서 환경변수 로드

# OpenAI API 키 가져오기
openai_api_key = os.getenv('OPENAI_API_KEY')

# 1. 변수에 값 할당하기
# openai_api_key = st.secrets["OpenAI"]["OPENAI_API_KEY"]

# 2. 값이 없으면 에러 처리
if not openai_api_key:
    raise ValueError("환경변수 'OPENAI_API_KEY'가 설정되지 않았습니다.")

# 3. openai에 API 키 등록
openai.api_key = openai_api_key

client = OpenAI(api_key=openai_api_key)

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# 동화 생성 함수
def generate_fairy_tale(name, theme):
    prompt = (
        f"너는 동화 작가야. '{theme}'을 주제로 해서 '{name}'이 주인공인 길고 풍부한 동화를 생성해줘. 등장인물, 배경, 사건 등의 디테일을 포함하고, 엄마가 아이에게 읽어주듯 친절한 말투로 써줘."
    )
    try:
        completion = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=4096,
            temperature=0.5
        )
        return completion.choices[0].message.content
    except Exception as e:
        return f"동화 생성 중 오류 발생: {e}"


# 음성 재생 함수
def play_openai_voice(text, voice="alloy", speed=1):
    # 1. TTS 음성 생성
    response = openai.audio.speech.create(
        model="tts-1",
        voice=voice,
        input=text
    )
    # 2. 임시 파일에 저장
    tmp_path = None
    if hasattr(response, 'content') and response.content:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp_file:
            tmp_file.write(response.content)
            tmp_path = tmp_file.name
    else:
        logging.error("TTS 응답이 없습니다.")
        return None
    return tmp_path


# 이미지 생성 함수
def generate_image_from_fairy_tale(image_mode, fairy_tale_text):
    prompt = f"동화 속 장면을 묘사한 그림: {fairy_tale_text[:300]} 을 {image_mode}로 출력해줘. 만약 {image_mode}가 'Black/White' 라면 색칠할 수 있게 라인만 그려줘"
    try:
        response = openai.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            n=1
        )
        if hasattr(response, "data") and response.data and len(response.data) > 0:
            return response.data[0].url
        else:
            print("이미지 생성 실패: 응답이 비어 있거나 형식이 잘못됨.")
            print("전체 응답:", response)
            return None
    except Exception as e:
        print(f"이미지 생성 중 오류 발생:\n{e}")
        return None