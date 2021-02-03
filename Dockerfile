From nginx:1.15-alpine
COPY assets /etc/nginx/assets
COPY _posts /etc/nginx/_posts
WORKDIR /etc/nginx/assets