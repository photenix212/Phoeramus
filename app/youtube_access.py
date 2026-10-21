from __future__ import annotations

import os
from pathlib import Path

import yt_dlp


BOT_CHECK_MARKERS = (
    "sign in to confirm you're not a bot",
    "sign in to confirm you’re not a bot",
    "confirm you're not a bot",
    "confirm you’re not a bot",
    "use --cookies-from-browser",
    "use --cookies for the authentication",
    "login required",
)


def is_youtube_url(url: str) -> bool:
    value = (url or "").lower()
    return "youtube.com/" in value or "youtu.be/" in value


def is_auth_error(exc: BaseException | str) -> bool:
    text = str(exc).lower()
    return any(marker in text for marker in BOT_CHECK_MARKERS)


def _browser_paths() -> dict[str, tuple[Path, ...]]:
    local = Path(os.environ.get("LOCALAPPDATA", ""))
    roaming = Path(os.environ.get("APPDATA", ""))
    return {
        "chrome": (
            local / "Google" / "Chrome" / "User Data",
            local / "Google" / "Chrome Beta" / "User Data",
        ),
        "edge": (
            local / "Microsoft" / "Edge" / "User Data",
        ),
        "firefox": (
            roaming / "Mozilla" / "Firefox" / "Profiles",
        ),
    }


def available_browsers(preferred: str = "") -> list[str]:
    paths = _browser_paths()
    found = [name for name in ("chrome", "edge", "firefox")
             if any(path.exists() for path in paths[name])]
    preferred = (preferred or "").lower()
    if preferred in found:
        found.remove(preferred)
        found.insert(0, preferred)
    return found


def human_auth_error(language: str, attempts: list[tuple[str, str]]) -> str:
    ru = (language or "en").lower() == "ru"
    if attempts:
        details = "; ".join(f"{name.capitalize()}: {reason}" for name, reason in attempts)
    else:
        details = "Chrome / Edge / Firefox profiles not found"

    if ru:
        return (
            "YouTube запросил подтверждение, что вы не бот. "
            "Phoeramus автоматически попробовал cookies из доступных браузеров, "
            "но авторизация не сработала.\n\n"
            "Войдите в YouTube в Chrome, Edge или Firefox и повторите попытку.\n"
            f"Диагностика: {details}"
        )
    return (
        "YouTube asked to confirm that you're not a bot. "
        "Phoeramus automatically tried cookies from available browsers, "
        "but authentication still failed.\n\n"
        "Sign in to YouTube in Chrome, Edge or Firefox and try again.\n"
        f"Diagnostics: {details}"
    )


def short_reason(exc: BaseException | str) -> str:
    text = str(exc).replace("\r", " ").replace("\n", " ").strip()
    low = text.lower()
    if "could not find" in low and "cookies" in low:
        return "cookies not found"
    if "failed to decrypt" in low or "decrypt" in low:
        return "cookie decryption failed"
    if "permission" in low or "being used by another process" in low or "locked" in low:
        return "browser cookie database is locked"
    if is_auth_error(text):
        return "YouTube still rejected authentication"
    if len(text) > 110:
        text = text[:107] + "..."
    return text or "failed"


def run_with_cookie_fallback(url, base_options, action, language="en", preferred_browser=""):
    """
    Run a yt-dlp action normally. Only if YouTube returns an auth/bot-check
    error, retry with cookies from installed Chrome, Edge and Firefox profiles.

    action(ydl) should perform extract_info() or download().
    Returns (result, browser_used). browser_used is "" for the normal path.
    """
    try:
        with yt_dlp.YoutubeDL(dict(base_options)) as ydl:
            return action(ydl), ""
    except yt_dlp.utils.DownloadError as first_error:
        if not is_youtube_url(url) or not is_auth_error(first_error):
            raise

        attempts = []
        browsers = available_browsers(preferred_browser)
        for browser in browsers:
            options = dict(base_options)
            options["cookiesfrombrowser"] = (browser,)
            try:
                with yt_dlp.YoutubeDL(options) as ydl:
                    return action(ydl), browser
            except yt_dlp.utils.DownloadError as exc:
                attempts.append((browser, short_reason(exc)))
            except Exception as exc:
                attempts.append((browser, short_reason(exc)))

        raise RuntimeError(human_auth_error(language, attempts)) from first_error
