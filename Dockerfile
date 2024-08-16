FROM node:latest

RUN npm install -g http-server

WORKDIR /usr/src/wardriver/pages

COPY ./pages /usr/src/wardriver/pages

EXPOSE 8080

CMD ["http-server", "-p", "8080"]
