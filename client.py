import requests
import librosa
import hashlib


def transcribe(addr, port):
    audio, _ = librosa.load("test.wav", sr=16000)

    audio_length = len(audio) / 16000

    audio_hash = hashlib.sha256(audio).hexdigest()
    res = requests.post(
        f"{addr}:{port}/predict",
        files={
            "audio": open("test.wav", "rb"),
        },
        # headers={"Content-Type":"application/json"},
    ).text
    return dict(audio_length=audio_length, audio_hash=audio_hash, text=res)


def get_metadata(addr, port):
    return requests.get(f"{addr}:{port}/metadata").json()
