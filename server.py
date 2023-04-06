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

from batch_runner import BatchRunner
from collators import TorchCollator
from messages import PredictionMsg
from openchatkit_utils import StopWordsCriteria
from serializers import async_speech_to_text_endpoint

STT = "openai/whisper-tiny.en"
LLM = "togethercomputer/Pythia-Chat-Base-7B"
# LLM = "togethercomputer/GPT-NeoXT-Chat-Base-20B"


app = FastAPI()

whisper_processor = WhisperProcessor.from_pretrained(STT)
open_chat_kit_tokenizer = AutoTokenizer.from_pretrained(LLM)


whisper_model = WhisperForConditionalGeneration.from_pretrained(STT)
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


open_chat_kit_model = AutoModelForCausalLM.from_pretrained(LLM)
open_chat_kit_model.eval()
open_chat_kit_stop_criteria = StopWordsCriteria(open_chat_kit_tokenizer, ["<human>"], None)

def run_open_chat_kit(x: torch.Tensor) -> torch.Tensor:
    return open_chat_kit_model.generate(
        x,
        max_length=128,
        temperature=0.7,
        top_p=0.7,
        top_k=50,
        repetition_penalty=1.0,
        pad_token_id=open_chat_kit_tokenizer.eos_token_id,
        stopping_criteria=StoppingCriteriaList([open_chat_kit_stop_criteria]),
    )

open_chat_kit_runner = BatchRunner(
    run_open_chat_kit,
    max_batch_size=2,
    max_latency_ms=10000,
    collator=TorchCollator(),
)
app.on_event("startup")(open_chat_kit_runner.run)


@app.post("/open-chat-kit/predict")
async def predict(msg: PredictionMsg) -> str:
    input_ids = open_chat_kit_tokenizer(msg.input_text, return_tensors="pt").input_ids
    predicted_ids = await open_chat_kit_runner.submit(input_ids)
    transcription = open_chat_kit_tokenizer.batch_decode(predicted_ids, skip_special_tokens=True)
    return transcription[0]

@app.post("/whisper/predict")
@async_speech_to_text_endpoint(sample_rate=16000)
async def predict(x: np.ndarray) -> str:
    input_features = whisper_processor(x, sampling_rate=16000, return_tensors="pt").input_features
    predicted_ids = await whisper_runner.submit(input_features)
    transcription = whisper_processor.batch_decode(predicted_ids, skip_special_tokens=True)
    return transcription[0]

@app.post("/audio-summarization-pipeline/predict")
@async_speech_to_text_endpoint(sample_rate=16000)
async def predict(x: np.ndarray) -> str:
    input_features = whisper_processor(x, sampling_rate=16000, return_tensors="pt").input_features
    predicted_ids = await whisper_runner.submit(input_features)
    transcription = whisper_processor.batch_decode(predicted_ids, skip_special_tokens=True)
    input_ids = open_chat_kit_tokenizer(
        f"<human>: {transcription[0]}\n\nSummarize the above into a single sentence.\n<bot>:",
        return_tensors="pt"
    ).input_ids
    predicted_ids = await open_chat_kit_runner.submit(input_ids)
    transcription = open_chat_kit_tokenizer.batch_decode(predicted_ids, skip_special_tokens=True)
    return transcription[0]

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)