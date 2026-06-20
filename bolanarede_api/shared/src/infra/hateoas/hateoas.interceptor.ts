import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  HATEOAS_ITEM_KEY,
  HATEOAS_LIST_KEY,
  HateoasItemConfig,
  HateoasListConfig,
} from './hateoas.types';

@Injectable()
export class HateoasInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const itemConfig = this.reflector.get<HateoasItemConfig>(
      HATEOAS_ITEM_KEY,
      context.getHandler(),
    );
    const listConfig = this.reflector.get<HateoasListConfig>(
      HATEOAS_LIST_KEY,
      context.getHandler(),
    );

    if (!itemConfig && !listConfig) return next.handle();

    return next.handle().pipe(
      map((data) => {
        if (itemConfig) {
          return {
            data,
            _links: itemConfig.itemLinks(data as Record<string, unknown>),
          };
        }

        if (listConfig) {
          const items = Array.isArray(data) ? data : [];
          return {
            data: items.map((item) => ({
              ...item,
              _links: listConfig.itemLinks(item as Record<string, unknown>),
            })),
            _links: {
              self: { href: listConfig.basePath, method: 'GET' },
              create: { href: listConfig.basePath, method: 'POST' },
            },
          };
        }

        return data;
      }),
    );
  }
}
