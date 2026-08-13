using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using ServiceB.Data;

namespace ServiceB.Controllers;

[ApiController]
[Route("[controller]")]
public class ProcessController : ControllerBase
{
    private static readonly ActivitySource ActivitySource = new("ServiceB");
    private readonly AppDbContext _db;
    private readonly ILogger<ProcessController> _logger;

    public ProcessController(AppDbContext db, ILogger<ProcessController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpGet("/process")]
    public async Task<IActionResult> Process([FromQuery] string? input)
    {
        using var span = ActivitySource.StartActivity("process-request");
        span?.SetTag("input.value", input ?? "default");

        _logger.LogInformation("service-b procesando input={Input}", input);

        string result;
        using (var businessSpan = ActivitySource.StartActivity("business-logic"))
        {
            await Task.Delay(Random.Shared.Next(10, 50));
            result = $"processed:{input?.ToUpper() ?? "DEFAULT"}";
            businessSpan?.SetTag("result.value", result);
        }

        using (var dbSpan = ActivitySource.StartActivity("save-to-database"))
        {
            var log = new RequestLog
            {
                Input = input ?? "default",
                Result = result,
                ProcessedAt = DateTime.UtcNow,
                TraceId = Activity.Current?.TraceId.ToString() ?? string.Empty
            };

            _db.RequestLogs.Add(log);
            await _db.SaveChangesAsync();
            dbSpan?.SetTag("db.records.saved", 1);
        }

        _logger.LogInformation("service-b completó procesamiento result={Result}", result);

        return Ok(new
        {
            service = "service-b",
            input,
            result,
            traceId = Activity.Current?.TraceId.ToString()
        });
    }

    [HttpGet("/health")]
    public IActionResult Health() => Ok(new { status = "healthy", service = "service-b" });
}
