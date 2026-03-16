# Download stage – uses Corretto (confirmed accessible, has curl + dnf)
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023 AS downloader
ARG LOKI_VERSION=v3.6.7
ARG TARGETARCH
RUN dnf install -y unzip && \
    curl -fsSL -o /tmp/promtail.zip \
        "https://github.com/grafana/loki/releases/download/${LOKI_VERSION}/promtail-linux-${TARGETARCH}.zip" && \
    unzip /tmp/promtail.zip -d /tmp/promtail-extracted && \
    mv /tmp/promtail-extracted/promtail-linux-${TARGETARCH} /tmp/promtail && \
    chmod 755 /tmp/promtail

# Minimal final image – Promtail Go binary is statically compiled
FROM gcr.io/distroless/static:nonroot
COPY --from=downloader /tmp/promtail /usr/bin/promtail
EXPOSE 9080
ENTRYPOINT ["/usr/bin/promtail"]
CMD ["-config.file=/etc/promtail/config.yml"]
