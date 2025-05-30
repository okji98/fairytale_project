import streamlit as st
from controllers.story_controller import generate_fairy_tale, play_openai_voice, generate_image_from_fairy_tale
import os

# 초기 상태 설정
if 'fairy_tale_text' not in st.session_state:
    st.session_state.fairy_tale_text = ""

if 'image_url' not in st.session_state:
    st.session_state.image_url = None

# Streamlit 앱 설정
title = "태교 동화 생성봇"
st.markdown("# 인공지능 동화작가 동글이입니다.")

# 태아 또는 자녀 이름 입력 받기
name = st.text_input("아이의 이름(태명)을 입력해 주세요", "")
st.write(f"{name}을(를) 위한 동화를 생성해 드립니다.")

# 속도 버튼
speed = st.slider("속도를 선택해 주세요", 0, 2, 1) # 최소, 최대, 기본값
st.write("선택한 속도:", speed)

# 테마 버튼
thema = st.selectbox("테마를 선택해 주세요", ["자연", "도전", "가족", "사랑", "우정", "용기"])
st.write("선택한 테마:", thema)

# 목소리 선택
voice_choices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
voice = st.selectbox("목소리를 선택해 주세요", voice_choices)
st.write("선택한 목소리:", voice)

# 동화 생성 버튼
if st.button("동화 생성"):
    st.session_state.fairy_tale_text = generate_fairy_tale(name, thema)  # 동화 생성
    st.success("동화가 생성되었습니다!")  # 사용자 피드백

# 동화 내용 표시
st.text_area("생성된 동화:", st.session_state.fairy_tale_text, height=300)

# 음성 재생 버튼
if st.button("음성으로 듣기"):
    if st.session_state.get("fairy_tale_text"):
        audio_file = play_openai_voice(st.session_state.fairy_tale_text, voice=voice)
        if audio_file:
            st.audio(audio_file)
            os.remove(audio_file)
    else:
        st.warning("먼저 동화를 생성하세요.")

# 이미지 색상 모드 선택 버튼
image_mode = st.radio(
    "모드를 선택해 주세요",
    ["Color", "Black/White"],
    index=0, # 기본 선택값
)
st.write(f"{image_mode}를 선택하였습니다.")

# 이미지 생성 버튼
if st.button("동화 이미지 생성"):
    if st.session_state.fairy_tale_text.strip():
        image_url = generate_image_from_fairy_tale(image_mode, st.session_state.fairy_tale_text)
        if image_url:
            st.session_state.image_url = image_url
            st.success("이미지가 생성되었습니다!")
        else:
            st.warning("이미지 생성에 실패했습니다. 입력을 다시 확인해주세요.")
    else:
        st.warning("먼저 동화 내용을 입력해주세요.")

# 이미지 표시
if st.session_state.image_url:
    st.image(st.session_state.image_url, caption="동화 이미지", use_column_width=True)