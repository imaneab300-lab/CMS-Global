FROM php:8.2-fpm-alpine

# Install system dependencies & PHP extensions
RUN apk add --no-cache nginx wget git bash \
    && docker-php-ext-install pdo_mysql bcmath

# Configure Nginx for the nested subdirectory structure
RUN echo 'server { \
    listen 80; \
    root /app/backend/public; \
    index index.php index.html; \
    charset utf-8; \
    location / { \
        try_files $uri $uri/ /index.php?$query_string; \
    } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        include fastcgi_params; \
    } \
}' > /etc/nginx/http.d/default.conf

# Setup working directory to absolute root first
WORKDIR /app
COPY . /app

# Install Composer packages straight inside backend
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN cd /app/backend && composer install --no-dev --optimize-autoloader

# Set explicit folder access rules for Laravel
RUN chown -R www-data:www-data /app/backend/storage /app/backend/bootstrap/cache

# Shift core execution workspace directly to backend folder for Railway commands
WORKDIR /app/backend

EXPOSE 80

# Boot both PHP-FPM and Nginx cleanly together
CMD php-fpm -D && nginx -g "daemon off;"