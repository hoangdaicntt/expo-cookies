# expo-cookies

🍪 Cookie Manager for Expo using Expo Modules API

A modern cookie management library for Expo applications, built with the Expo Modules API. This library provides a clean, promise-based interface for managing HTTP cookies across iOS and Android platforms.

## Features

- ✅ **iOS Support** - Full cookie management with WebKit support
- ✅ **Android Support** - Complete cookie functionality
- ✅ **TypeScript** - Full TypeScript support with type definitions
- ✅ **Expo Modules API** - Built with modern Expo Modules API
- ✅ **Promise-based** - Clean async/await API
- ✅ **WebKit Support** - iOS WebKit cookie store integration
- ✅ **Cross-platform** - Works on both iOS and Android

## Installation

```bash
npm install expo-cookies
# or
yarn add expo-cookies
```

### Version Requirements

- **Expo SDK**: 52+
- **React Native**: 0.79+
- **iOS**: 15.1+
- **Android**: API 21+

### Configure for development builds

If you're using development builds, you'll need to rebuild your development client after installing this library.

## Usage

### Basic Usage

```typescript
import CookieManager from 'expo-cookies';

// Set a cookie
await CookieManager.set('https://example.com', {
  name: 'userToken',
  value: 'abc123',
  domain: 'example.com',
  path: '/',
  expires: '2025-12-31T23:59:59.000Z',
  secure: true,
  httpOnly: false
});

// Get cookies for a URL
const cookies = await CookieManager.get('https://example.com');
console.log(cookies);

// Clear all cookies
await CookieManager.clearAll();
```

### Set cookies from response header

```typescript
// Set cookies from a response header
await CookieManager.setFromResponse(
  'https://example.com',
  'sessionId=def456; Path=/; Secure; HttpOnly'
);
```

### iOS WebKit Support

```typescript
const useWebKit = true;

// Set cookie in WebKit store
await CookieManager.set('https://example.com', {
  name: 'webkitCookie',
  value: 'webkit123',
  domain: 'example.com',
  path: '/'
}, useWebKit);

// Get cookies from WebKit store
const webkitCookies = await CookieManager.get('https://example.com', useWebKit);
```

### Android-specific methods

```typescript
// Flush cookies to persistent storage (Android only)
await CookieManager.flush();

// Remove session cookies (Android only)
const removed = await CookieManager.removeSessionCookies();
```

### iOS-specific methods

```typescript
// Get all cookies (iOS only)
const allCookies = await CookieManager.getAll();

// Clear specific cookie by name (iOS only)
await CookieManager.clearByName('https://example.com', 'cookieName');
```

## API Reference

### Cookie Object

```typescript
interface Cookie {
  name: string;
  value: string;
  path?: string;
  domain?: string;
  version?: string;
  expires?: string; // ISO 8601 format
  secure?: boolean;
  httpOnly?: boolean;
}
```

### Methods

#### `set(url: string, cookie: Cookie, useWebKit?: boolean): Promise<boolean>`

Set a cookie for the given URL.

#### `setFromResponse(url: string, cookieHeader: string): Promise<boolean>`

Set cookies from a response header string.

#### `get(url: string, useWebKit?: boolean): Promise<Cookies>`

Get cookies for a specific URL.

#### `getAll(useWebKit?: boolean): Promise<Cookies>` (iOS only)

Get all cookies.

#### `clearAll(useWebKit?: boolean): Promise<boolean>`

Clear all cookies.

#### `clearByName(url: string, name: string, useWebKit?: boolean): Promise<boolean>` (iOS only)

Clear a specific cookie by name.

#### `flush(): Promise<boolean>` (Android only)

Flush cookies to persistent storage.

#### `removeSessionCookies(): Promise<boolean>` (Android only)

Remove session cookies.

## Platform Support

| Platform | Support |
|----------|---------|
| iOS      | ✅ Full support with WebKit |
| Android  | ✅ Full support |
| Web      | ❌ Not supported |

## WebKit Support (iOS)

On iOS, cookies can be stored in two different stores:

1. **NSHTTPCookieStorage** (default) - Shared with other HTTP requests
2. **WKHTTPCookieStore** - Used by WebKit WebViews

You can specify which store to use by passing the `useWebKit` parameter to the relevant methods.

## Development

### Project Structure

```
expo-cookies/
├── src/
│   ├── index.ts                 # Main TypeScript interface
│   └── ExpoCookies.types.ts     # TypeScript types
├── ios/
│   └── ExpoCookiesModule.swift  # iOS implementation
├── android/
│   └── src/main/java/expo/modules/cookies/
│       └── ExpoCookiesModule.kt # Android implementation
├── expo-module.config.json      # Expo module configuration
└── package.json
```

### Building

```bash
npm run build
```

### Testing

```bash
npm run test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details.

## Acknowledgments

This module was inspired by [@react-native-cookies/cookies](https://github.com/react-native-cookies/cookies) and adapted to use the Expo Modules API for better integration with Expo applications.
