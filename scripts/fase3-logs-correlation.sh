#!/usr/bin/env bash
# Fase 3 — Correlación logs-trazas: crea IAM role para Grafana y despliega datasources
set -euo pipefail

CLUSTER_NAME="otel-cluster"
REGION="us-east-2"
NAMESPACE="observability"
POLICY_NAME="GrafanaCloudWatchLogsPolicy"
POLICY_FILE="$(dirname "$0")/../iam/grafana-cloudwatch-policy.json"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $AWS_ACCOUNT_ID"

# 1. Crear IAM policy para leer CloudWatch Logs
echo "==> Creando IAM policy $POLICY_NAME..."
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "file://$POLICY_FILE" \
    --query 'Policy.Arn' \
    --output text 2>/dev/null) || \
    POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

echo "Policy ARN: $POLICY_ARN"

# 2. Crear service account con IRSA para Grafana
echo "==> Creando service account IRSA para grafana..."
eksctl create iamserviceaccount \
    --cluster="$CLUSTER_NAME" \
    --region="$REGION" \
    --namespace="$NAMESPACE" \
    --name=grafana \
    --attach-policy-arn="$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve

echo "==> Service account creado:"
kubectl get serviceaccount grafana -n "$NAMESPACE" -o yaml | grep -A5 annotations

# 3. Aplicar datasources (Jaeger + CloudWatch) y actualizar Grafana
echo "==> Aplicando grafana-provisioning.yaml..."
kubectl apply -f "$(dirname "$0")/../k8s/aws/grafana-provisioning.yaml"

echo "==> Aplicando grafana.yaml (con serviceAccountName)..."
kubectl apply -f "$(dirname "$0")/../k8s/aws/grafana.yaml"

echo "==> Reiniciando Grafana para cargar nueva configuración..."
kubectl rollout restart deployment/grafana -n "$NAMESPACE"
kubectl rollout status deployment/grafana -n "$NAMESPACE" --timeout=120s

echo ""
echo "==> LISTO. Datasources disponibles en Grafana:"
echo "   - Prometheus   → métricas"
echo "   - Jaeger       → trazas (interno, para correlación)"
echo "   - CloudWatch   → logs con link a Jaeger por trace_id"
echo ""
echo "==> Cómo verificar la correlación:"
echo "   1. Abrir Grafana → Explore"
echo "   2. Seleccionar datasource: CloudWatch Logs"
echo "   3. Log group: /otel/service-a/logs"
echo "   4. Query: fields @timestamp, @message | sort @timestamp desc | limit 20"
echo "   5. En cualquier log line, click en TraceID para abrir el trace en Jaeger"
