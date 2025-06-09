#!/bin/bash

# Local Testing Script for Housing Price Prediction App
set -e

echo "🧪 Testing Housing Price Prediction App Locally"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if model file exists
if [ ! -f "trained_model.h5" ]; then
    echo "❌ Model file 'trained_model.h5' not found. Please ensure the model file is present."
    exit 1
fi
echo "✅ Found model file"

# Test with Docker Compose
echo "🐳 Starting services with Docker Compose..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Health checks
echo "🔍 Performing health checks..."

# Check API health
API_HEALTH=$(curl -s http://localhost:8001/health || echo "failed")
if [[ "$API_HEALTH" == *"healthy"* ]]; then
    echo "✅ API is healthy"
else
    echo "❌ API health check failed"
    echo "API Response: $API_HEALTH"
fi

# Check frontend
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 || echo "failed")
if [[ "$FRONTEND_STATUS" == "200" ]]; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend check failed (HTTP: $FRONTEND_STATUS)"
fi

# Check NGINX
NGINX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "failed")
if [[ "$NGINX_STATUS" == "200" ]]; then
    echo "✅ NGINX is routing correctly"
else
    echo "❌ NGINX check failed (HTTP: $NGINX_STATUS)"
fi

# Test API prediction
echo "🔮 Testing prediction API..."
PREDICTION_TEST=$(curl -s -X POST "http://localhost:8001/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "CRIM": 0.00632,
    "ZN": 18.0,
    "INDUS": 2.31,
    "CHAS": 0,
    "NOX": 0.538,
    "RM": 6.575,
    "AGE": 65.2,
    "DIS": 4.0900,
    "TAX": 296.0,
    "PTRATIO": 15.3,
    "LSTAT": 4.98
  }' || echo "failed")

if [[ "$PREDICTION_TEST" == *"predicted_price"* ]]; then
    echo "✅ Prediction API is working"
    echo "Sample prediction: $PREDICTION_TEST"
else
    echo "❌ Prediction API test failed"
    echo "Response: $PREDICTION_TEST"
fi

# Show running containers
echo "📊 Running containers:"
docker-compose ps

echo ""
echo "🌐 Access URLs:"
echo "  - Full Application: http://localhost:8080"
echo "  - API directly: http://localhost:8001"
echo "  - Frontend directly: http://localhost:3001"
echo ""
echo "📋 To view logs:"
echo "  - API logs: docker-compose logs api"
echo "  - Frontend logs: docker-compose logs frontend"
echo "  - NGINX logs: docker-compose logs nginx"
echo ""
echo "🛑 To stop services:"
echo "  docker-compose down"