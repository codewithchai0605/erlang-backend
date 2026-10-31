FROM erlang:29 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        rebar3 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY backend/ backend/
COPY proto/ proto/

WORKDIR /workspace/backend

RUN rebar3 as prod release

FROM erlang:29-slim AS runtime

ENV CHAT_HTTP_BIND=0.0.0.0 \
    CHAT_HTTP_PORT=10000

WORKDIR /opt/chat

COPY --from=build /workspace/backend/_build/prod/rel/chat/ ./

EXPOSE 10000

CMD ["/opt/chat/bin/chat", "foreground"]