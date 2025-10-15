# Build stage using Alpine with Go (not Chainguard)
FROM cgr.dev/chainguard/go:latest AS build

ENV CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o myapp main.go

# Runtime stage using scratch (not Chainguard)
FROM cgr.dev/chainguard/distroless-base:latest
WORKDIR /app

COPY --from=build /src/myapp .
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 8080
ENTRYPOINT ["./myapp"]


