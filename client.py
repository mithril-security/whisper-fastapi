import requests

res = requests.post(
    "http://127.0.0.1:8000/whisper/predict",
    #"https://ec2-44-228-153-183.us-west-2.compute.amazonaws.com/audio-summarization-pipeline/predict",
    #"https://nitro.mithrilsecurity.io/whisper/predict",
    # "https://nitro.mithrilsecurity.io/audio-summarization-pipeline/predict",
    files={
        "audio": open("test2.wav", "rb"),
    },
    verify=False,
).text

print(res)