export const HATEOAS_ITEM_KEY = 'hateoas:item';
export const HATEOAS_LIST_KEY = 'hateoas:list';

export interface HateoasLink {
  href: string;
}

export interface HateoasResponse<T> {
  data: T;
  _links: { self: HateoasLink };
}
