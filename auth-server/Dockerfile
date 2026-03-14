FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace/app

COPY pom.xml .
COPY src ./src

RUN apk add --no-cache maven && \
    mvn package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

COPY --from=build /workspace/app/target/*.jar app.jar

USER spring:spring

EXPOSE 9000

ENTRYPOINT ["java", "-jar", "app.jar"]
