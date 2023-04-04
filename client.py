import requests

res = requests.post(
    "http://127.0.0.1:8000/predict",
    files={
        "audio": open("test.wav", "rb"),
    },
    # headers={"Content-Type":"application/json"},
).text

print(res)
