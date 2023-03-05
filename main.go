package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	playPb "github.com/athlas-app/play/pb"
)

func main() {
	r := chi.NewRouter()

	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	mux := runtime.NewServeMux()

	playServerUrl := os.Getenv("PLAY_SERVER_URL") // Replace with `localhost:8080` if you want to run the gRPC server locally
	playPbErr := playPb.RegisterPlayHandlerFromEndpoint(context.Background(), mux, playServerUrl, []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())})
	if playPbErr != nil {
		log.Fatalf("failed to register gateway: %v", playPbErr)
	}

	r.HandleFunc("/*", func(w http.ResponseWriter, r *http.Request) {
		mux.ServeHTTP(w, r)
	})

    port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Default().Println("Starting gRPC gateway on port " + port)
	http.ListenAndServe(":" + port, r)
}
