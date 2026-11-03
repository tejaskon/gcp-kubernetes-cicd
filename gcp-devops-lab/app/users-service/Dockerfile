FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace/app
COPY . .
RUN ./mvnw install -DskipTests

FROM eclipse-temurin:21-jre-alpine
COPY --from=build /workspace/app/target/*.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]