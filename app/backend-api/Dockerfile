# Build stage using official Maven image (no mvnw needed)
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /workspace/app

# Copy pom.xml and source code
COPY pom.xml .
COPY src ./src

# Build the jar package
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /workspace/app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]