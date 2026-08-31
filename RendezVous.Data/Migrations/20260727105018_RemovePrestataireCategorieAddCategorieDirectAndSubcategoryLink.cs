using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RendezVous.Data.Migrations
{
    /// <inheritdoc />
    public partial class RemovePrestataireCategorieAddCategorieDirectAndSubcategoryLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PrestataireCategories");

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

            migrationBuilder.AddColumn<Guid>(
                name: "CategorieId",
                table: "Prestataires",
                type: "uuid",
                nullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "Amount",
                table: "Paiements",
                type: "numeric(18,2)",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric(10,2)");

            migrationBuilder.CreateTable(
                name: "PrestataireSubcategories",
                columns: table => new
                {
                    PrestataireId = table.Column<Guid>(type: "uuid", nullable: false),
                    SubcategoryId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PrestataireSubcategories", x => new { x.PrestataireId, x.SubcategoryId });
                    table.ForeignKey(
                        name: "FK_PrestataireSubcategories_Prestataires_PrestataireId",
                        column: x => x.PrestataireId,
                        principalTable: "Prestataires",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PrestataireSubcategories_Subcategories_SubcategoryId",
                        column: x => x.SubcategoryId,
                        principalTable: "Subcategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Prestataires_CategorieId",
                table: "Prestataires",
                column: "CategorieId");

            migrationBuilder.CreateIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_PrestataireSubcategories_SubcategoryId",
                table: "PrestataireSubcategories",
                column: "SubcategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_Prestataires_Categories_CategorieId",
                table: "Prestataires",
                column: "CategorieId",
                principalTable: "Categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Prestataires_Categories_CategorieId",
                table: "Prestataires");

            migrationBuilder.DropTable(
                name: "PrestataireSubcategories");

            migrationBuilder.DropIndex(
                name: "IX_Prestataires_CategorieId",
                table: "Prestataires");

            migrationBuilder.DropIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires");

            migrationBuilder.DropColumn(
                name: "CategorieId",
                table: "Prestataires");

            migrationBuilder.AlterColumn<decimal>(
                name: "RatingAvg",
                table: "Prestataires",
                type: "numeric",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric(3,2)");

            migrationBuilder.AlterColumn<decimal>(
                name: "Amount",
                table: "Paiements",
                type: "numeric(10,2)",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric(18,2)");

            migrationBuilder.CreateTable(
                name: "PrestataireCategories",
                columns: table => new
                {
                    PrestataireId = table.Column<Guid>(type: "uuid", nullable: false),
                    CategorieId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PrestataireCategories", x => new { x.PrestataireId, x.CategorieId });
                    table.ForeignKey(
                        name: "FK_PrestataireCategories_Categories_CategorieId",
                        column: x => x.CategorieId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PrestataireCategories_Prestataires_PrestataireId",
                        column: x => x.PrestataireId,
                        principalTable: "Prestataires",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Prestataires_UserId",
                table: "Prestataires",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PrestataireCategories_CategorieId",
                table: "PrestataireCategories",
                column: "CategorieId");
        }
    }
}
