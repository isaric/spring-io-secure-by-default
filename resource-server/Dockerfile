# maven:3.9-eclipse-temurin-17 is multi-arch (linux/amd64, linux/arm64) and has Maven pre-installed
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /workspace/app

COPY pom.xml .
COPY src ./src

RUN mvn package -DskipTests -q

# eclipse-temurin:17-jre-jammy is multi-arch (linux/amd64, linux/arm64)
FROM eclipse-temurin:17-jre-jammy

RUN groupadd --system spring && useradd --system --gid spring spring

WORKDIR /app

COPY --from=build /workspace/app/target/*.jar app.jar

USER spring:spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
