FROM node:18-alpine

RUN npm install -g http-server

WORKDIR /usr/src/app

COPY ./www/html /usr/src/app

EXPOSE 8080

CMD ["http-server", "-p", "8080"]
