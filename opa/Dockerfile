# Download stage – uses Corretto (confirmed accessible, has curl + dnf)
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023 AS downloader
ARG OPA_VERSION=v1.14.1
ARG TARGETARCH
RUN curl -fsSL -o /tmp/opa \
    "https://github.com/open-policy-agent/opa/releases/download/${OPA_VERSION}/opa_linux_${TARGETARCH}_static" && \
    chmod 755 /tmp/opa

# Minimal final image – OPA static binary needs no OS libraries
FROM gcr.io/distroless/static:nonroot
COPY --from=downloader /tmp/opa /opa
EXPOSE 8181
ENTRYPOINT ["/opa"]
CMD ["run"]
