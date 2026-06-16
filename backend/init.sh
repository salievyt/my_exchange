#!/bin/bash

# My Exchange Backend Initialization Script

set -e

echo "========================================="
echo "My Exchange Backend Initialization"
echo "========================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Check if Docker is installed (optional)
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo ""
    echo "Docker detected. You can use docker-compose for easier setup:"
    echo "  docker-compose up -d"
    echo ""
    read -p "Continue with manual setup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Copy environment file
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
    echo "Please edit .env file with your settings"
fi

# Run migrations
echo "Running migrations..."
python manage.py migrate

# Initialize data
echo "Initializing default data..."
python manage.py init_data

# Create logs directory
mkdir -p logs

echo ""
echo "========================================="
echo "Initialization completed successfully!"
echo "========================================="
echo ""
echo "Default users:"
echo "  Admin:    admin / admin123"
echo "  Cashier:  cashier1 / cashier123"
echo ""
echo "IMPORTANT: Change default passwords!"
echo ""
echo "To start the server:"
echo "  source venv/bin/activate"
echo "  python manage.py runserver"
echo ""
echo "API Documentation: http://localhost:8000/api/docs/"
echo "========================================="
