import { SetMetadata } from '@nestjs/common';
import { HATEOAS_ITEM_KEY } from './hateoas.types';

export const HateoasItem = (_dto: unknown) => SetMetadata(HATEOAS_ITEM_KEY, true);
