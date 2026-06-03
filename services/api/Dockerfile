FROM node:22-alpine AS build
WORKDIR /app/services/api
COPY services/api/package.json services/api/package-lock.json ./
RUN npm ci
COPY tsconfig.base.json /app/tsconfig.base.json
COPY services/api/tsconfig.json ./
COPY services/api/src ./src
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app/services/api
ENV NODE_ENV=production
COPY services/api/package.json services/api/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/services/api/dist ./dist
EXPOSE 3000
USER node
CMD ["node", "dist/index.js"]
