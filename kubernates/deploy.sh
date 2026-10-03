#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-apply}"

do_apply() {
  echo "======================================================"
  echo "Deploying Kubernetes Manifests..."
  echo "======================================================"

  echo "[1/6] Applying ConfigMap..."
  kubectl apply -f "${SCRIPT_DIR}/2_configmaps.yaml"

  echo "[2/6] Applying Discovery Server..."
  kubectl apply -f "${SCRIPT_DIR}/kubernetes-discoveryserver.yml"

  echo "[3/6] Applying Keycloak, Config Server, and Kafka..."
  kubectl apply -f "${SCRIPT_DIR}/1_keycloak.yml" -f "${SCRIPT_DIR}/3_configserver.yml" -f "${SCRIPT_DIR}/9_kafka.yml"

  echo "[4/6] Applying Microservices (accounts, loans, cards)..."
  kubectl apply -f "${SCRIPT_DIR}/5_accounts.yml" -f "${SCRIPT_DIR}/6_loans.yml" -f "${SCRIPT_DIR}/7_cards.yml"

  echo "[5/6] Applying Gateway Server and Message Service..."
  kubectl apply -f "${SCRIPT_DIR}/8_gateway.yml" -f "${SCRIPT_DIR}/10_message.yml"

  echo "[6/6] All manifests applied successfully!"
  echo ""
  kubectl get pods
}

do_delete() {
  echo "======================================================"
  echo "Deleting Kubernetes Resources..."
  echo "======================================================"

  echo "Deleting Microservices..."
  kubectl delete -f "${SCRIPT_DIR}/8_gateway.yml" -f "${SCRIPT_DIR}/10_message.yml" -f "${SCRIPT_DIR}/5_accounts.yml" -f "${SCRIPT_DIR}/6_loans.yml" -f "${SCRIPT_DIR}/7_cards.yml" --ignore-not-found=true

  echo "Deleting Keycloak, Config Server, and Kafka..."
  kubectl delete -f "${SCRIPT_DIR}/1_keycloak.yml" -f "${SCRIPT_DIR}/3_configserver.yml" -f "${SCRIPT_DIR}/9_kafka.yml" --ignore-not-found=true

  echo "Deleting Discovery Server and ConfigMap..."
  kubectl delete -f "${SCRIPT_DIR}/kubernetes-discoveryserver.yml" -f "${SCRIPT_DIR}/2_configmaps.yaml" --ignore-not-found=true

  echo ""
  echo "All resources deleted!"
}

do_status() {
  echo "======================================================"
  echo "Kubernetes Pods:"
  echo "======================================================"
  kubectl get pods
  echo ""
  echo "======================================================"
  echo "Kubernetes Services:"
  echo "======================================================"
  kubectl get svc
}

case "${ACTION}" in
  apply)
    do_apply
    ;;
  delete)
    do_delete
    ;;
  status)
    do_status
    ;;
  *)
    echo "Usage:"
    echo "  ./deploy.sh         (applies all manifests)"
    echo "  ./deploy.sh apply   (applies all manifests)"
    echo "  ./deploy.sh delete  (deletes all deployed manifests)"
    echo "  ./deploy.sh status  (shows pod and service status)"
    exit 1
    ;;
esac
