using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Government_Service_Navigator.Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddTemplateServiceProcedureLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ServiceProcedureId",
                table: "Templates",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Templates_ServiceProcedureId",
                table: "Templates",
                column: "ServiceProcedureId");

            migrationBuilder.AddForeignKey(
                name: "FK_Templates_ServiceProcedures_ServiceProcedureId",
                table: "Templates",
                column: "ServiceProcedureId",
                principalTable: "ServiceProcedures",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Templates_ServiceProcedures_ServiceProcedureId",
                table: "Templates");

            migrationBuilder.DropIndex(
                name: "IX_Templates_ServiceProcedureId",
                table: "Templates");

            migrationBuilder.DropColumn(
                name: "ServiceProcedureId",
                table: "Templates");
        }
    }
}
