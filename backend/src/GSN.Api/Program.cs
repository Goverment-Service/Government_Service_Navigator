using System.Text;
using DotNetEnv;
using GSN.Application.Auth;
using GSN.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

// ---- Load .env into environment variables ----
Env.Load();

var builder = WebApplication.CreateBuilder(args);

// ---- Database (PostgreSQL via Npgsql) ----
var connectionString =
    $"Host={Environment.GetEnvironmentVariable("DB_HOST")};" +
    $"Port={Environment.GetEnvironmentVariable("DB_PORT")};" +
    $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
    $"Username={Environment.GetEnvironmentVariable("DB_USER")};" +
    $"Password={Environment.GetEnvironmentVariable("DB_PASSWORD")}";

builder.Services.AddDbContext<GsnDbContext>(options =>
    options.UseNpgsql(connectionString));

// ---- Application services ----
builder.Services.AddScoped<AuthService>();

// ---- JWT Authentication ----
var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")!;
var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

builder.Services.AddAuthorization();

// ---- CORS: allow the React dashboard + Flutter (mobile doesn't need CORS,
// but keeping the policy open for local web testing) ----
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClients", policy =>
    {
        policy.WithOrigins("http://localhost:5173", "http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// ---- Controllers + Swagger ----
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowClients");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Simple health check for your deployment report
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.Run();