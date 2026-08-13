using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Government_Service_Navigator.Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddOfficerDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Department",
                table: "Officers",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Name",
                table: "Officers",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Officers",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Department",
                table: "Officers");

            migrationBuilder.DropColumn(
                name: "Name",
                table: "Officers");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Officers");
        }
    }
}
