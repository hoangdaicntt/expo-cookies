// ios/ExpoCookiesModule.swift
import ExpoModulesCore
import Foundation
import WebKit

public class ExpoCookiesModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoCookies")

    // Sử dụng Promise thay vì async/await để tương thích với Expo Module API
    AsyncFunction("set") { (url: String, cookie: [String: Any], useWebKit: Bool, promise: Promise) in
      self.setCookie(url: url, cookie: cookie, useWebKit: useWebKit, promise: promise)
    }

    AsyncFunction("setFromResponse") { (url: String, cookieHeader: String, promise: Promise) in
      self.setFromResponseHeader(url: url, cookieHeader: cookieHeader, promise: promise)
    }

    AsyncFunction("get") { (url: String, useWebKit: Bool, promise: Promise) in
      self.getCookies(url: url, useWebKit: useWebKit, promise: promise)
    }

    AsyncFunction("getAll") { (useWebKit: Bool, promise: Promise) in
      self.getAllCookies(useWebKit: useWebKit, promise: promise)
    }

    AsyncFunction("clearAll") { (useWebKit: Bool, promise: Promise) in
      self.clearAllCookies(useWebKit: useWebKit, promise: promise)
    }

    AsyncFunction("clearByName") { (url: String, name: String, useWebKit: Bool, promise: Promise) in
      self.clearCookieByName(url: url, name: name, useWebKit: useWebKit, promise: promise)
    }

    AsyncFunction("flush") { (promise: Promise) in
      // iOS doesn't need explicit flushing
      promise.resolve(true)
    }

    AsyncFunction("removeSessionCookies") { (promise: Promise) in
      // iOS handles session cookies automatically
      promise.resolve(true)
    }
  }

  private func setCookie(url: String, cookie: [String: Any], useWebKit: Bool, promise: Promise) {
    guard let urlObj = URL(string: url) else {
      promise.resolve(false)
      return
    }

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

    guard let httpCookie = HTTPCookie(properties: properties) else {
      promise.resolve(false)
      return
    }

    if useWebKit {
      if #available(iOS 11.0, *) {
        WKWebsiteDataStore.default().httpCookieStore.setCookie(httpCookie) {
          promise.resolve(true)
        }
      } else {
        promise.resolve(false)
      }
    } else {
      HTTPCookieStorage.shared.setCookie(httpCookie)
      promise.resolve(true)
    }
  }

  private func setFromResponseHeader(url: String, cookieHeader: String, promise: Promise) {
    guard let urlObj = URL(string: url) else {
      promise.resolve(false)
      return
    }

    let cookies = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": cookieHeader], for: urlObj)

    for cookie in cookies {
      HTTPCookieStorage.shared.setCookie(cookie)
    }

    promise.resolve(true)
  }

  private func getCookies(url: String, useWebKit: Bool, promise: Promise) {
    guard let urlObj = URL(string: url) else {
      promise.resolve([:])
      return
    }

    if useWebKit {
      if #available(iOS 11.0, *) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { allCookies in
          let filteredCookies = allCookies.filter { cookie in
            return cookie.domain == urlObj.host || cookie.domain.hasPrefix("." + (urlObj.host ?? ""))
          }
          promise.resolve(self.cookiesToDictionary(filteredCookies))
        }
      } else {
        promise.resolve([:])
      }
    } else {
      let cookies = HTTPCookieStorage.shared.cookies(for: urlObj) ?? []
      promise.resolve(cookiesToDictionary(cookies))
    }
  }

  private func getAllCookies(useWebKit: Bool, promise: Promise) {
    if useWebKit {
      if #available(iOS 11.0, *) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { allCookies in
          promise.resolve(self.cookiesToDictionary(allCookies))
        }
      } else {
        promise.resolve([:])
      }
    } else {
      let cookies = HTTPCookieStorage.shared.cookies ?? []
      promise.resolve(cookiesToDictionary(cookies))
    }
  }

  private func clearAllCookies(useWebKit: Bool, promise: Promise) {
    if useWebKit {
      if #available(iOS 11.0, *) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
          let group = DispatchGroup()
          for cookie in cookies {
            group.enter()
            WKWebsiteDataStore.default().httpCookieStore.delete(cookie) {
              group.leave()
            }
          }
          group.notify(queue: .main) {
            promise.resolve(true)
          }
        }
      } else {
        promise.resolve(false)
      }
    } else {
      if let cookies = HTTPCookieStorage.shared.cookies {
        for cookie in cookies {
          HTTPCookieStorage.shared.deleteCookie(cookie)
        }
      }
      promise.resolve(true)
    }
  }

  private func clearCookieByName(url: String, name: String, useWebKit: Bool, promise: Promise) {
    guard let urlObj = URL(string: url) else {
      promise.resolve(false)
      return
    }

    if useWebKit {
      if #available(iOS 11.0, *) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
          let cookieToDelete = cookies.first { cookie in
            cookie.name == name && (cookie.domain == urlObj.host || cookie.domain.hasPrefix("." + (urlObj.host ?? "")))
          }

          if let cookie = cookieToDelete {
            WKWebsiteDataStore.default().httpCookieStore.delete(cookie) {
              promise.resolve(true)
            }
          } else {
            promise.resolve(false)
          }
        }
      } else {
        promise.resolve(false)
      }
    } else {
      if let cookies = HTTPCookieStorage.shared.cookies(for: urlObj) {
        for cookie in cookies {
          if cookie.name == name {
            HTTPCookieStorage.shared.deleteCookie(cookie)
            promise.resolve(true)
            return
          }
        }
      }
      promise.resolve(false)
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
