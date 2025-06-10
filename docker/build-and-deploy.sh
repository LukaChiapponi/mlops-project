#!/bin/bash

# Enhanced build-and-deploy.sh for CI/CD
set -e  # Exit on any error

# Configuration
REGISTRY=${REGISTRY:-"localhost:5000"}
TAG=${TAG:-"latest"}
NAMESPACE=${NAMESPACE:-"housing-app"}

API_IMAGE="$REGISTRY/housing-api:$TAG"
FRONTEND_IMAGE="$REGISTRY/housing-frontend:$TAG"
NGINX_IMAGE="$REGISTRY/housing-nginx:$TAG"

echo "🚀 Starting deployment with:"
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo "Namespace: $NAMESPACE"

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

# Push images to registry (for production)
if [ "$REGISTRY" != "localhost:5000" ] && [ -n "$GITHUB_ACTIONS" ]; then
    echo "📤 Pushing images to registry..."
    docker push $API_IMAGE
    docker push $FRONTEND_IMAGE
    docker push $NGINX_IMAGE
else
    # For local testing with minikube/kind, load images directly
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
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

# Apply ConfigMaps first
echo "📝 Applying configurations..."
kubectl create configmap nginx-config --from-file=nginx.conf -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

if [ -f "k8s-model-configmap.yaml" ]; then
    kubectl apply -f k8s-model-configmap.yaml -n $NAMESPACE
fi

# Update deployment files with new image tags
echo "🏷️  Updating image tags in deployment files..."
sed -i.bak "s|image: .*housing-api.*|image: $API_IMAGE|g" k8s-api-deployment.yaml
sed -i.bak "s|image: .*housing-frontend.*|image: $FRONTEND_IMAGE|g" k8s-frontend-deployment.yaml  
sed -i.bak "s|image: .*housing-nginx.*|image: $NGINX_IMAGE|g" k8s-nginx-deployment.yaml

# Deploy services
echo "🚀 Deploying services..."
kubectl apply -f k8s-api-deployment.yaml -n $NAMESPACE
kubectl apply -f k8s-frontend-deployment.yaml -n $NAMESPACE
kubectl apply -f k8s-nginx-deployment.yaml -n $NAMESPACE

# Add automatic rollout restart for updated deployments
echo "🔄 Rolling out updates..."
kubectl rollout restart deployment/housing-api -n $NAMESPACE
kubectl rollout restart deployment/housing-frontend -n $NAMESPACE  
kubectl rollout restart deployment/housing-nginx -n $NAMESPACE

# Wait for rollout to complete
echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/housing-api -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/housing-frontend -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/housing-nginx -n $NAMESPACE --timeout=300s

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=30s deployment/housing-api -n $NAMESPACE
kubectl wait --for=condition=available --timeout=30s deployment/housing-frontend -n $NAMESPACE
kubectl wait --for=condition=available --timeout=30s deployment/housing-nginx -n $NAMESPACE

# Get service information
echo "🌐 Service information:"
kubectl get services -n $NAMESPACE

# Clean up backup files
rm -f k8s-*-deployment.yaml.bak

echo "✅ Deployment complete!"
echo ""
echo "🔗 To access the application locally, run:"
echo "kubectl port-forward service/housing-nginx-service 8080:80 -n $NAMESPACE"
echo "Then open http://localhost:8080"