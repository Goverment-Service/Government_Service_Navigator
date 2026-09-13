using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Government_Service_Navigator.Backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateModels : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // NOTE: Templates and FormFields were already created by the AddTemplates
            // (20260907122435) and AddTemplateStatus (20260908170255) migrations.
            // This migration was regenerated against a stale model snapshot and
            // originally duplicated those CreateTable calls, which fails with
            // "relation already exists" against any database that already applied
            // AddTemplates/AddTemplateStatus. Left as a no-op to match the DB state
            // that AddMemberAServiceCatalog (20260911091400) already assumes.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}

