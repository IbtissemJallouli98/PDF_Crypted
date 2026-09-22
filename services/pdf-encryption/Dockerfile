FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY src src
RUN mvn -q package -DskipTests && test -f /build/target/pdf-encryption-service-all.jar

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S -G app app
WORKDIR /app
COPY --from=build /build/target/pdf-encryption-service-all.jar /app/service.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/service.jar"]
