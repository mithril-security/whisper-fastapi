FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root

COPY ./sev/sev-init.sh /root
COPY ./sev/sev-start.sh /root
COPY ./model_store_requirements.txt /root
COPY ./model_store.py /root

RUN ./sev-init.sh
RUN ./sev-start.sh

EXPOSE 80 443

CMD ./sev-start.sh
