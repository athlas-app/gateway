package main

import (
	"context"
	"crypto/tls"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"

	playPb "github.com/athlas-app/play/pb"
)

func main() {
	r := chi.NewRouter()

	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	mux := runtime.NewServeMux()

	playServerUrl := os.Getenv("PLAY_SERVER_URL") // Replace with `localhost:8080` if you want to run the gRPC server locally

	// Create TLS credentials for gRPC client
	creds := credentials.NewTLS(&tls.Config{
		// Use InsecureSkipVerify if you don't have a valid CA certificate for your Cloud Run service.
		// It's not recommended for production use.
		InsecureSkipVerify: true,
	})

	println(playServerUrl)
	playPbErr := playPb.RegisterPlayHandlerFromEndpoint(context.Background(), mux, playServerUrl, []grpc.DialOption{grpc.WithTransportCredentials(creds)})
	if playPbErr != nil {
		log.Fatalf("failed to register gateway: %v", playPbErr)
	}

	r.Mount("/", mux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Default().Println("Starting gRPC gateway on port " + port)
	http.ListenAndServe(":"+port, r)
}
