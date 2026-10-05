-- AlterTable
ALTER TABLE "teams" ADD COLUMN "pix_key" TEXT,
ADD COLUMN "pix_nome" TEXT;

-- CreateTable
CREATE TABLE "team_charges" (
    "id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "valor" DOUBLE PRECISION NOT NULL,
    "criado_por" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "team_charges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_charge_items" (
    "id" TEXT NOT NULL,
    "charge_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "paid_at" TIMESTAMP(3),
    "marked_by" TEXT,

    CONSTRAINT "team_charge_items_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "team_charge_items_charge_id_user_id_key" ON "team_charge_items"("charge_id", "user_id");

-- AddForeignKey
ALTER TABLE "team_charges" ADD CONSTRAINT "team_charges_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_charges" ADD CONSTRAINT "team_charges_criado_por_fkey" FOREIGN KEY ("criado_por") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_charge_items" ADD CONSTRAINT "team_charge_items_charge_id_fkey" FOREIGN KEY ("charge_id") REFERENCES "team_charges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_charge_items" ADD CONSTRAINT "team_charge_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
