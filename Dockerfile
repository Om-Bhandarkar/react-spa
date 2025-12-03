FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install   # use this instead of npm ci

COPY . .

RUN npm run build

FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80
