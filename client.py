import requests

res = requests.post(
    "http://127.0.0.1:8000/audio-summarization-pipeline/predict",
    files={
        "audio": open("test2.wav", "rb"),
    },
).text

print(res)
