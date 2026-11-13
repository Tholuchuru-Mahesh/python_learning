import { IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateStaffDto {
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  permissions?: string[];

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

