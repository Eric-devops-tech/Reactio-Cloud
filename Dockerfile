FROM maven:3.9.11-eclipse-temurin-17 AS build
WORKDIR /workspace

COPY api/REACTIO-java/pom.xml ./pom.xml
RUN mvn -B dependency:go-offline

COPY api/REACTIO-java/src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

RUN groupadd --system --gid 10001 reactio \
    && useradd --system --uid 10001 --gid reactio --home-dir /app reactio \
    && mkdir -p /app/data \
    && chown -R reactio:reactio /app

COPY --from=build --chown=reactio:reactio /workspace/target/reactio-api-1.0.0.jar /app/reactio-api.jar

ENV SERVER_ADDRESS=0.0.0.0 \
    PORT=8080 \
    DB_URL=jdbc:h2:file:/app/data/reactio \
    DB_USER=sa \
    DB_PASSWORD= \
    SEED_ENABLED=true

VOLUME ["/app/data"]
EXPOSE 8080
USER reactio

ENTRYPOINT ["java", "-jar", "/app/reactio-api.jar"]
