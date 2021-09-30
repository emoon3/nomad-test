FROM alpine:latest

RUN apk add --update --no-cache curl py-pip
RUN apk add --no-cache bash
RUN apk add sqlite
RUN mkdir /app

COPY requirements.txt /app
COPY schema.sql /app
COPY app_b.py /app

WORKDIR /app

RUN pip3 install -r requirements.txt
RUN sqlite3 database.db < schema.sql

ENTRYPOINT [ "python3" ] 
CMD ["app_b.py"]