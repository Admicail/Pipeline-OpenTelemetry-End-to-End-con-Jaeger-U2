using Microsoft.EntityFrameworkCore;

namespace ServiceB.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<RequestLog> RequestLogs { get; set; }
}

public class RequestLog
{
    public int Id { get; set; }
    public string Input { get; set; } = string.Empty;
    public string Result { get; set; } = string.Empty;
    public DateTime ProcessedAt { get; set; }
    public string TraceId { get; set; } = string.Empty;
}
