FROM debian:testing

RUN apt update && apt install -y \
    curl git build-essential \
    python3 python3-pip python3-venv

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:$PATH"