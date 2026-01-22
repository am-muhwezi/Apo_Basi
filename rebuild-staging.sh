#!/bin/bash

docker compose -f docker-compose.staging.yml pull
docker compose -f docker-compose.staging.yml down -v
docker compose -f docker-compose.staging.yml up --build -d
docker system prune -f
