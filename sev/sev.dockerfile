FROM python:3.10.10-bullseye

RUN pip install \
    torch==1.13.1 \
    transformers==4.26.1 \
    fastapi==0.95.0 \
    python-multipart==0.0.6 \
    uvicorn==0.21.1 \
    soundfile==0.12.1 \
    librosa==0.10.0 \
    pydantic==1.10.7 \
    requests==2.28.2 \
    --extra-index-url https://download.pytorch.org/whl/cpu

COPY ../batch_runner.py /
COPY ../collators.py /
COPY ../messages.py /
COPY ../model_store.py /
COPY ../openchatkit_utils.py /
COPY ../serializers.py /
COPY ../server.py /
# COPY init-sev.sh /

EXPOSE 80

# CMD init-sev.sh

# debug mode
EXPOSE 22

RUN apt-get update && apt-get install -y openssh-server

RUN mkdir ~/.ssh && \
    echo 'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGIkScs6r3IaPujv7/1Sj4LdbL5trRZemf0o+vd1NJ+0kRgGru5h4lz3EVOlJMVZh9GucU46z9x0Mxi/7ORGlmY= cchudant@niko' \
    > ~/.ssh/authorized_keys
CMD service ssh restart && sleep infinity
