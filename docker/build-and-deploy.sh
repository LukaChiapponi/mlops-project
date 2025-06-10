#!/bin/bash

# Build and Deploy Housing Price Prediction App
set -e

echo "🏠 Building Housing Price Prediction Application"

# Configuration
NAMESPACE="housing-app"
REGISTRY="your-registry.com"  # Replace with your container registry
TAG="latest"

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Build Docker images
echo "🔨 Building Docker images..."

# Build API
echo "Building API image..."
docker build -f Dockerfile.api -t $REGISTRY/housing-api:$TAG .

# Build Frontend  
echo "Building Frontend image..."
docker build -f Dockerfile.frontend -t $REGISTRY/housing-frontend:$TAG .

# Build NGINX
echo "Building NGINX image..."
docker build -f Dockerfile.nginx -t $REGISTRY/housing-nginx:$TAG .

# Push images (uncomment when ready)
# echo "📤 Pushing images to registry..."
# docker push $REGISTRY/housing-api:$TAG
# docker push $REGISTRY/housing-frontend:$TAG  
# docker push $REGISTRY/housing-nginx:$TAG

# For local testing with minikube/kind, load images directly
if command -v minikube &> /dev/null; then
    echo "🚀 Loading images to minikube..."
    minikube image load $REGISTRY/housing-api:$TAG
    minikube image load $REGISTRY/housing-frontend:$TAG
    minikube image load $REGISTRY/housing-nginx:$TAG
elif command -v kind &> /dev/null; then
    echo "🚀 Loading images to kind..."
    kind load docker-image $REGISTRY/housing-api:$TAG
    kind load docker-image $REGISTRY/housing-frontend:$TAG
    kind load docker-image $REGISTRY/housing-nginx:$TAG
fi

# Deploy to Kubernetes
echo "☸️  Deploying to Kubernetes..."

# Apply ConfigMaps first
kubectl apply -f k8s-model-configmap.yaml -n $NAMESPACE

# Deploy services
kubectl apply -f k8s-api-deployment.yaml -n $NAMESPACE
kubectl apply -f k8s-frontend-deployment.yaml -n $NAMESPACE
kubectl apply -f k8s-nginx-deployment.yaml -n $NAMESPACE

# Add automatic rollout restart for updated deployments
echo "🔄 Rolling out updates..."
kubectl rollout restart deployment/housing-api -n $NAMESPACE
kubectl rollout restart deployment/housing-frontend -n $NAMESPACE  
kubectl rollout restart deployment/housing-nginx -n $NAMESPACE

# Wait for rollout to complete
kubectl rollout status deployment/housing-api -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/housing-frontend -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/housing-nginx -n $NAMESPACE --timeout=300s

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/housing-api -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/housing-frontend -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/housing-nginx -n $NAMESPACE

# Get service information
echo "🌐 Service information:"
kubectl get services -n $NAMESPACE

# Port forwarding for local access (optional)
echo "🔗 To access the application locally, run:"
echo "kubectl port-forward service/housing-nginx-service 8080:80 -n $NAMESPACE"
echo "Then open http://localhost:8080"

echo "✅ Deployment complete!"