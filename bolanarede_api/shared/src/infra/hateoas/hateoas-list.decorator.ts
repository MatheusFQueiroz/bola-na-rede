import { SetMetadata } from '@nestjs/common';
import { HATEOAS_LIST_KEY } from './hateoas.types';

export const HateoasList = (_dto: unknown) => SetMetadata(HATEOAS_LIST_KEY, true);
