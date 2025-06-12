import os
import openai
import tempfile
from playsound import playsound
import asyncio
from dotenv import load_dotenv
import streamlit as st
from openai import OpenAI
from io import BytesIO
import requests
import cv2
import numpy as np
from PIL import Image
import random
import re
from typing import Optional
import base64

load_dotenv()  # .env 파일에서 환경변수 로드

# OpenAI API 키 가져오기
openai_api_key = os.getenv('OPENAI_API_KEY')

# 1. 변수에 값 할당하기
#openai_api_key = st.secrets["OpenAI"]["OPENAI_API_KEY"]

# 2. 값이 없으면 에러 처리
if not openai_api_key:
    raise ValueError("환경변수 'OPENAI_API_KEY'가 설정되지 않았습니다.")

# 3. openai에 API 키 등록
openai.api_key = openai_api_key

client = OpenAI(api_key=openai_api_key)


# You are a fairy tale writer.

# Please write a long and rich fairy tale in Korean about '{thema}', with the main character named '{name}'.  
# The main character can be various animals.  
# Include detailed descriptions of the characters, background, and events,  
# and write in a warm and gentle tone as if a mother is reading the story to her child.

# 동화 생성 함수
def generate_fairy_tale(name, thema):
    prompt = (
        f"""
        너는 동화 작가야.
        '{thema}'를 주제로, '{name}'이 주인공인 길고 아름다운 동화를 써줘.
        엄마가 아이에게 읽어주듯 다정한 말투로 써줘.
        """
    )
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=16384,
            temperature=0.5
        )
        return completion.choices[0].message.content
    except Exception as e:
        return f"동화 생성 중 오류 발생: {e}"


# # 음성 재생 함수
# def play_openai_voice(text, voice="alloy", speed=1):
#     # 1. TTS 음성 생성
#     try:
#         response = openai.audio.speech.create(
#             model="tts-1",
#             voice=voice,
#             input=text,
#             speed=speed # 속도 조절 (1.0이 기본 속도, 0.5는 느리게, 2.0은 빠르게)
#         )
#         # # 2. 임시 파일에 저장
#         # tmp_path = None
#         # if hasattr(response, 'content') and response.content:
#         #     with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp_file:
#         #         tmp_file.write(response.content)
#         #         tmp_path = tmp_file.name
#         # else:
#         #     st.error("TTS 응답이 없습니다.")
#         #     return None
#         # return tmp_path

#         # 2. 영구 파일에 저장 (임시 파일 대신)
#         audio_filename = f"tts_audio_{voice}_{hash(text) % 10000}.mp3"
#         audio_path = os.path.join(".", audio_filename)
        
#         # 기존 파일이 있으면 삭제
#         if os.path.exists(audio_path):
#             os.remove(audio_path)
        
#         # 새 파일로 저장
#         with open(audio_path, "wb") as audio_file:
#             audio_file.write(response.content)
        
#         print(f"음성 파일 생성 완료: {audio_path} (voice: {voice})")
#         return audio_path
        
#     except Exception as e:
#         print(f"TTS 생성 오류: {e}")
#         return None

# OpenAI TTS를 사용하여 음성 데이터 생성 (파일 저장 없음)
def generate_openai_voice(text, voice="alloy", speed=1.0):
    try:
        # TTS 음성 생성
        response = openai.audio.speech.create(
            model="tts-1",
            voice=voice,
            input=text,
            speed=speed
        )
        
        # 바이너리 데이터 직접 반환
        return response.content
        
    except Exception as e:
        print(f"TTS 생성 오류: {e}")
        return None

def audio_to_base64(audio_data):
    """
    오디오 바이너리 데이터를 Base64로 인코딩
    모바일 앱에서 사용하기 위함
    """
    if audio_data:
        return base64.b64encode(audio_data).decode('utf-8')
    return None




# # 이미지 생성 함수 (Dall-E 3 사용)
# def generate_image_from_fairy_tale(fairy_tale_text):
#     # 프롬프트 영어로 생성 시 응답 내용 더 정확해짐
#     try:
#         base_prompt = fairy_tale_text[:300].replace('\n', ' ')

#         prompt = (
#             "Make sure there is no text in the image "
#             "Minimul detail "
#             f"Please create a single, simple illustration that matches the content about {base_prompt}, in a child-friendly style. "
#         )

#         response = client.images.generate(
#             model="dall-e-3",
#             prompt=prompt,
#             size="1024x1024",
#             quality="standard",
#             n=1
#         )
        
#         if hasattr(response, "data") and response.data and len(response.data) > 0:
#             return response.data[0].url
#         else:
#             print("이미지 생성 실패: 응답이 비어 있거나 형식이 잘못됨.")
#             print("전체 응답:", response)
#             return None
#     except Exception as e:
#         print(f"이미지 생성 중 오류 발생:\n{e}")
#         return None

# 중복되지 않는 파일명 생성 함수
def get_available_filename(base_name: str, extension: str = ".png", folder: str = ".") -> str:
    """
    중복되지 않는 파일명을 자동으로 생성
    예: fairy_tale_image.png, fairy_tale_image_1.png, ...
    """
    counter = 0
    while True:
        filename = f"{base_name}{f'_{counter}' if counter > 0 else ''}{extension}"
        filepath = os.path.join(folder, filename)
        if not os.path.exists(filepath):
            return filepath
        counter += 1

# 프롬프트 생성 함수 (staility_sdxl는 영어만 처리 가능)
def generate_image_prompt_from_story(fairy_tale_text: str) -> Optional[str]:
    """
    동화 내용을 기반으로 이미지 생성용 영어 프롬프트 생성
    """
    try:
        system_prompt = (
            "You are a prompt generator for staility_sdxl. "
            f"From the given {fairy_tale_text}, choose one vivid, heartwarming scene. "
            "Describe it in English in a single short sentence suitable for generating a simple, child-friendly fairy tale illustration style. "
            "Use a soft, cute, minimal detail. "
            "No text, no words, no letters, no signs, no numbers."
        )

        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"다음은 동화야:\n\n{fairy_tale_text}\n\n이 동화에 어울리는 그림을 그릴 수 있도록 프롬프트를 영어로 짧게 써줘."}
            ],
            temperature=0.5,
            max_tokens=150
        )

        return completion.choices[0].message.content.strip()

    except Exception as e:
        st.error(f"이미지 프롬프트 생성 오류: {e}")
        return None


# 이미지 생성 함수 (staility_sdxl 사용)
def generate_image_from_fairy_tale(fairy_tale_text):
    # 프롬프트 영어로 생성 시 응답 내용 더 정확해짐
    try:
        endpoint = "https://api.stability.ai/v2beta/stable-image/generate/core"
        
        
        # 동화 프롬프트 처리
        base_prompt = generate_image_prompt_from_story(fairy_tale_text)
        if not base_prompt:
            st.error("이미지 프롬프트 생성에 실패했습니다.")
            return None

        prompt = (
            "no text in the image "
            "Minimul detail "
            f"Please create a single, simple illustration that matches the content about {base_prompt}, in a child-friendly style. "
        )

        headers = {
            "Authorization": f"Bearer {os.getenv('STABILITY_API_KEY')}",
            "Accept": "image/*",
        }

        # multipart/form-data 형태로 데이터 전송
        files = {
            "prompt": (None, prompt),
            "model": (None, "stable-diffusion-xl-1024-v1-0"),
            "output_format": (None, "png"),
            "height": (None, "1024"),
            "width": (None, "1024"),
            "seed": (None, "1234")
        }

        response = requests.post(endpoint, headers=headers, files=files)

        if response.status_code == 200:
            save_path = get_available_filename("fairy_tale_image", ".png", folder=".")
            with open(save_path, "wb") as f:
                f.write(response.content)
            print(f"이미지 저장 완료: {save_path}")
            return save_path
        else:
            print("이미지 생성 실패:", response.status_code)
            print("응답 내용:", response.text)
            return None

    except Exception as e:
        print(f"이미지 생성 중 오류 발생:\n{e}")
        return None


# 흑백 이미지 변환 (Dalle-E 3 이미지 용)
# def convert_bw_image(image_url, save_path="bw_image.png"):
#     try:
#         response = requests.get(image_url)
#         image = Image.open(BytesIO(response.content)).convert("RGB")

#         # Numpy 배열로 변환
#         np_image = np.array(image)

#         # 흑백 변환
#         gray = cv2.cvtColor(np_image, cv2.COLOR_RGB2GRAY)

#         # 가우시안 블러로 노이즈 제거
#         blurred = cv2.GaussianBlur(gray, (3, 3), 0)

#         # 캐니 엣지 디텍션 (더 부드러운 선)
#         edges = cv2.Canny(blurred, 50, 150)
        
#         # 선 두께 조절
#         kernel = np.ones((2,2), np.uint8)
#         dilated_edges = cv2.dilate(edges, kernel, iterations=1)
        
#         # 흰 배경에 검은 선
#         line_drawing = 255 - dilated_edges
        
#         # 이미지 저장
#         cv2.imwrite(save_path, line_drawing)
#         return save_path
    
#     except Exception as e:
#         print(f"변환 오류: {e}")
#         return None

# 흑백 이미지 변환 (staility_sdxl 이미지 용)
def convert_bw_image(image_url, save_path="bw_image.png"):
    try:

        # URL인지 로컬 파일인지 판단
        if image_url.startswith(('http://', 'https://')):
            # URL에서 이미지 다운로드
            response = requests.get(image_url)
            image = Image.open(BytesIO(response.content)).convert("RGB")
        else:
            # 로컬 파일에서 이미지 로드
            image = Image.open(image_url).convert("RGB")

        # Numpy 배열로 변환
        np_image = np.array(image)

        # 흑백 변환
        gray = cv2.cvtColor(np_image, cv2.COLOR_RGB2GRAY)

        # 가우시안 블러로 노이즈 제거
        blurred = cv2.GaussianBlur(gray, (3, 3), 0)

        # 캐니 엣지 디텍션 (더 부드러운 선)
        edges = cv2.Canny(blurred, 50, 150)
        
        # 선 두께 조절
        kernel = np.ones((2,2), np.uint8)
        dilated_edges = cv2.dilate(edges, kernel, iterations=1)
        
        # 흰 배경에 검은 선
        line_drawing = 255 - dilated_edges
        
        # 이미지 저장
        cv2.imwrite(save_path, line_drawing)
        st.info(f"흑백 변환 완료: {save_path}")
        return save_path
    
    except Exception as e:
        print(f"변환 오류: {e}")
        return None