import { SetMetadata } from '@nestjs/common';
import { HATEOAS_ITEM_KEY, HateoasItemConfig } from './hateoas.types';

export const HateoasItem = <T>(config: HateoasItemConfig<T>) =>
  SetMetadata(HATEOAS_ITEM_KEY, config);
