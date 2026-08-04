import { IsString } from 'class-validator';

export class CreateChallengeRequestDto {
  @IsString()
  requestingTeamId: string;
}
