using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RendezVous.Data.Migrations
{
    /// <inheritdoc />
    public partial class SyncModelChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires");

            migrationBuilder.AlterColumn<decimal>(
                name: "RatingAvg",
                table: "Prestataires",
                type: "numeric",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric(3,2)");

            migrationBuilder.CreateIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires",
                column: "UserId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires");

            migrationBuilder.AlterColumn<decimal>(
                name: "RatingAvg",
                table: "Prestataires",
                type: "numeric(3,2)",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric");

            migrationBuilder.CreateIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires",
                column: "UserId");
        }
    }
}
