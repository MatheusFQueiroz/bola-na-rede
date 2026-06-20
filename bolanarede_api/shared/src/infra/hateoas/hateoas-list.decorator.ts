import { SetMetadata } from '@nestjs/common';
import { HATEOAS_LIST_KEY, HateoasListConfig } from './hateoas.types';

export const HateoasList = <T>(config: HateoasListConfig<T>) =>
  SetMetadata(HATEOAS_LIST_KEY, config);
