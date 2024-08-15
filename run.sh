#docker-compose up -d && docker-compose exec backend "perl /usr/src/wardriver/backend/scripts/justDrive"
#docker-compose up --build -d --remove-orphans
#docker-compose exec backend "perl backend/scripts/justDrive"
#docker attach "$(docker ps -q --filter 'ancestor=justdrive-backend')"
#docker attach backend
#perl backend/scripts/justDrive
#docker-compose up --build -d frontend && perl driver/scripts/justDrive
docker run --rm -d --name pages_frontend -p 8080:8080 -v "$(pwd)"/pages:/usr/src/wardriver pages_frontend && perl driver/scripts/justDrive
