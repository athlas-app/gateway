FROM golang:1.19-alpine as builder

RUN apk --update add ca-certificates git openssh-client

WORKDIR /app
COPY go.mod go.sum ./

ENV CGO_ENABLED=0 GOOS=linux GOPRIVATE=github.com/athlas-app/*

# Create the /root/.ssh directory
RUN mkdir -p /root/.ssh

# Copy the SSH key with access to private repositories
ARG SSH_PRIVATE_KEY
RUN echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

# Set up gitconfig
RUN --mount=type=ssh git config --global url.ssh://git@github.com/.insteadOf https://github.com/ && \
    go mod download

COPY . .

# Build the server binary
RUN go build -v -o server main.go

# Start a new stage from the Alpine base image
FROM alpine:3.15

# Install any necessary dependencies
RUN apk --no-cache add ca-certificates

# Install Doppler CLI
RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    apk add doppler

# Copy the server binary from the builder stage
COPY --from=builder /app/server /server

# Expose the gRPC server port
EXPOSE 8080

# Run the server binary
ENTRYPOINT ["doppler", "run", "--"]
CMD ["/server"]
