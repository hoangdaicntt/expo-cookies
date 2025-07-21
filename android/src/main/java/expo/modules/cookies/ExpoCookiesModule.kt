// android/src/main/java/expo/modules/cookies/ExpoCookiesModule.kt
package expo.modules.cookies

import android.webkit.CookieManager
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise
import java.text.SimpleDateFormat
import java.util.*

class ExpoCookiesModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoCookies")

    AsyncFunction("set") { url: String, cookie: Map<String, Any?>, useWebKit: Boolean ->
      setCookie(url, cookie)
    }

    AsyncFunction("setFromResponse") { url: String, cookieHeader: String ->
      setFromResponseHeader(url, cookieHeader)
    }

    AsyncFunction("get") { url: String, useWebKit: Boolean ->
      getCookies(url)
    }

    AsyncFunction("getAll") { useWebKit: Boolean ->
      getAllCookies()
    }

    AsyncFunction("clearAll") { useWebKit: Boolean, promise: Promise ->
      clearAllCookies(promise)
    }

    AsyncFunction("clearByName") { url: String, name: String, useWebKit: Boolean ->
      clearCookieByName(url, name)
    }

    AsyncFunction("flush") { ->
      flushCookies()
    }

    AsyncFunction("removeSessionCookies") { promise: Promise ->
      removeSessionCookies(promise)
    }
  }

  private fun setCookie(url: String, cookie: Map<String, Any?>): Boolean {
    return try {
      val cookieManager = CookieManager.getInstance()
      val name = cookie["name"] as? String ?: ""
      val value = cookie["value"] as? String ?: ""
      val domain = cookie["domain"] as? String
      val path = cookie["path"] as? String ?: "/"
      val expires = cookie["expires"] as? String
      val secure = cookie["secure"] as? Boolean ?: false
      val httpOnly = cookie["httpOnly"] as? Boolean ?: false

      val cookieBuilder = StringBuilder()
      cookieBuilder.append("$name=$value")

      if (domain != null) {
        cookieBuilder.append("; Domain=$domain")
      }

      cookieBuilder.append("; Path=$path")

      if (expires != null) {
        try {
          val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US)
          val date = formatter.parse(expires)
          val gmtFormatter = SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.US)
          gmtFormatter.timeZone = TimeZone.getTimeZone("GMT")
          cookieBuilder.append("; Expires=${gmtFormatter.format(date)}")
        } catch (e: Exception) {
          // If parsing fails, skip expires
        }
      }

      if (secure) {
        cookieBuilder.append("; Secure")
      }

      if (httpOnly) {
        cookieBuilder.append("; HttpOnly")
      }

      cookieManager.setCookie(url, cookieBuilder.toString())
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun setFromResponseHeader(url: String, cookieHeader: String): Boolean {
    return try {
      val cookieManager = CookieManager.getInstance()
      cookieManager.setCookie(url, cookieHeader)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun getCookies(url: String): Map<String, Map<String, Any>> {
    return try {
      val cookieManager = CookieManager.getInstance()
      val cookieString = cookieManager.getCookie(url)

      if (cookieString != null) {
        parseCookieString(cookieString)
      } else {
        emptyMap()
      }
    } catch (e: Exception) {
      emptyMap()
    }
  }

  private fun getAllCookies(): Map<String, Map<String, Any>> {
    // Android doesn't provide a direct way to get all cookies
    // This is a limitation of the Android CookieManager
    return emptyMap()
  }

  private fun clearAllCookies(promise: Promise) {
    try {
      val cookieManager = CookieManager.getInstance()
      cookieManager.removeAllCookies { success ->
        promise.resolve(success)
      }
    } catch (e: Exception) {
      promise.reject("CLEAR_ALL_COOKIES_ERROR", "Failed to clear all cookies", e)
    }
  }

  private fun clearCookieByName(url: String, name: String): Boolean {
    return try {
      val cookieManager = CookieManager.getInstance()
      val cookieString = cookieManager.getCookie(url)

      if (cookieString != null) {
        val cookies = cookieString.split(";").map { it.trim() }
        var found = false

        for (cookie in cookies) {
          val parts = cookie.split("=")
          if (parts.size >= 2 && parts[0].trim() == name) {
            // Set expired cookie to remove it
            val expiredCookie = "$name=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/"
            cookieManager.setCookie(url, expiredCookie)
            found = true
            break
          }
        }

        found
      } else {
        false
      }
    } catch (e: Exception) {
      false
    }
  }

  private fun flushCookies(): Boolean {
    return try {
      val cookieManager = CookieManager.getInstance()
      cookieManager.flush()
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun removeSessionCookies(promise: Promise) {
    try {
      val cookieManager = CookieManager.getInstance()
      cookieManager.removeSessionCookies { success ->
        promise.resolve(success)
      }
    } catch (e: Exception) {
      promise.reject("REMOVE_SESSION_COOKIES_ERROR", "Failed to remove session cookies", e)
    }
  }

  private fun parseCookieString(cookieString: String): Map<String, Map<String, Any>> {
    val cookies = mutableMapOf<String, Map<String, Any>>()

    val cookieParts = cookieString.split(";").map { it.trim() }

    for (cookiePart in cookieParts) {
      val parts = cookiePart.split("=", limit = 2)
      if (parts.size == 2) {
        val name = parts[0].trim()
        val value = parts[1].trim()

        val cookieMap = mutableMapOf<String, Any>(
          "name" to name,
          "value" to value,
          "path" to "/",
          "secure" to false,
          "httpOnly" to false
        )

        cookies[name] = cookieMap
      }
    }

    return cookies
  }
}
