FROM public.ecr.aws/docker/library/python:alpine3.16

RUN python3 --version
RUN pip3 --version
RUN apk add --no-cache aws-cli
RUN aws --version
RUN mkdir /var/metadata/
COPY metadata2.sh /
COPY metadata2.json /
RUN chmod +x /metadata2.sh
RUN chmod -R 0777 /var/metadata/

CMD ./metadata2.sh 