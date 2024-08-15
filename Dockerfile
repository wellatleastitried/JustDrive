FROM node:latest

RUN npm install -g http-server

WORKDIR /usr/src/wardriver/frontend

COPY ./pages /usr/src/wardriver/frontend

EXPOSE 8080

CMD ["http-server", "-p", "8080"]
