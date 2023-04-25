FROM python:3.10.10-bullseye as base

RUN pip install \
    torch==1.13.1 \
    transformers==4.26.1 \
    fastapi==0.95.0 \
    python-multipart==0.0.6 \
    uvicorn==0.21.1 \
    soundfile==0.12.1 \
    messages \
    librosa==0.10.0 \
    pydantic==1.10.7 \
    requests==2.28.2 \
    --extra-index-url https://download.pytorch.org/whl/cpu

COPY batch_runner.py /
COPY collators.py /
COPY messages.py /
COPY model_store.py /
COPY openchatkit_utils.py /
COPY serializers.py /
COPY server.py /
COPY start.sh /

CMD ["/start.sh"]

FROM base as sev-aci

ENV TEE_ENV=sev-aci

ENV PROXY_SERVER=localhost
ENV PROXY_PORT=3128

RUN apt-get update && apt-get install iptables redsocks curl lynx -qy

COPY redsocks.conf /etc/redsocks.conf
RUN echo "Configuration:" && \
    echo "PROXY_SERVER=$PROXY_SERVER" && \
    echo "PROXY_PORT=$PROXY_PORT" && \
    echo "Setting config variables" && \
    sed -i "s/vPROXY-SERVER/$PROXY_SERVER/g" /etc/redsocks.conf && \
    sed -i "s/vPROXY-PORT/$PROXY_PORT/g" /etc/redsocks.conf && \
    echo "Restarting redsocks and redirecting traffic via iptables" && \
    update-alternatives --set iptables /usr/sbin/iptables-legacy && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy && \
    /etc/init.d/redsocks restart

FROM base as nitro

ENV TEE_ENV=nitriding

COPY nitriding /
