#!/bin/bash

# Build and Deploy Housing Price Prediction App
set -e

echo "🏠 Building Housing Price Prediction Application"

# Check if Kubernetes cluster is available
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ No Kubernetes cluster available. Please start minikube or kind:"
    echo "   minikube start"
    echo "   OR"
    echo "   kind create cluster --name housing-app"
    exit 1
fi
echo "✅ Kubernetes cluster is available"

# Configuration
NAMESPACE="housing-app"
REGISTRY=""
TAG="latest"

# Set image names based on whether registry is provided
if [ -z "$REGISTRY" ]; then
    API_IMAGE="housing-api:$TAG"
    FRONTEND_IMAGE="housing-frontend:$TAG"
    NGINX_IMAGE="housing-nginx:$TAG"
else
    API_IMAGE="$REGISTRY/housing-api:$TAG"
    FRONTEND_IMAGE="$REGISTRY/housing-frontend:$TAG"
    NGINX_IMAGE="$REGISTRY/housing-nginx:$TAG"
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Build Docker images
echo "🔨 Building Docker images..."

# Build API
echo "Building API image..."
docker build --no-cache -f Dockerfile.api -t $API_IMAGE .

# Build Frontend  
echo "Building Frontend image..."
docker build --no-cache -f Dockerfile.frontend -t $FRONTEND_IMAGE .

# Build NGINX
echo "Building NGINX image..."
docker build --no-cache -f Dockerfile.nginx -t $NGINX_IMAGE .


# Push images (uncomment when ready)
# echo "📤 Pushing images to registry..."
# docker push $REGISTRY/housing-api:$TAG
# docker push $REGISTRY/housing-frontend:$TAG  
# docker push $REGISTRY/housing-nginx:$TAG

# For local testing with minikube/kind, load images directly
if command -v minikube &> /dev/null; then
    echo "🚀 Loading images to minikube..."
    minikube image load $API_IMAGE
    minikube image load $FRONTEND_IMAGE
    minikube image load $NGINX_IMAGE
elif command -v kind &> /dev/null; then
    echo "🚀 Loading images to kind..."
    kind load docker-image $API_IMAGE
    kind load docker-image $FRONTEND_IMAGE
    kind load docker-image $NGINX_IMAGE
fi

# Deploy to Kubernetes
echo "☸️  Deploying to Kubernetes..."

# Clean up existing resources more aggressively
echo "🧹 Cleaning up existing resources..."
kubectl delete job model-loader -n $NAMESPACE --ignore-not-found=true --timeout=60s || true
kubectl delete pvc model-pvc -n $NAMESPACE --ignore-not-found=true --timeout=60s || true

# Force cleanup if needed
kubectl delete job model-loader -n $NAMESPACE --force --grace-period=0 --ignore-not-found=true 2>/dev/null || true
kubectl delete pvc model-pvc -n $NAMESPACE --force --grace-period=0 --ignore-not-found=true 2>/dev/null || true

# Wait for cleanup to complete
echo "⏳ Waiting for cleanup to complete..."
sleep 10

# Verify cleanup
echo "🔍 Verifying cleanup..."
kubectl get pvc,jobs -n $NAMESPACE --ignore-not-found=true

# Apply ConfigMaps
echo "📝 Applying model configuration..."
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
kubectl wait --for=condition=available --timeout=10s deployment/housing-api -n $NAMESPACE
kubectl wait --for=condition=available --timeout=10s deployment/housing-frontend -n $NAMESPACE
kubectl wait --for=condition=available --timeout=10s deployment/housing-nginx -n $NAMESPACE

# Get service information
echo "🌐 Service information:"
kubectl get services -n $NAMESPACE

# Port forwarding for local access (optional)
echo "🔗 To access the application locally, run:"
echo "kubectl port-forward service/housing-nginx-service 8080:80 -n $NAMESPACE"
echo "Then open http://localhost:8080"

echo "✅ Deployment complete!"