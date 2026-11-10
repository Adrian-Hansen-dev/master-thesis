# syntax=docker/dockerfile:1
FROM maven:3.8.8-eclipse-temurin-8

WORKDIR /workspace

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

CMD ["/scripts/verify-baseline.sh"]
