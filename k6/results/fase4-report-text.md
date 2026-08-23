# Fase 4 Analisis de Overhead OTel

## Metodologia del Benchmark

Se ejecuto una comparacion controlada entre dos escenarios de la misma aplicacion: un escenario baseline con `OTEL_ENABLED=false` y un escenario instrumentado con `OTEL_ENABLED=true`. En ambos casos se uso el mismo script `k6/overhead-test.js`, el mismo endpoint publico de `service-a` y la misma configuracion de carga. El endpoint probado fue `http://localhost:18080/request`, el cual ejecuta el flujo `service-a -> service-b -> PostgreSQL`.

## Herramienta utilizada

La herramienta utilizada fue K6 local (`k6.exe v2.2.0`). Para conservar evidencia se exportaron los resultados a `summary.json`, `output.txt` y `metrics.jsonl` en carpetas separadas para cada escenario. Adicionalmente, se capturo consumo de CPU y memoria de `service-a` y `service-b` mediante `docker stats`, guardado como `docker-stats.jsonl`.

## Escenarios de carga definidos

La prueba incluyo tres etapas: un warmup de 1 minuto aumentando hasta 10 VUs, una carga sostenida de 3 minutos con 50 VUs, y un spike de 1 minuto que inicio en 50 VUs, subio a 100 VUs y termino bajando a 50 VUs. La duracion efectiva de la prueba fue aproximadamente 5 minutos.

## Configuracion de la prueba

Los thresholds definidos fueron `p95 < 500 ms`, `p99 < 1000 ms`, `error rate < 1 %` y `success rate > 99 %`. El script agrupa la URL con `http.url` para evitar alta cardinalidad en K6, pero mantiene la misma ruta real y el mismo parametro `input` dinamico en ambos escenarios.

## Ejecucion Baseline (sin OTel)

En el escenario baseline se ejecuto la aplicacion con `OTEL_ENABLED=false` en `service-a` y `service-b`. Se verifico que `/request` respondiera HTTP 200 y que `/metrics` no estuviera expuesto en los servicios. La prueba completa finalizo con 358529 requests, 0.00 % de errores, 100.00 % de success rate y un throughput de 1194.92 req/s. La latencia promedio fue 39.70 ms, p95 fue 60.37 ms y p99 fue 80.82 ms.

## Ejecucion con instrumentacion OTel

En el escenario instrumentado se ejecuto la aplicacion con `OTEL_ENABLED=true` en `service-a` y `service-b`. Se verifico que `/request` respondiera HTTP 200, que `/metrics` estuviera disponible y que Prometheus tuviera targets `up` para `service-a`, `service-b`, `otel-collector` y `otel-collector-metrics`. La prueba completa finalizo con 304264 requests, 0.00 % de errores, 100.00 % de success rate y un throughput de 1013.98 req/s. La latencia promedio fue 46.79 ms, p95 fue 70.76 ms y p99 fue 119.49 ms.

## Tabla Comparativa de Overhead

| Metrica | Sin OTel | Con OTel | Overhead |
| --- | ---: | ---: | ---: |
| Latencia promedio (ms) | 39.70 | 46.79 | 17.86% |
| Latencia p95 (ms) | 60.37 | 70.76 | 17.22% |
| Latencia p99 (ms) | 80.82 | 119.49 | 47.85% |
| Error rate (%) | 0.00 | 0.00 | 0.00 pp |
| Success rate (%) | 100.00 | 100.00 | 0.00 pp |
| Throughput (req/s) | 1194.92 | 1013.98 | 15.14% degradacion |
| CPU promedio | 244.36% | 259.21% | 6.08% |
| Memoria promedio (MB) | 160.55 | 241.98 | +81.43 MB |

## Analisis de Resultados

Los resultados muestran que OpenTelemetry introdujo overhead medible, pero la aplicacion mantuvo estabilidad funcional durante toda la prueba. En ambos escenarios el error rate fue 0.00 % y el success rate fue 100.00 %, por lo que la instrumentacion no genero fallos HTTP bajo la carga evaluada.

## Impacto en latencia

La latencia promedio aumento de 39.70 ms a 46.79 ms, equivalente a un overhead de 17.86 %. La latencia p95 aumento de 60.37 ms a 70.76 ms, equivalente a 17.22 %. El mayor impacto relativo se observo en p99, que paso de 80.82 ms a 119.49 ms, equivalente a 47.85 %. Esto indica que la instrumentacion afecta principalmente la cola de latencias mas altas, aunque los valores siguieron dentro de los thresholds definidos.

## Impacto en CPU y memoria

El CPU promedio combinado de `service-a` y `service-b` aumento de 244.36 % a 259.21 %, equivalente a 6.08 % de overhead. La memoria promedio combinada aumento de 160.55 MB a 241.98 MB, es decir, 81.43 MB adicionales. Por servicio, `service-a` paso de 84.70 % CPU y 60.88 MB a 95.08 % CPU y 101.98 MB; `service-b` paso de 159.66 % CPU y 99.67 MB a 164.12 % CPU y 140.00 MB.

## Conclusion sobre el overhead de OTel

Con la configuracion probada, OpenTelemetry genero un overhead moderado en latencia promedio y p95, un impacto mas visible en p99, un incremento bajo en CPU y un aumento importante en memoria. A cambio, el sistema produjo trazas distribuidas, metricas y logs exportados por OTLP. Para este laboratorio, el overhead observado se considera aceptable porque la aplicacion mantuvo 0.00 % de errores, 100.00 % de success rate y todos los percentiles de latencia permanecieron por debajo de los thresholds definidos.

## Evidencias recomendadas

1. Docker Compose: capturar `docker compose ps` mostrando `service-a`, `service-b`, `postgres`, `otel-collector`, `jaeger`, `prometheus` y `grafana` en estado `Up`; PostgreSQL debe verse `healthy`.
2. K6 baseline: capturar el final de `k6/results/baseline/output.txt` o la terminal donde se vea `checks 100.00%`, `http_req_failed 0.00%`, `http_reqs 358529` y `p(95)=60.36ms`.
3. K6 con OTel: capturar el final de `k6/results/otel/output.txt` donde se vea `checks 100.00%`, `http_req_failed 0.00%`, `http_reqs 304264` y `p(95)=70.76ms`.
4. Prometheus: abrir `http://localhost:9090/targets` y capturar los targets `service-a`, `service-b`, `otel-collector` y `otel-collector-metrics` en estado `UP`.
5. Jaeger: abrir `http://localhost:16686`, seleccionar `service-a`, buscar una traza reciente de K6 y mostrar el detalle con el mismo `traceID` atravesando `service-a` y `service-b`, incluyendo spans `handle-request`, `validate-input`, `call-service-b`, `process-request`, `business-logic`, `save-to-database` y el span `appdb` con `db.system=postgresql`.
6. Comparacion final: capturar la tabla de `k6/results/overhead-summary.md` o esta seccion del informe con las columnas `Sin OTel`, `Con OTel` y `Overhead`.
