# syntax=docker/dockerfile:1

FROM golang:1.23-bookworm AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=1 go build -ldflags="-s -w" -o /out/crush ./

FROM debian:bookworm-slim AS runtime
ARG USERNAME=crush
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"

ENV HOME=/home/${USERNAME} \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share

WORKDIR /workspace

RUN mkdir -p /workspace \
    && mkdir -p "${XDG_CONFIG_HOME}/crush" "${XDG_DATA_HOME}/crush" \
    && chown -R "${USERNAME}:${USERNAME}" /workspace "${HOME}"

COPY --from=build /out/crush /usr/local/bin/crush

USER ${USERNAME}

ENTRYPOINT ["crush"]
