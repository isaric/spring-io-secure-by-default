# Amazon Corretto 17 on Amazon Linux 2023 - multi-arch (linux/amd64, linux/arm64)
# Hosted on ECR Public Gallery (no Docker Hub rate limits)
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023 AS build

RUN dnf install -y maven && dnf clean all

WORKDIR /workspace/app

COPY pom.xml .
COPY src ./src

RUN mvn package -DskipTests -q

FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023

WORKDIR /app

COPY --from=build /workspace/app/target/*.jar app.jar

# Startup script: waits for SPIRE cert files before launching Java so that
# Spring Boot's SSL bundle file watcher (reload-on-update: true) can register
# the paths at startup without hitting "is neither a file nor a directory".
COPY start.sh start.sh
RUN chmod +x start.sh

# Use a non-root numeric UID/GID (shadow-utils not present in minimal image)
USER 1001:1001

EXPOSE 8080

ENTRYPOINT ["/app/start.sh"]
