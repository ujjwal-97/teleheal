# Use OpenJDK 24 as base image
FROM openjdk:24-jdk-slim

# Set working directory
WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradlew gradlew.bat ./
COPY gradle/ gradle/
COPY build.gradle settings.gradle ./

# Make gradlew executable
RUN chmod +x gradlew

# Copy source code
COPY src/ src/

# Build the application
RUN ./gradlew build -x test

# Expose port 8080
EXPOSE 8080

# Run the Spring Boot application
# Spring profile will be set via environment variable in docker-compose or at runtime
CMD ["java", "-jar", "build/libs/teleheal-backend-0.0.1-SNAPSHOT.jar"]
