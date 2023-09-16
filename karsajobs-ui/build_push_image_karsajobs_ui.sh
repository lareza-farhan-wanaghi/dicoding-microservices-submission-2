#!/bin/bash

# Build Docker image
docker build -t ghcr.io/lareza-farhan-wanaghi/karsajobs-ui:latest .

# Log in to GitHub Container Registry
docker login ghcr.io -u lareza-farhan-wanaghi -p $GH_PACKAGES_TOKEN

# Push Docker image to GitHub Container Registry
docker push ghcr.io/lareza-farhan-wanaghi/karsajobs-ui:latest
