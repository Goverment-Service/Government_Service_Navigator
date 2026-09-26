using AgenticAi.Agents.IntakePlanningAgent;
using Backend.Data;
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
using Stripe;
using Government_Service_Navigator.AgenticAi.Tools.CheckDuplicateApplication;
using Government_Service_Navigator.AgenticAi.Agents.ValidationSafety;
using Government_Service_Navigator.AgenticAi.Config;
using Government_Service_Navigator.AgenticAi.Orchestration;
using Government_Service_Navigator.AgenticAi.Tools.CheckDuplicateApplication;
using Government_Service_Navigator.AgenticAi.Tools.ValidateSchema;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Chunking;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Retrieval;
using Government_Service_Navigator.AgenticAi.Orchestration;
using Government_Service_Navigator.AgenticAi.Tools.CheckEligibilityRules;
using Government_Service_Navigator.AgenticAi.Tools.GetDocumentRequirements;
using Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent;
using Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.Retrieval;
using Government_Service_Navigator.AgenticAi.Tools.CalculateFee;
using Government_Service_Navigator.AgenticAi.Tools.FindAppointmentSlot;
using Government_Service_Navigator.AgenticAi.Tools.PrefillApplication;




// Load environment variables from .env file
Env.Load();
StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");

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

// 1.5 Register the Vector Database for the RAG Agent
var vectorConnectionString = builder.Configuration.GetConnectionString("VectorDb");
builder.Services.AddDbContext<VectorDbContext>(options =>
    options.UseNpgsql(vectorConnectionString, o => o.UseVector()));

// Register the Main Application Database
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
builder.Services.AddScoped<IDuplicateApplicationRepository, DuplicateApplicationRepository>();
builder.Services.AddScoped<IVerificationTaskEnqueuer, VerificationTaskEnqueuerService>();

builder.Services.AddScoped<IRefundService, Government_Service_Navigator.Backend.Services.RefundService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IInstallmentPlanService, InstallmentPlanService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<IAnomalyDetectionService, AnomalyDetectionService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IVectorRetriever, VectorRetrieverService>();
builder.Services.AddScoped<IEligibilityVectorRetriever, EligibilityVectorRetrieverService>();
builder.Services.AddScoped<IDocumentChunker, DocumentChunker>();
builder.Services.AddScoped<IEligibilityDocumentAgent, EligibilityDocumentAgent>();
builder.Services.AddScoped<IAgent2WorkflowOrchestrator, Agent2WorkflowOrchestrator>();
builder.Services.AddScoped<ICheckEligibilityRulesTool, CheckEligibilityRulesTool>();
builder.Services.AddScoped<IGetDocumentRequirementsTool, GetDocumentRequirementsTool>();
builder.Services.AddScoped<IDocumentRequirementRepository, DocumentRequirementRepository>();
builder.Services.AddScoped<IIntakePlanningAgent, IntakePlanningAgent>();
builder.Services.AddScoped<IFeeScheduleRepository, FeeScheduleRepository>();
builder.Services.AddScoped<IApplicationTemplateRepository, ApplicationTemplateRepository>();
builder.Services.AddScoped<ICalculateFeeTool, CalculateFeeTool>();
builder.Services.AddScoped<IFindAppointmentSlotTool, FindAppointmentSlotTool>();
builder.Services.AddScoped<IPrefillApplicationTool, PrefillApplicationTool>();
builder.Services.AddScoped<IActionVectorRetriever, ActionVectorRetrieverService>();
builder.Services.AddScoped<IActionToolAgent, ActionToolAgent>();
builder.Services.AddScoped<IAgent3WorkflowOrchestrator, Agent3WorkflowOrchestrator>();
// Agent 4: Validation & Safety Agent and Orchestrator
builder.Services.AddScoped<ISchemaValidatorTool, SchemaValidatorTool>();
builder.Services.AddScoped<IDuplicateCheckTool, DuplicateCheckTool>();
builder.Services.AddScoped<IValidationSafetyAgent, ValidationSafetyAgent>();
builder.Services.AddScoped<IValidationOrchestrator, ValidationOrchestrator>();
builder.Services.AddSingleton(new ValidationSafetyConfig
{
    BlockDuplicateSubmissions = true,
    MinimumLegalAge = 16,
    EnableAdversarialDefense = true
});

builder.Services.AddScoped<IApplicationDraftingService, ApplicationDraftingService>();
builder.Services.AddSingleton<IEmbeddingService, LocalEmbeddingService>();
builder.Services.AddHostedService<InstallmentMonitorService>();




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
        context.Database.Migrate(); 
        Console.WriteLine("Database migrations applied successfully.");

        // Migrations are gitignored, so the Agent 3 draft, uploaded document, installment, receipt and notification tables are ensured with idempotent SQL
        context.Database.ExecuteSqlRaw(@"
CREATE TABLE IF NOT EXISTS ""AgentDrafts"" (
    ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ""ApplicationId"" integer NOT NULL,
    ""DraftJson"" text NOT NULL,
    ""CreatedAt"" timestamp with time zone NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS ""IX_AgentDrafts_ApplicationId"" ON ""AgentDrafts"" (""ApplicationId"");
CREATE TABLE IF NOT EXISTS ""SubmissionDocuments"" (
    ""Id"" uuid PRIMARY KEY,
    ""ApplicationId"" integer NULL,
    ""FieldLabel"" text NOT NULL,
    ""FileName"" text NOT NULL,
    ""ContentType"" text NOT NULL,
    ""SizeBytes"" bigint NOT NULL,
    ""Content"" bytea NOT NULL,
    ""UploaderNic"" text NOT NULL,
    ""UploadedAt"" timestamp with time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS ""IX_SubmissionDocuments_ApplicationId"" ON ""SubmissionDocuments"" (""ApplicationId"");
CREATE TABLE IF NOT EXISTS ""InstallmentPlans"" (
    ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ""PaymentId"" integer NOT NULL,
    ""NumberOfInstallments"" integer NOT NULL,
    ""TotalAmount"" numeric NOT NULL,
    ""Status"" text NOT NULL,
    ""CreatedDate"" timestamp with time zone NOT NULL,
    CONSTRAINT ""FK_InstallmentPlans_Payments_PaymentId""
        FOREIGN KEY (""PaymentId"") REFERENCES ""Payments"" (""Id"") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ""IX_InstallmentPlans_PaymentId"" ON ""InstallmentPlans"" (""PaymentId"");
CREATE TABLE IF NOT EXISTS ""Installments"" (
    ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ""InstallmentPlanId"" integer NOT NULL,
    ""InstallmentNumber"" integer NOT NULL,
    ""Amount"" numeric NOT NULL,
    ""DueDate"" timestamp with time zone NOT NULL,
    ""Status"" text NOT NULL,
    ""PaidDate"" timestamp with time zone NULL,
    CONSTRAINT ""FK_Installments_InstallmentPlans_InstallmentPlanId""
        FOREIGN KEY (""InstallmentPlanId"") REFERENCES ""InstallmentPlans"" (""Id"") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ""IX_Installments_InstallmentPlanId"" ON ""Installments"" (""InstallmentPlanId"");
ALTER TABLE ""Installments"" ADD COLUMN IF NOT EXISTS ""PaymentMethod"" text NULL;
ALTER TABLE ""Installments"" ADD COLUMN IF NOT EXISTS ""StripeSessionId"" text NULL;
ALTER TABLE ""Installments"" ADD COLUMN IF NOT EXISTS ""ReceiptId"" uuid NULL;
CREATE TABLE IF NOT EXISTS ""PaymentReceipts"" (
    ""Id"" uuid PRIMARY KEY,
    ""InstallmentId"" integer NOT NULL,
    ""FileName"" text NOT NULL,
    ""ContentType"" text NOT NULL,
    ""SizeBytes"" bigint NOT NULL,
    ""Content"" bytea NOT NULL,
    ""UploadedAt"" timestamp with time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS ""IX_PaymentReceipts_InstallmentId"" ON ""PaymentReceipts"" (""InstallmentId"");
ALTER TABLE ""Installments"" ADD COLUMN IF NOT EXISTS ""ReminderSentAt"" timestamp with time zone NULL;
CREATE TABLE IF NOT EXISTS ""CitizenNotifications"" (
    ""Id"" integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ""CitizenNic"" text NOT NULL,
    ""UserEmail"" text NOT NULL,
    ""Type"" text NOT NULL,
    ""Title"" text NOT NULL,
    ""Message"" text NOT NULL,
    ""ApplicationId"" integer NULL,
    ""InstallmentPlanId"" integer NULL,
    ""CreatedAt"" timestamp with time zone NOT NULL,
    ""ReadAt"" timestamp with time zone NULL
);
CREATE INDEX IF NOT EXISTS ""IX_CitizenNotifications_CitizenNic"" ON ""CitizenNotifications"" (""CitizenNic"");");

        // Seed mock VerificationTasks if empty so the UI has something to show!
        if (!context.VerificationTasks.Any())
        {
            context.VerificationTasks.AddRange(
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask { ApplicationId = 9088, Status = "Pending", CreatedDate = DateTime.UtcNow.AddHours(-1) },
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask { ApplicationId = 9102, Status = "Pending", CreatedDate = DateTime.UtcNow.AddDays(-3) },
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask { ApplicationId = 8895, Status = "Approved", CreatedDate = DateTime.UtcNow.AddDays(-5) },
                new Government_Service_Navigator.Backend.Models.Entities.VerificationTask { ApplicationId = 8850, Status = "Rejected", CreatedDate = DateTime.UtcNow.AddDays(-6) }
            );
            context.SaveChanges();
            Console.WriteLine("Seeded mock VerificationTasks into the database.");
        }

        // Seed mock ServiceProcedures if empty so Services tab is populated!
        if (!context.ServiceProcedures.Any())
        {
            context.ServiceProcedures.AddRange(
                new Government_Service_Navigator.Backend.Models.Entities.ServiceProcedure
                {
                    ServiceId = "GSN-SRV-001",
                    Name = "Passport Renewal & Application",
                    Category = "Identity",
                    Status = "Active",
                    FeeSchedules = new List<Government_Service_Navigator.Backend.Models.Entities.FeeSchedule>
                    {
                        new() { FeeType = "Standard Processing", Amount = 10000 }
                    }
                },
                new Government_Service_Navigator.Backend.Models.Entities.ServiceProcedure
                {
                    ServiceId = "GSN-SRV-002",
                    Name = "Small Business Registration",
                    Category = "Commerce",
                    Status = "Active",
                    FeeSchedules = new List<Government_Service_Navigator.Backend.Models.Entities.FeeSchedule>
                    {
                        new() { FeeType = "Registration Fee", Amount = 5500 }
                    }
                },
                new Government_Service_Navigator.Backend.Models.Entities.ServiceProcedure
                {
                    ServiceId = "GSN-SRV-003",
                    Name = "Driving License Renewal",
                    Category = "Transport",
                    Status = "Active",
                    FeeSchedules = new List<Government_Service_Navigator.Backend.Models.Entities.FeeSchedule>
                    {
                        new() { FeeType = "Renewal Fee", Amount = 3500 }
                    }
                }
            );
            context.SaveChanges();
            Console.WriteLine("Seeded mock ServiceProcedures into the database.");
        }

    }
    catch (Exception ex)
    {
        Console.WriteLine($"An error occurred while migrating the database: {ex.Message}");
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
