# Amazon Corretto 17 on Amazon Linux 2023 - multi-arch (linux/amd64, linux/arm64)
# Hosted on ECR Public Gallery (no Docker Hub rate limits)
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023 AS build

RUN dnf install -y maven && dnf clean all

WORKDIR /workspace/app

COPY pom.xml .
COPY src ./src

RUN mvn package -DskipTests -q

FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-al2023

RUN groupadd --system spring && useradd --system --gid spring spring

WORKDIR /app

COPY --from=build /workspace/app/target/*.jar app.jar

USER spring:spring

EXPOSE 9000

ENTRYPOINT ["java", "-jar", "app.jar"]
