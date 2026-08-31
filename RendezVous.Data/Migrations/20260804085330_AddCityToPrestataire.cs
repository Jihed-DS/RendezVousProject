using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RendezVous.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCityToPrestataire : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "Prestataires",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "City",
                table: "Prestataires");
        }
    }
}
