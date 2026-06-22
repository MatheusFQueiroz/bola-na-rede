import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { MatchmakingService } from '../../application/services/matchmaking.service';
import { CreateMatchRequestDto } from '../../application/dto/create-match-request.dto';
import { MatchRequestDto } from '../../application/dto/match-request.dto';

@ApiTags('Match Requests')
@UseGuards(JwtAuthGuard)
@Controller('match-requests')
export class MatchRequestsController {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  @Get()
  @ApiOperation({ summary: 'Get current user active match request' })
  async getActiveRequest(@Request() req: any): Promise<MatchRequestDto | null> {
    const userId: string = req.user.id;
    const request = await this.matchmakingService.getActiveRequest(userId);
    return request ? MatchRequestDto.from(request) : null;
  }

  @Post()
  @ApiOperation({ summary: 'Create a new matchmaking request' })
  async createRequest(
    @Request() req: any,
    @Body() dto: CreateMatchRequestDto,
  ): Promise<MatchRequestDto> {
    const userId: string = req.user.id;
    const displayName: string = req.user.name ?? '';
    const request = await this.matchmakingService.createRequest(userId, displayName, dto.sport);
    return MatchRequestDto.from(request);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get match request status' })
  async getRequest(@Request() req: any, @Param('id') id: string): Promise<MatchRequestDto> {
    const userId: string = req.user.id;
    const request = await this.matchmakingService.getRequest(userId, id);
    return MatchRequestDto.from(request);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Cancel a match request' })
  async cancelRequest(@Request() req: any, @Param('id') id: string): Promise<void> {
    const userId: string = req.user.id;
    await this.matchmakingService.cancelRequest(userId, id);
  }
}
