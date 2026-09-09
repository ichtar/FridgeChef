FROM nginx:1.27-alpine

ARG VERSION=dev
ARG COLOR=#2563eb
ARG TEXT=Fridge Chef

COPY index.html.template /tmp/index.html.template
RUN sed -e "s|{{VERSION}}|${VERSION}|g" \
        -e "s|{{COLOR}}|${COLOR}|g" \
        -e "s|{{TEXT}}|${TEXT}|g" \
        /tmp/index.html.template > /usr/share/nginx/html/index.html \
    && rm /tmp/index.html.template

EXPOSE 80
