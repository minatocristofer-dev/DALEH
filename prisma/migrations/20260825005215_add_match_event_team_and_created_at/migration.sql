-- AlterTable
ALTER TABLE "match_events" ADD COLUMN     "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "team_id" TEXT;

-- AddForeignKey
ALTER TABLE "match_events" ADD CONSTRAINT "match_events_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE SET NULL ON UPDATE CASCADE;
