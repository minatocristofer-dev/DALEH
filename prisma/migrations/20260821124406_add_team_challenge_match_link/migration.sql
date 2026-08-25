-- AlterTable
ALTER TABLE "team_challenges" ADD COLUMN "match_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "team_challenges_match_id_key" ON "team_challenges"("match_id");

-- AddForeignKey
ALTER TABLE "team_challenges" ADD CONSTRAINT "team_challenges_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "matches"("id") ON DELETE SET NULL ON UPDATE CASCADE;
