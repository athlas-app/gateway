FROM golang:alpine

RUN apk --update add ca-certificates git openssh-client

ARG SSH_PRIVATE_KEY

ENV CGO_ENABLED=0 GOOS=linux GOPRIVATE=github.com/athlas-app/*

# Install Doppler CLI
RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    apk add doppler

WORKDIR /app
COPY . .

# Add your SSH private key to the container
RUN echo $SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/ && \
    echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_ed25519 && \
    chmod 600 /root/.ssh/id_ed25519 && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

# Set up gitconfig
RUN git config --global url."git@github.com:".insteadOf "https://github.com/"

RUN go mod download

RUN go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .

ENTRYPOINT ["doppler", "run", "--"]
CMD ["/app/main"]
