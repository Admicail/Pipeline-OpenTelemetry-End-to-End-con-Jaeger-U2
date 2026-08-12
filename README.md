# Pipeline OpenTelemetry End-to-End con Jaeger

Pipeline de observabilidad end-to-end basado en OpenTelemetry que captura métricas, logs estructurados y trazas distribuidas desde una aplicación de microservicios desplegada en GCP GKE y AWS ECS.

## Arquitectura

- service-a: ASP.NET Core Web API (HTTP Gateway)
- service-b: ASP.NET Core Web API + PostgreSQL (Business Layer)
- OTel Collector: Recibe, procesa y exporta los 3 pilares
- Jaeger: Trazas distribuidas (GCP)
- AWS X-Ray: Trazas distribuidas (AWS)
- Prometheus + Grafana: Métricas y dashboards

## Integrantes

| Nombre | Responsabilidad |
|--------|----------------|
| Esteban Garay | Instrumentación OTel, GCP/GKE, Arquitectura |
| Carlos | AWS/ECS, OTel Collector AWS |
| John | Benchmark k6, Análisis de overhead |

## Estructura del Repositorio

- src/             Microservicios C#
- otel-collector/  Configuraciones del Collector
- terraform/       IaC para GCP y AWS
- helm/            Helm charts para GKE
- prometheus/      Configuración de Prometheus
- grafana/         Dashboards
- scripts/         Benchmarks k6
- docs/            Screenshots y documentación

## Levantar entorno local

    docker-compose up --build

## URLs locales

| Servicio   | URL                    |
|------------|------------------------|
| service-a  | http://localhost:8080  |
| service-b  | http://localhost:8081  |
| Jaeger UI  | http://localhost:16686 |
| Prometheus | http://localhost:9090  |
| Grafana    | http://localhost:3000  |
G