import uvicorn
from fastapi import FastAPI
from transformers import WhisperProcessor, WhisperForConditionalGeneration
import numpy as np
import torch

from batch_runner import BatchRunner
from collators import TorchCollator
from serializers import async_speech_to_text_endpoint

app = FastAPI()

model = WhisperForConditionalGeneration.from_pretrained("openai/whisper-tiny.en")
model.eval()

def run_fn(x: torch.Tensor) -> torch.Tensor:
    return model.generate(x)

runner = BatchRunner(
    run_fn,
    max_batch_size=2,
    max_latency_ms=10000,
    collator=TorchCollator(),
)
app.on_event("startup")(runner.run)

processor = WhisperProcessor.from_pretrained("openai/whisper-tiny.en")

@app.post("/predict")
@async_speech_to_text_endpoint(sample_rate=16000)
async def predict(x: np.ndarray) -> str:
    input_features = processor(x, sampling_rate=16000, return_tensors="pt").input_features
    predicted_ids = await runner.submit(input_features)
    transcription = processor.batch_decode(predicted_ids, skip_special_tokens=True)
    return transcription[0]

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
