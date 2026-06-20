export declare const HATEOAS_ITEM_KEY = "hateoas:item";
export declare const HATEOAS_LIST_KEY = "hateoas:list";
export interface HateoasLink {
    href: string;
    method: string;
}
export interface HateoasItemConfig<T = Record<string, unknown>> {
    basePath: string;
    itemLinks: (item: T) => Record<string, HateoasLink>;
}
export interface HateoasListConfig<T = Record<string, unknown>> {
    basePath: string;
    itemLinks: (item: T) => Record<string, HateoasLink>;
}
export interface HateoasResponse<T> {
    data: T;
    _links: Record<string, HateoasLink>;
}
