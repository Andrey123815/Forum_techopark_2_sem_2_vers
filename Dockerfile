FROM golang:1.15 AS build

ADD . /app
WORKDIR /app
RUN go build ./cmd/main.go

FROM ubuntu:20.04

RUN apt-get -y update && apt-get install -y tzdata
ENV TZ=Russia/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && apt-get install -y postgresql-12
USER postgres

RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER admin WITH SUPERUSER PASSWORD 'pass';" &&\
    createdb -O admin forum &&\
    /etc/init.d/postgresql stop

EXPOSE 5432
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
USER root

WORKDIR /usr/src/app

COPY . .
COPY --from=build /app/main/ .

EXPOSE 5000
ENV PGPASSWORD pass
CMD service postgresql start && psql -h localhost -d forum -U admin -p 5432 -a -q -f ./db/db.sql && ./main