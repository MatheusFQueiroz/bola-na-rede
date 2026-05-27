import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { HATEOAS_ITEM_KEY, HATEOAS_LIST_KEY } from './hateoas.types';

@Injectable()
export class HateoasInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const isItem = this.reflector.get<boolean>(HATEOAS_ITEM_KEY, context.getHandler());
    const isList = this.reflector.get<boolean>(HATEOAS_LIST_KEY, context.getHandler());

    if (!isItem && !isList) return next.handle();

    const request = context
      .switchToHttp()
      .getRequest<{ protocol: string; get: (h: string) => string; url: string }>();

    const protocol = request.protocol || 'http';
    const host = request.get('host') || 'localhost';
    const selfHref = `${protocol}://${host}${request.url}`;

    return next.handle().pipe(
      map((data) => ({ data, _links: { self: { href: selfHref } } })),
    );
  }
}
