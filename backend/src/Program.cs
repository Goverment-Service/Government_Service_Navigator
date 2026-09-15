using System.IdentityModel.Tokens.Jwt;
using System.Text;
using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Services;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.OpenApi.Models;
using Npgsql;

// Load environment variables from .env file
Env.Load();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// 1. Setup PostgreSQL
// If DATABASE_URL is set (e.g. a Neon connection string), prefer it and require SSL.
// Otherwise fall back to the local DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD settings.
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
string connectionString;

if (!string.IsNullOrEmpty(databaseUrl))
{
    var uri = new Uri(databaseUrl);
    var userInfo = uri.UserInfo.Split(':', 2);

    var npgsqlBuilder = new NpgsqlConnectionStringBuilder
    {
        Host = uri.Host,
        Port = uri.Port > 0 ? uri.Port : 5432,
        Database = uri.AbsolutePath.TrimStart('/'),
        Username = Uri.UnescapeDataString(userInfo[0]),
        Password = userInfo.Length > 1 ? Uri.UnescapeDataString(userInfo[1]) : string.Empty,
        SslMode = SslMode.Require
    };

    connectionString = npgsqlBuilder.ConnectionString;
}
else
{
    var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
    var dbPort = Environment.GetEnvironmentVariable("DB_PORT");
    var dbName = Environment.GetEnvironmentVariable("DB_NAME");
    var dbUser = Environment.GetEnvironmentVariable("DB_USER");
    var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");

    if (string.IsNullOrEmpty(dbHost) || string.IsNullOrEmpty(dbPort) || string.IsNullOrEmpty(dbName) || string.IsNullOrEmpty(dbUser) || string.IsNullOrEmpty(dbPassword))
    {
        throw new InvalidOperationException("One or more required database environment variables are missing.");
    }

    connectionString = $"Host={dbHost};Port={dbPort};Database={dbName};Username={dbUser};Password={dbPassword}";
}

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. Setup Dependency Injection
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
});
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IVerificationService, VerificationService>();
builder.Services.AddScoped<ITemplateService, TemplateService>();
builder.Services.AddScoped<IServiceCatalogService, ServiceCatalogService>();


// 3. Setup CORS (Crucial for Flutter/Mobile/Web app connectivity)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAllOrigins",
        policy => policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod());
});

// 4. Setup JWT Authentication
var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY");
var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");

if (!string.IsNullOrEmpty(jwtKey))
{
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

        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var jti = context.Principal?.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
                if (string.IsNullOrEmpty(jti))
                {
                    return;
                }

                var dbContext = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var isRevoked = await dbContext.RevokedTokens.AnyAsync(t => t.Jti == jti);
                if (isRevoked)
                {
                    context.Fail("Token has been revoked.");
                }
            }
        };
    });
}

// 5. Setup Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Government Service Navigator API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});


var app = builder.Build();

// 6. Automatically Apply Migrations at Startup (Fixes Read/Write errors instantly)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<AppDbContext>();
        
        // Ensure RevokedTokens table exists before Migrations run in case EF history is corrupt
        context.Database.ExecuteSqlRaw(@"
            CREATE TABLE IF NOT EXISTS ""RevokedTokens"" (
                ""Id"" integer GENERATED BY DEFAULT AS IDENTITY,
                ""Jti"" text NOT NULL,
                ""ExpiresAt"" timestamp with time zone NOT NULL,
                ""RevokedAt"" timestamp with time zone NOT NULL,
                CONSTRAINT ""PK_RevokedTokens"" PRIMARY KEY (""Id"")
            );
            CREATE UNIQUE INDEX IF NOT EXISTS ""IX_RevokedTokens_Jti"" ON ""RevokedTokens"" (""Jti"");
        ");

        // Ensure ServiceProcedureId column exists on Templates in case EF history is corrupt
        context.Database.ExecuteSqlRaw(@"
            ALTER TABLE ""Templates"" ADD COLUMN IF NOT EXISTS ""ServiceProcedureId"" integer;
        ");

        context.Database.Migrate(); 
        
        Console.WriteLine("Database migrations applied successfully.");

        // SEED DEFAULT USERS FOR DEVELOPMENT (Force update passwords to be safe)
        var admin = context.Admins.FirstOrDefault(a => a.Email == "admin@gov.lk");
        if (admin == null)
        {
            admin = new Government_Service_Navigator.Backend.Models.Entities.Admin
            {
                Email = "admin@gov.lk",
                Role = "System Admin"
            };
            context.Admins.Add(admin);
        }
        admin.PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123");
        
        var officer = context.Officers.FirstOrDefault(o => o.Email == "officer@gov.lk");
        if (officer == null)
        {
            officer = new Government_Service_Navigator.Backend.Models.Entities.Officer
            {
                Name = "Test Officer",
                Email = "officer@gov.lk",
                Department = "Department of Motor Traffic",
                Role = "Verifying Officer"
            };
            context.Officers.Add(officer);
        }
        officer.PasswordHash = BCrypt.Net.BCrypt.HashPassword("officer123");
        
        // ADD SAMPLE TASKS FOR BULK VERIFICATION / WORKSPACE TESTING
        if (!context.VerificationTasks.Any())
        {
            context.VerificationTasks.AddRange(
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask
                {
                    ApplicationId = 9102,
                    Status = "Pending",
                    CreatedDate = DateTime.UtcNow.AddDays(-3)
                },
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask
                {
                    ApplicationId = 9088,
                    Status = "Pending",
                    CreatedDate = DateTime.UtcNow.AddDays(-1)
                },
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask
                {
                    ApplicationId = 8799,
                    Status = "Pending",
                    CreatedDate = DateTime.UtcNow.AddDays(-5)
                },
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask
                {
                    ApplicationId = 8745,
                    Status = "Pending",
                    CreatedDate = DateTime.UtcNow.AddDays(-14)
                }
            );
        }

        // ADD SAMPLE AUDIT LOGS FOR ADMIN DASHBOARD TESTING
        if (!context.AuditLogs.Any())
        {
            context.AuditLogs.AddRange(
                new Government_Service_Navigator.Backend.Models.Entities.AuditLog
                {
                    ApplicationId = 1001,
                    Action = "System Backup Complete",
                    PerformedBy = "System",
                    Timestamp = DateTime.UtcNow.AddHours(-12),
                    OldValues = "",
                    NewValues = ""
                },
                new Government_Service_Navigator.Backend.Models.Entities.AuditLog
                {
                    ApplicationId = 1002,
                    Action = "Failed Login Attempt",
                    PerformedBy = "Unknown IP",
                    Timestamp = DateTime.UtcNow.AddHours(-6),
                    OldValues = "",
                    NewValues = ""
                },
                new Government_Service_Navigator.Backend.Models.Entities.AuditLog
                {
                    ApplicationId = 1003,
                    Action = "Officer Account Suspended",
                    PerformedBy = "admin@gov.lk",
                    Timestamp = DateTime.UtcNow.AddHours(-1),
                    OldValues = "",
                    NewValues = ""
                }
            );
        }

        context.SaveChanges();
        Console.WriteLine("Force-seeded default passwords and sample data!");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"An error occurred while migrating/seeding the database: {ex.Message}");
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();

// 7. Enable CORS globally
app.UseCors("AllowAllOrigins");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run("http://0.0.0.0:5119");