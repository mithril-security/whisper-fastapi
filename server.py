import uvicorn
from fastapi import FastAPI
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    WhisperProcessor,
    WhisperForConditionalGeneration,
    StoppingCriteriaList,
)
import numpy as np
import torch
import requests

from batch_runner import BatchRunner
from collators import TorchCollator
from messages import PredictionMsg
from model_store import load_from_store
from serializers import async_speech_to_text_endpoint

STT = "openai/whisper-tiny.en"
#LLM = "togethercomputer/Pythia-Chat-Base-7B"
MODEL_STORE_ADDR = "172.17.0.1"
# LLM = "togethercomputer/GPT-NeoXT-Chat-Base-20B"


app = FastAPI()

whisper_processor = load_from_store(STT, WhisperProcessor, MODEL_STORE_ADDR)

whisper_model = load_from_store(STT, WhisperForConditionalGeneration, MODEL_STORE_ADDR)
whisper_model.eval()

def run_whisper(x: torch.Tensor) -> torch.Tensor:
    return whisper_model.generate(x)

whisper_runner = BatchRunner(
    run_whisper,
    max_batch_size=2,
    max_latency_ms=10000,
    collator=TorchCollator(),
)
app.on_event("startup")(whisper_runner.run)


@app.post("/whisper/predict")
@async_speech_to_text_endpoint(sample_rate=16000)
async def predict(x: np.ndarray) -> str:
    input_features = whisper_processor(x, sampling_rate=16000, return_tensors="pt").input_features
    predicted_ids = await whisper_runner.submit(input_features)
    transcription = whisper_processor.batch_decode(predicted_ids, skip_special_tokens=True)
    return transcription[0]

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)