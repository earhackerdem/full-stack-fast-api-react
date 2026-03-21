#!/usr/bin/env bash
set -e

if [ -f .env ]; then
  echo ".env already exists. Delete it first to re-run setup."
  exit 0
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required but not installed."
  exit 1
fi

cp .env.example .env

generate_secret() {
  python3 -c "import secrets; print(secrets.token_urlsafe(32))"
}

SECRET=$(generate_secret)
sed -i.bak "s|^SECRET_KEY=changethis|SECRET_KEY=$SECRET|" .env

PW=$(generate_secret)
sed -i.bak "s|^FIRST_SUPERUSER_PASSWORD=changethis|FIRST_SUPERUSER_PASSWORD=$PW|" .env

PGPW=$(generate_secret)
sed -i.bak "s|^POSTGRES_PASSWORD=changethis|POSTGRES_PASSWORD=$PGPW|" .env

rm -f .env.bak

echo ".env created with generated secrets."
echo ""
echo "You can edit .env to customize PROJECT_NAME, FIRST_SUPERUSER, SMTP settings, etc."
echo "Run 'make dev' to start the full stack."
