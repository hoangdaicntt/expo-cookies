// src/index.ts
import {requireNativeModule} from 'expo-modules-core';
import {Cookie, Cookies} from './ExpoCookies.types';

const ExpoCookiesModule = requireNativeModule('ExpoCookies');

export default class CookieManager {
    /**
     * Set a cookie for the given URL
     * @param url - The URL to set the cookie for
     * @param cookie - The cookie object to set
     * @param useWebKit - Whether to use WebKit cookie store (iOS only)
     * @returns Promise that resolves to true if successful
     */
    static async set(url: string, cookie: Cookie, useWebKit: boolean = false): Promise<boolean> {
        return await ExpoCookiesModule.set(url, cookie, useWebKit);
    }

    /**
     * Set cookies from a response header string
     * @param url - The URL to set the cookies for
     * @param cookieHeader - The Set-Cookie header string
     * @returns Promise that resolves to true if successful
     */
    static async setFromResponse(url: string, cookieHeader: string): Promise<boolean> {
        return await ExpoCookiesModule.setFromResponse(url, cookieHeader);
    }

    /**
     * Get cookies for a specific URL
     * @param url - The URL to get cookies for
     * @param useWebKit - Whether to use WebKit cookie store (iOS only)
     * @returns Promise that resolves to cookies object
     */
    static async get(url: string, useWebKit: boolean = false): Promise<Cookies> {
        return await ExpoCookiesModule.get(url, useWebKit);
    }

    /**
     * Get all cookies (iOS only)
     * @param useWebKit - Whether to use WebKit cookie store (iOS only)
     * @returns Promise that resolves to all cookies
     */
    static async getAll(useWebKit: boolean = false): Promise<Cookies> {
        return await ExpoCookiesModule.getAll(useWebKit);
    }

    /**
     * Clear all cookies
     * @param useWebKit - Whether to use WebKit cookie store (iOS only)
     * @returns Promise that resolves to true if successful
     */
    static async clearAll(useWebKit: boolean = false): Promise<boolean> {
        return await ExpoCookiesModule.clearAll(useWebKit);
    }

    /**
     * Clear a specific cookie by name (iOS only)
     * @param url - The URL to clear the cookie for
     * @param name - The name of the cookie to clear
     * @param useWebKit - Whether to use WebKit cookie store (iOS only)
     * @returns Promise that resolves to true if successful
     */
    static async clearByName(url: string, name: string, useWebKit: boolean = false): Promise<boolean> {
        return await ExpoCookiesModule.clearByName(url, name, useWebKit);
    }

    /**
     * Flush cookies to persistent storage (Android only)
     * @returns Promise that resolves to true if successful
     */
    static async flush(): Promise<boolean> {
        return await ExpoCookiesModule.flush();
    }

    /**
     * Remove session cookies (Android only)
     * @returns Promise that resolves to true if session cookies were removed
     */
    static async removeSessionCookies(): Promise<boolean> {
        return await ExpoCookiesModule.removeSessionCookies();
    }
}

export * from './ExpoCookies.types';
export {CookieManager};
