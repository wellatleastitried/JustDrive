FROM node:latest

RUN npm install -g http-server

WORKDIR /usr/src/wardriver

COPY . /usr/src/wardriver

EXPOSE 80

CMD ["http-server", "-p", "8080"]
