docker run --rm -d --name pages_frontend -p 8080:8080 -v "$(pwd)"/pages:/usr/src/wardriver pages_frontend && perl driver/scripts/justDrive
