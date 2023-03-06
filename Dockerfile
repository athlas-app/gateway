FROM golang:alpine

RUN apk --update add ca-certificates git openssh-client

ARG GITHUB_TOKEN

ENV CGO_ENABLED=0 GOOS=linux GOPRIVATE=github.com/athlas-app/*

# Install Doppler CLI
RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    apk add doppler

WORKDIR /app
COPY . .

# Set up gitconfig
RUN echo "machine github.com login athlas-app password ${GITHUB_TOKEN}" > ~/.netrc

RUN go mod download

RUN go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .

ENTRYPOINT ["doppler", "run", "--"]
CMD ["/app/main"]
