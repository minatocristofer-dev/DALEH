/*
  Warnings:

  - Added the required column `created_by` to the `matches` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "bookings_venue_slot_id_idx";

-- DropIndex
DROP INDEX "call_ups_match_id_idx";

-- DropIndex
DROP INDEX "call_ups_team_id_idx";

-- DropIndex
DROP INDEX "call_ups_user_id_idx";

-- DropIndex
DROP INDEX "challenge_requests_requesting_team_id_idx";

-- DropIndex
DROP INDEX "championship_teams_championship_id_team_id_key";

-- DropIndex
DROP INDEX "championship_teams_team_id_idx";

-- DropIndex
DROP INDEX "match_attendance_user_id_idx";

-- DropIndex
DROP INDEX "match_events_match_id_idx";

-- DropIndex
DROP INDEX "match_events_user_id_idx";

-- DropIndex
DROP INDEX "matches_away_team_id_idx";

-- DropIndex
DROP INDEX "matches_championship_id_idx";

-- DropIndex
DROP INDEX "matches_home_team_id_idx";

-- DropIndex
DROP INDEX "matches_modalidade_id_idx";

-- DropIndex
DROP INDEX "matches_venue_id_idx";

-- DropIndex
DROP INDEX "notifications_user_id_idx";

-- DropIndex
DROP INDEX "payments_user_id_idx";

-- DropIndex
DROP INDEX "player_modalidades_modalidade_id_idx";

-- DropIndex
DROP INDEX "player_stats_modalidade_id_idx";

-- DropIndex
DROP INDEX "reviews_reviewed_id_idx";

-- DropIndex
DROP INDEX "reviews_reviewer_id_idx";

-- DropIndex
DROP INDEX "team_challenges_modalidade_id_idx";

-- DropIndex
DROP INDEX "team_challenges_team_id_idx";

-- DropIndex
DROP INDEX "team_challenges_venue_id_idx";

-- DropIndex
DROP INDEX "team_finances_team_id_idx";

-- DropIndex
DROP INDEX "team_members_user_id_idx";

-- DropIndex
DROP INDEX "teams_owner_id_idx";

-- DropIndex
DROP INDEX "user_roles_role_id_idx";

-- DropIndex
DROP INDEX "user_roles_user_id_idx";

-- DropIndex
DROP INDEX "venue_slots_venue_id_idx";

-- DropIndex
DROP INDEX "venues_owner_id_idx";

-- AlterTable
ALTER TABLE "matches" ADD COLUMN     "created_by" TEXT NOT NULL;

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
