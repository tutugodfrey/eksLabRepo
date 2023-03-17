FROM public.ecr.aws/docker/library/httpd:2.4

RUN apt-get update && apt-get -y install cron && apt-get install vim -y
COPY cron /etc/cron.d/
COPY index.html /usr/local/apache2/htdocs/
COPY metadata.sh /usr/local/apache2/htdocs/
COPY copy-metadata-file.sh /
COPY font /usr/local/apache2/htdocs/font
COPY images /usr/local/apache2/htdocs/images
RUN mkdir /var/metadata
RUN chmod -R 0777 /var/metadata/
RUN chmod +x /usr/local/apache2/htdocs/metadata.sh
RUN chmod +x /copy-metadata-file.sh
RUN chmod 644 /etc/cron.d/cron
RUN crontab /etc/cron.d/cron
EXPOSE 80
WORKDIR /usr/local/apache2/htdocs/
CMD ./metadata.sh && crontab && crontab /etc/cron.d/cron && service cron restart && apachectl -D FOREGROUND
