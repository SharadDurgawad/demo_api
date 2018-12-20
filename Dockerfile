FROM openjdk:8-jre-alpine

ARG JAR_FILE
EXPOSE 8080
VOLUME /tmp

COPY target/${JAR_FILE} app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]