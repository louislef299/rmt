# syntax=docker/dockerfile:1.7
FROM alpine:edge

RUN apk add --no-cache build-base zig

WORKDIR /app

COPY . .

RUN zig build

CMD ["/app/zig-out/bin/rmt"]
