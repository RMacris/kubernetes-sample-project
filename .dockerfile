FROM node:latest
WORKDIR /node_test
COPY . .
RUN npm install
RUN npm start
