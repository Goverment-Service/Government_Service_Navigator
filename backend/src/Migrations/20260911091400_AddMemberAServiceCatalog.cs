using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Government_Service_Navigator.Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddMemberAServiceCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // migrationBuilder.DropColumn(
            //     name: "SubTitle",
            //     table: "RejectionReasons");

            // migrationBuilder.AddColumn<string>(
            //     name: "Description",
            //     table: "RejectionReasons",
            //     type: "text",
            //     nullable: false,
            //     defaultValue: "");

            migrationBuilder.CreateTable(
                name: "ServiceProcedures",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceId = table.Column<string>(type: "text", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceProcedures", x => x.Id);
                });

            // migrationBuilder.CreateTable(
            //     name: "Templates",
            //     columns: table => new
            //     {
            //         Id = table.Column<Guid>(type: "uuid", nullable: false),
            //         FormName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
            //         SubTitle = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
            //         LawText = table.Column<string>(type: "text", nullable: true),
            //         Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
            //         CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            //     },
            //     constraints: table =>
            //     {
            //         table.PrimaryKey("PK_Templates", x => x.Id);
            //     });

            migrationBuilder.CreateTable(
                name: "DocumentRequirements",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceProcedureId = table.Column<int>(type: "integer", nullable: false),
                    DocumentName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    IsMandatory = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DocumentRequirements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DocumentRequirements_ServiceProcedures_ServiceProcedureId",
                        column: x => x.ServiceProcedureId,
                        principalTable: "ServiceProcedures",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EligibilityRules",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceProcedureId = table.Column<int>(type: "integer", nullable: false),
                    Field = table.Column<string>(type: "text", nullable: false),
                    Operator = table.Column<string>(type: "text", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: false),
                    IsStrict = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EligibilityRules", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EligibilityRules_ServiceProcedures_ServiceProcedureId",
                        column: x => x.ServiceProcedureId,
                        principalTable: "ServiceProcedures",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FeeSchedules",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceProcedureId = table.Column<int>(type: "integer", nullable: false),
                    FeeType = table.Column<string>(type: "text", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    EffectiveDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FeeSchedules", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FeeSchedules_ServiceProcedures_ServiceProcedureId",
                        column: x => x.ServiceProcedureId,
                        principalTable: "ServiceProcedures",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // migrationBuilder.CreateTable(
            //     name: "FormFields",
            //     columns: table => new
            //     {
            //         Id = table.Column<Guid>(type: "uuid", nullable: false),
            //         TemplateId = table.Column<Guid>(type: "uuid", nullable: false),
            //         Label = table.Column<string>(type: "text", nullable: false),
            //         Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
            //         Options = table.Column<string>(type: "text", nullable: true),
            //         IsRequired = table.Column<bool>(type: "boolean", nullable: false),
            //         OrderIndex = table.Column<int>(type: "integer", nullable: false)
            //     },
            //     constraints: table =>
            //     {
            //         table.PrimaryKey("PK_FormFields", x => x.Id);
            //         table.ForeignKey(
            //             name: "FK_FormFields_Templates_TemplateId",
            //             column: x => x.TemplateId,
            //             principalTable: "Templates",
            //             principalColumn: "Id",
            //             onDelete: ReferentialAction.Cascade);
            //     });

            migrationBuilder.CreateIndex(
                name: "IX_DocumentRequirements_ServiceProcedureId",
                table: "DocumentRequirements",
                column: "ServiceProcedureId");

            migrationBuilder.CreateIndex(
                name: "IX_EligibilityRules_ServiceProcedureId",
                table: "EligibilityRules",
                column: "ServiceProcedureId");

            migrationBuilder.CreateIndex(
                name: "IX_FeeSchedules_ServiceProcedureId",
                table: "FeeSchedules",
                column: "ServiceProcedureId");

            // migrationBuilder.CreateIndex(
            //     name: "IX_FormFields_TemplateId",
            //     table: "FormFields",
            //     column: "TemplateId");

            migrationBuilder.CreateIndex(
                name: "IX_ServiceProcedures_ServiceId",
                table: "ServiceProcedures",
                column: "ServiceId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DocumentRequirements");

            migrationBuilder.DropTable(
                name: "EligibilityRules");

            migrationBuilder.DropTable(
                name: "FeeSchedules");

            migrationBuilder.DropTable(
                name: "FormFields");

            migrationBuilder.DropTable(
                name: "ServiceProcedures");

            migrationBuilder.DropTable(
                name: "Templates");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "RejectionReasons");

            migrationBuilder.AddColumn<string>(
                name: "SubTitle",
                table: "RejectionReasons",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }
    }
}
