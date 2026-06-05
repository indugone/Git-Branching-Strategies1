# ---------- Stage 1: Install dependencies -----------
FROM node:20-slim AS deps
WORKDIR /app
 
COPY package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./
 
RUN npm install
 
# ---------- Stage 2: Build Expo Web (PWA: icons/splash + export + service worker) ----------
FROM node:20-slim AS builder
WORKDIR /app
 
COPY --from=deps /app/node_modules ./node_modules
COPY . .
 
# Non-interactive export; full `build:web` = copy PWA public assets, `expo export -p web`, Workbox `sw.js`
ENV CI=1
ENV EXPO_NO_TELEMETRY=1
RUN npm run build:web
 
# ---------- Stage 3: Production ----------
FROM nginx:alpine AS runner
 
COPY --from=builder /app/dist /usr/share/nginx/html
 
# SPA fallback so Expo Router / deep links work when launched like an app (refresh, direct URL)
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf
 
EXPOSE 80
 
CMD ["nginx", "-g", "daemon off;"]
 
 
