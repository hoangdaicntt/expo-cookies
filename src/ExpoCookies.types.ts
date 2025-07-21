// src/ExpoCookies.types.ts
export interface Cookie {
  name: string;
  value: string;
  path?: string;
  domain?: string;
  version?: string;
  expires?: string;
  secure?: boolean;
  httpOnly?: boolean;
}

export interface Cookies {
  [key: string]: Cookie;
}

export interface ExpoCookiesModule {
  set(url: string, cookie: Cookie, useWebKit?: boolean): Promise<boolean>;
  setFromResponse(url: string, cookieHeader: string): Promise<boolean>;
  get(url: string, useWebKit?: boolean): Promise<Cookies>;
  getAll(useWebKit?: boolean): Promise<Cookies>;
  clearAll(useWebKit?: boolean): Promise<boolean>;
  clearByName(url: string, name: string, useWebKit?: boolean): Promise<boolean>;
  flush(): Promise<boolean>;
  removeSessionCookies(): Promise<boolean>;
}
