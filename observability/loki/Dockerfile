# Download stage – uses Corretto (confirmed accessible, has curl + dnf)
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023 AS downloader
ARG LOKI_VERSION=v3.6.7
ARG TARGETARCH
RUN dnf install -y unzip && \
    curl -fsSL -o /tmp/loki.zip \
        "https://github.com/grafana/loki/releases/download/${LOKI_VERSION}/loki-linux-${TARGETARCH}.zip" && \
    unzip /tmp/loki.zip -d /tmp/loki-extracted && \
    mv /tmp/loki-extracted/loki-linux-${TARGETARCH} /tmp/loki && \
    chmod 755 /tmp/loki && \
    mkdir -p /tmp/loki-data

# Minimal final image – Loki Go binary is statically compiled
FROM gcr.io/distroless/static:nonroot
COPY --from=downloader /tmp/loki /usr/bin/loki
COPY --from=downloader --chown=65532:65532 /tmp/loki-data /loki
EXPOSE 3100
ENTRYPOINT ["/usr/bin/loki"]
CMD ["-config.file=/etc/loki/local-config.yaml"]
