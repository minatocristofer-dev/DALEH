-- CreateTable
CREATE TABLE "venue_blocked_dates" (
    "id" TEXT NOT NULL,
    "venue_id" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "venue_blocked_dates_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "venue_blocked_dates_venue_id_date_key" ON "venue_blocked_dates"("venue_id", "date");

-- AddForeignKey
ALTER TABLE "venue_blocked_dates" ADD CONSTRAINT "venue_blocked_dates_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "venues"("id") ON DELETE CASCADE ON UPDATE CASCADE;
