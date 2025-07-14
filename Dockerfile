# syntax=docker/dockerfile:1.7
# check=error=true

FROM alpine:latest

RUN apk add --no-cache zig build-base musl-dev
WORKDIR /app
COPY . .

RUN zig build

CMD ["./zig-out/bin/rmt"]
