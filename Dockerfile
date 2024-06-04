FROM golang:alpine

WORKDIR /app

COPY main.go /app/

RUN go build -o main main.go

EXPOSE 8080

CMD ["./main"]