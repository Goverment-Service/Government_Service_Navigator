using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Npgsql;

namespace Government_Service_Navigator.Backend.Data.Context
{
    // Used only by 'dotnet ef' at design-time (migrations), independent of the
    // normal app startup pipeline in Program.cs.
    public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            Env.Load();

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

                connectionString = $"Host={dbHost};Port={dbPort};Database={dbName};Username={dbUser};Password={dbPassword}";
            }

            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql(connectionString);

            return new AppDbContext(optionsBuilder.Options);
        }
    }
}