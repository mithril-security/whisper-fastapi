import requests

res = requests.post(
    "https://nitro.mithrilsecurity.io/whisper/predict",
    # "https://nitro.mithrilsecurity.io/audio-summarization-pipeline/predict",
    files={
        "audio": open("test2.wav", "rb"),
    },
).text

print(res)
