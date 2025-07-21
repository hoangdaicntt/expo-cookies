// ios/ExpoCookiesModule.swift
import ExpoModulesCore
import Foundation
import WebKit

public class ExpoCookiesModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoCookies")

    AsyncFunction("set") { (url: String, cookie: [String: Any], useWebKit: Bool) -> Bool in
      return await self.setCookie(url: url, cookie: cookie, useWebKit: useWebKit)
    }

    AsyncFunction("setFromResponse") { (url: String, cookieHeader: String) -> Bool in
      return await self.setFromResponseHeader(url: url, cookieHeader: cookieHeader)
    }

    AsyncFunction("get") { (url: String, useWebKit: Bool) -> [String: [String: Any]] in
      return await self.getCookies(url: url, useWebKit: useWebKit)
    }

    AsyncFunction("getAll") { (useWebKit: Bool) -> [String: [String: Any]] in
      return await self.getAllCookies(useWebKit: useWebKit)
    }

    AsyncFunction("clearAll") { (useWebKit: Bool) -> Bool in
      return await self.clearAllCookies(useWebKit: useWebKit)
    }

    AsyncFunction("clearByName") { (url: String, name: String, useWebKit: Bool) -> Bool in
      return await self.clearCookieByName(url: url, name: name, useWebKit: useWebKit)
    }

    AsyncFunction("flush") { () -> Bool in
      // iOS doesn't need explicit flushing
      return true
    }

    AsyncFunction("removeSessionCookies") { () -> Bool in
      // iOS handles session cookies automatically
      return true
    }
  }

  private func setCookie(url: String, cookie: [String: Any], useWebKit: Bool) async -> Bool {
    guard let urlObj = URL(string: url) else { return false }

    let name = cookie["name"] as? String ?? ""
    let value = cookie["value"] as? String ?? ""
    let domain = cookie["domain"] as? String ?? urlObj.host
    let path = cookie["path"] as? String ?? "/"
    let secure = cookie["secure"] as? Bool ?? false
    let httpOnly = cookie["httpOnly"] as? Bool ?? false

    var properties: [HTTPCookiePropertyKey: Any] = [
      .name: name,
      .value: value,
      .domain: domain ?? "",
      .path: path
    ]

    if let expires = cookie["expires"] as? String {
      let formatter = ISO8601DateFormatter()
      if let date = formatter.date(from: expires) {
        properties[.expires] = date
      }
    }

    if let version = cookie["version"] as? String {
      properties[.version] = version
    }

    if secure {
      properties[.secure] = "TRUE"
    }

    if httpOnly {
      properties[.httpOnly] = "TRUE"
    }

    guard let httpCookie = HTTPCookie(properties: properties) else { return false }

    if useWebKit {
      if #available(iOS 11.0, *) {
        return await withCheckedContinuation { continuation in
          WKWebsiteDataStore.default().httpCookieStore.setCookie(httpCookie) {
            continuation.resume(returning: true)
          }
        }
      } else {
        return false
      }
    } else {
      HTTPCookieStorage.shared.setCookie(httpCookie)
      return true
    }
  }

  private func setFromResponseHeader(url: String, cookieHeader: String) async -> Bool {
    guard let urlObj = URL(string: url) else { return false }

    let cookies = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": cookieHeader], for: urlObj)

    for cookie in cookies {
      HTTPCookieStorage.shared.setCookie(cookie)
    }

    return true
  }

  private func getCookies(url: String, useWebKit: Bool) async -> [String: [String: Any]] {
    guard let urlObj = URL(string: url) else { return [:] }

    let cookies: [HTTPCookie]

    if useWebKit {
      if #available(iOS 11.0, *) {
        cookies = await withCheckedContinuation { continuation in
          WKWebsiteDataStore.default().httpCookieStore.getAllCookies { allCookies in
            let filteredCookies = allCookies.filter { cookie in
              return cookie.domain == urlObj.host || cookie.domain.hasPrefix("." + (urlObj.host ?? ""))
            }
            continuation.resume(returning: filteredCookies)
          }
        }
      } else {
        cookies = []
      }
    } else {
      cookies = HTTPCookieStorage.shared.cookies(for: urlObj) ?? []
    }

    return cookiesToDictionary(cookies)
  }

  private func getAllCookies(useWebKit: Bool) async -> [String: [String: Any]] {
    let cookies: [HTTPCookie]

    if useWebKit {
      if #available(iOS 11.0, *) {
        cookies = await withCheckedContinuation { continuation in
          WKWebsiteDataStore.default().httpCookieStore.getAllCookies { allCookies in
            continuation.resume(returning: allCookies)
          }
        }
      } else {
        cookies = []
      }
    } else {
      cookies = HTTPCookieStorage.shared.cookies ?? []
    }

    return cookiesToDictionary(cookies)
  }

  private func clearAllCookies(useWebKit: Bool) async -> Bool {
    if useWebKit {
      if #available(iOS 11.0, *) {
        return await withCheckedContinuation { continuation in
          WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let group = DispatchGroup()
            for cookie in cookies {
              group.enter()
              WKWebsiteDataStore.default().httpCookieStore.delete(cookie) {
                group.leave()
              }
            }
            group.notify(queue: .main) {
              continuation.resume(returning: true)
            }
          }
        }
      } else {
        return false
      }
    } else {
      if let cookies = HTTPCookieStorage.shared.cookies {
        for cookie in cookies {
          HTTPCookieStorage.shared.deleteCookie(cookie)
        }
      }
      return true
    }
  }

  private func clearCookieByName(url: String, name: String, useWebKit: Bool) async -> Bool {
    guard let urlObj = URL(string: url) else { return false }

    if useWebKit {
      if #available(iOS 11.0, *) {
        return await withCheckedContinuation { continuation in
          WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let cookieToDelete = cookies.first { cookie in
              cookie.name == name && (cookie.domain == urlObj.host || cookie.domain.hasPrefix("." + (urlObj.host ?? "")))
            }

            if let cookie = cookieToDelete {
              WKWebsiteDataStore.default().httpCookieStore.delete(cookie) {
                continuation.resume(returning: true)
              }
            } else {
              continuation.resume(returning: false)
            }
          }
        }
      } else {
        return false
      }
    } else {
      if let cookies = HTTPCookieStorage.shared.cookies(for: urlObj) {
        for cookie in cookies {
          if cookie.name == name {
            HTTPCookieStorage.shared.deleteCookie(cookie)
            return true
          }
        }
      }
      return false
    }
  }

  private func cookiesToDictionary(_ cookies: [HTTPCookie]) -> [String: [String: Any]] {
    var result: [String: [String: Any]] = [:]

    for cookie in cookies {
      var cookieDict: [String: Any] = [
        "name": cookie.name,
        "value": cookie.value,
        "domain": cookie.domain,
        "path": cookie.path
      ]

      if let expiresDate = cookie.expiresDate {
        let formatter = ISO8601DateFormatter()
        cookieDict["expires"] = formatter.string(from: expiresDate)
      }

      if cookie.version != 0 {
        cookieDict["version"] = String(cookie.version)
      }

      cookieDict["secure"] = cookie.isSecure
      cookieDict["httpOnly"] = cookie.isHTTPOnly

      result[cookie.name] = cookieDict
    }

    return result
  }
}
