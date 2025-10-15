# Build stage using Alpine with Go (not Chainguard)
FROM artifactory.devhub-cloud.cisco.com/sto-cg-docker/go:1.24-dev AS build

ENV CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o myapp main.go

# Runtime stage using scratch (not Chainguard)
FROM artifactory.devhub-cloud.cisco.com/sto-cg-docker/static:latest-glibc
WORKDIR /app

COPY --from=build /src/myapp .
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 8080
ENTRYPOINT ["./myapp"]


