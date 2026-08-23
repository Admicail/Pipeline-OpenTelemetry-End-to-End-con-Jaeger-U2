# Fase 4 - Analisis de Overhead OTel

| Metrica | Sin OTel | Con OTel | Overhead |
| --- | ---: | ---: | ---: |
| Latencia promedio (ms) | 39.70 | 46.79 | 17.86% |
| Latencia p95 (ms) | 60.37 | 70.76 | 17.22% |
| Latencia p99 (ms) | 80.82 | 119.49 | 47.85% |
| Error rate (%) | 0.00 | 0.00 | 0.00 pp |
| Success rate (%) | 100.00 | 100.00 | 0.00 pp |
| Throughput (req/s) | 1194.92 | 1013.98 | 15.14% degradacion |
| CPU promedio | 244.36% | 259.21% | 6.08% |
| Memoria promedio (MB) | 160.55 | 241.98 | +81.43 MB (50.72%) |

## CPU y memoria por servicio

| Escenario | Servicio | CPU promedio | Memoria promedio (MB) | Muestras |
| --- | --- | ---: | ---: | ---: |
| Sin OTel | service-a | 84.70% | 60.88 | 27 |
| Sin OTel | service-b | 159.66% | 99.67 | 27 |
| Con OTel | service-a | 95.08% | 101.98 | 26 |
| Con OTel | service-b | 164.12% | 140.00 | 26 |
