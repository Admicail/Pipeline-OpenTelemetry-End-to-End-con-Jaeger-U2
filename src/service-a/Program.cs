using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

var serviceName = builder.Configuration["OTEL_SERVICE_NAME"] ?? "service-a";
var otlpEndpoint = builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"] ?? "http://localhost:4317";
var otelEnabled = builder.Configuration.GetValue("OTEL_ENABLED", true);

if (otelEnabled)
{
    var resourceBuilder = ResourceBuilder.CreateDefault()
        .AddService(serviceName)
        .AddAttributes(new Dictionary<string, object>
        {
            ["deployment.environment"] = builder.Environment.EnvironmentName.ToLower()
        });

    builder.Services.AddOpenTelemetry()
        .WithTracing(tracing => tracing
            .SetResourceBuilder(resourceBuilder)
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddSource("ServiceA")
            .AddOtlpExporter(o => o.Endpoint = new Uri(otlpEndpoint)))
        .WithMetrics(metrics => metrics
            .SetResourceBuilder(resourceBuilder)
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddRuntimeInstrumentation()
            .AddPrometheusExporter());

    builder.Logging.AddOpenTelemetry(logging =>
    {
        logging.SetResourceBuilder(resourceBuilder);
        logging.AddOtlpExporter(o => o.Endpoint = new Uri(otlpEndpoint));
        logging.IncludeScopes = true;
        logging.IncludeFormattedMessage = true;
    });
}

builder.Services.AddHttpClient();
builder.Services.AddControllers();

var app = builder.Build();

if (otelEnabled)
{
    app.UseOpenTelemetryPrometheusScrapingEndpoint();
}

app.MapControllers();
app.Run();
