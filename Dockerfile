FROM node:18-alpine

RUN npm install -g http-server

WORKDIR /usr/src/app

COPY ./pages /usr/src/app

EXPOSE 8080

CMD ["http-server", "-p", "8080"]
