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
        st.error("TTS 응답이 없습니다.")
        return None
    return tmp_path


# 이미지 생성 함수
def generate_image_from_fairy_tale(fairy_tale_text):
    # 프롬프트 영어로 생성 시 응답 내용 더 정확해짐
    try:
        base_prompt = fairy_tale_text[:300].replace('\n', ' ')

        prompt = (
            "Make sure there is no text in the image "
            "Minimul detail "
            f"Please create a single, simple illustration that matches the content about {base_prompt}, in a child-friendly style. "
        )

        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="standard",
            n=1
        )
        
        if hasattr(response, "data") and response.data and len(response.data) > 0:
            # URL 가져오기
            image_url = response.data[0].url
            print(f"이미지 생성 성공: {image_url}")
            return image_url

            # 이미지 다운로드 및 파일로 저장
            # image_response = requests.get(image_url, stream=True)
            # if image_response.status_code == 200:
            #     # PIL을 사용해 이미지 열기
            #     image = Image.open(BytesIO(image_response.content))
            #     image.save(save_path)  # 저장 경로에 이미지 저장
            #     print(f"이미지가 성공적으로 저장되었습니다: {save_path}")
            #     return save_path
           
            # else:
            #     print(f"이미지 다운로드 실패: {image_response.status_code}")
            #     return None
        else:
            print("이미지 생성 실패: 응답이 비어 있거나 형식이 잘못됨.")
            print("전체 응답:", response)
            return None
    except Exception as e:
        print(f"이미지 생성 중 오류 발생:\n{e}")
        return None


# 흑백 이미지 변환
def convert_bw_image(image_url, save_path="bw_image.png"):
    try:
        response = requests.get(image_url)
        image = Image.open(BytesIO(response.content)).convert("RGB")

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
        # cv2.imwrite(save_path, line_drawing)
        bw_pil_image = Image.fromarray(line_drawing)
        bw_pil_image.save(save_path)
        return save_path
    
        # 이미지 저장
        # success = cv2.imwrite(save_path, line_drawing)
        # if not success:
        #     print("이미지 저장에 실패했습니다.")
        #     return None

        # print(f"이미지가 성공적으로 {save_path}에 저장되었습니다.")
        # return save_path
    
    except Exception as e:
        print(f"변환 오류: {e}")
        return None