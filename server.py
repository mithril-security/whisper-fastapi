import uvicorn
from fastapi import FastAPI
from transformers import WhisperProcessor, WhisperForConditionalGeneration
import numpy as np
import torch
import hashlib

from batch_runner import BatchRunner
from collators import TorchCollator
from serializers import async_speech_to_text_endpoint

import argparse

app = FastAPI()

model = WhisperForConditionalGeneration.from_pretrained("openai/whisper-tiny.en")
model.eval()

# Args for runner
parser = argparse.ArgumentParser()

parser.add_argument("--max_batch_size", type=int, default=2)
parser.add_argument("--max_latency_ms", type=int, default=10000)


def run_fn(x: torch.Tensor) -> torch.Tensor:
    return model.generate(x)


args = parser.parse_args()
runner = BatchRunner(
    run_fn,
    max_batch_size=args.max_batch_size,
    max_latency_ms=args.max_latency_ms,
    collator=TorchCollator(),
)


app.on_event("startup")(runner.run)

processor = WhisperProcessor.from_pretrained("openai/whisper-tiny.en")


@app.post("/predict")
@async_speech_to_text_endpoint(sample_rate=16000)
async def predict(x: np.ndarray) -> str:
    input_features = processor(
        x, sampling_rate=16000, return_tensors="pt"
    ).input_features
    predicted_ids = await runner.submit(input_features)
    transcription = processor.batch_decode(predicted_ids, skip_special_tokens=True)
    return transcription[0]


@app.get("/metadata")
async def metadata() -> dict:
    # Hash the model
    model_hash = hashlib.sha256(processor.tokenizer.name_or_path.encode()).hexdigest()
    return {
        "server_max_batch_size": args.max_batch_size,
        "server_max_latency_ms (s)": args.max_latency_ms,
        "model_hash": model_hash,
    }


if __name__ == "__main__":
    print("Starting server with args:", args)
    uvicorn.run(app, host="0.0.0.0", port=8000)
