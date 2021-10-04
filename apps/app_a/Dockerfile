FROM --platform=linux/amd64 alpine:latest

RUN apk add --update --no-cache curl py-pip
RUN apk add --no-cache bash
RUN mkdir /app

COPY requirements.txt /app
COPY app_a.py /app

WORKDIR /app

RUN pip3 install -r requirements.txt

EXPOSE 5000

ENTRYPOINT [ "python3" ] 
CMD [ "app_a.py" ]