import requests

res = requests.post(
    "http://localhost:8001/whisper/predict",
    files={
        "audio": open("test2.wav", "rb"),
    },
).text

print(res)
