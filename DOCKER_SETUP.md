# Docker Setup Guide

## Prerequisites
- Docker Desktop installed and running
- Docker Compose installed (comes with Docker Desktop)

## Getting Started

### 1. Build and Start Services
```bash
docker-compose up --build
```

This will:
- Build the Rails app container
- Start PostgreSQL database
- Start Redis server
- Start Sidekiq background worker
- Create and migrate databases automatically
- Start the Rails server on port 3000

### 2. Access the Application
- Rails App: http://localhost:3000
- PostgreSQL: localhost:5432
- Redis: localhost:6379

### 3. Common Commands

**Start services (detached mode)**
```bash
docker-compose up -d
```

**Stop services**
```bash
docker-compose down
```

**View logs**
```bash
docker-compose logs -f
docker-compose logs -f web      # Rails app only
docker-compose logs -f sidekiq  # Sidekiq only
```

**Run Rails commands**
```bash
docker-compose exec web bundle exec rails console
docker-compose exec web bundle exec rails db:migrate
docker-compose exec web bundle exec rails db:seed
docker-compose exec web bundle exec rails routes
```

**Run tests**
```bash
docker-compose exec web bundle exec rspec
```

**Rebuild containers (after Gemfile changes)**
```bash
docker-compose up --build
```

**Reset database**
```bash
docker-compose exec web bundle exec rails db:reset
```

**Access Rails console**
```bash
docker-compose exec web bundle exec rails console
```

**Stop and remove all containers + volumes**
```bash
docker-compose down -v
```

## Troubleshooting

### Port already in use
If port 3000, 5432, or 6379 is already in use, either:
- Stop the service using that port
- Or modify the port mapping in docker-compose.yml

### Database connection issues
Ensure PostgreSQL is healthy:
```bash
docker-compose ps
```

### Bundle install issues
Rebuild the container:
```bash
docker-compose build --no-cache web
```

### If already running
```bash
docker-compose up -d --force-recreate web sidekiq
```

## Environment Variables
All environment variables are configured in docker-compose.yml:
- `POSTGRES_HOST`: db
- `POSTGRES_USER`: postgres
- `POSTGRES_PASSWORD`: postgres
- `REDIS_URL`: redis://redis:6379/0
- `RAILS_ENV`: development
