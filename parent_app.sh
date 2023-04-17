#!/bin/bash

python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
python model_store.py download "openai/whisper-tiny.en"
python model_store.py download "togethercomputer/Pythia-Chat-Base-7B"
exec python model_store.py serve
