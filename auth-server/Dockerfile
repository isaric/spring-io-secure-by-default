# Amazon Corretto 17 on Amazon Linux 2023 - multi-arch (linux/amd64, linux/arm64)
# Hosted on ECR Public Gallery (no Docker Hub rate limits)
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023 AS build

RUN dnf install -y maven && dnf install -y wget && dnf clean all

WORKDIR /workspace/app

COPY pom.xml .
COPY src ./src

RUN mvn package -DskipTests -q

FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023

WORKDIR /app

COPY --from=build /workspace/app/target/*.jar app.jar

# Use a non-root numeric UID/GID (shadow-utils not present in minimal image)
USER 1001:1001

EXPOSE 9000

ENTRYPOINT ["java", "-jar", "app.jar"]
