FROM node:20-bookworm-slim

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY src ./src

RUN mkdir -p /app/data /app/uploads \
  && chown -R node:node /app

USER node
EXPOSE 8080
ENV NODE_ENV=production
CMD ["node", "src/index.js"]
