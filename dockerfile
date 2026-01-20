FROM harbor.ingress.lab.gitfitlive.com/mirror/nginx:alpine


RUN rm -rf /usr/share/nginx/html/*

COPY src/ /usr/share/nginx/html/

# COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
