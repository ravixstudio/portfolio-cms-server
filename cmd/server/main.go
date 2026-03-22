package main

import (
	"context"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ravixstudio/portfolio-cms-server/internal/config"
	sqlcdb "github.com/ravixstudio/portfolio-cms-server/internal/db/sqlc"
)

func main() {
	cfg := config.Load()

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("db: %v", err)
	}

	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("db ping: %v", err)
	}

	queries := sqlcdb.New(pool)

	_ = queries

	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"ok": true})
	})

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Error running server %v", err)
	}
}
