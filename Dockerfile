FROM python:3.10.10-bullseye

RUN pip install \
        torch==1.13.1 \
        transformers==4.26.1 \
        fastapi==0.95.0 \
        python-multipart==0.0.6 \
        uvicorn==0.21.1 \
        soundfile==0.12.1 \
        messages \
    --extra-index-url https://download.pytorch.org/whl/cpu

COPY batch_runner.py /
COPY collators.py /
COPY serializers.py /
COPY server.py /
COPY start.sh /

RUN chmod +x /start.sh

CMD ["/start.sh"]
