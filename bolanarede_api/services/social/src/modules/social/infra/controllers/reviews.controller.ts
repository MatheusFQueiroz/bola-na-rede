import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { ReviewService } from '../../application/services/review.service';
import { CreateReviewDto } from '../../application/dto/create-review.dto';
import { ListReviewsDto } from '../../application/dto/list-reviews.dto';
import { ReviewDto } from '../../application/dto/review.dto';

@ApiTags('reviews')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly service: ReviewService) {}

  @Post()
  @Permissions('social:write')
  @HateoasItem<ReviewDto>({
    basePath: '/v1/reviews',
    itemLinks: (r) => ({
      self: { href: `/v1/reviews`, method: 'GET' },
      reviewer: { href: `/v1/scores/players/${r.reviewerUserId}`, method: 'GET' },
      reviewee: { href: `/v1/scores/players/${r.revieweeUserId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Submeter avaliação de jogador após partida' })
  create(
    @Body() dto: CreateReviewDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReviewDto> {
    return this.service.createReview(user.id, user.name, dto);
  }

  @Get()
  @Public()
  @HateoasList<ReviewDto>({
    basePath: '/v1/reviews',
    itemLinks: (r) => ({
      self: { href: `/v1/reviews`, method: 'GET' },
      reviewer: { href: `/v1/scores/players/${r.reviewerUserId}`, method: 'GET' },
      reviewee: { href: `/v1/scores/players/${r.revieweeUserId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar avaliações (filtrável por reviewee, reviewer ou jogo)' })
  list(@Query() query: ListReviewsDto): Promise<ReviewDto[]> {
    return this.service.listReviews(query);
  }
}
