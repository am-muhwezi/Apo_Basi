"""
Test settings to make the test suite run locally without external services.

Usage: pass this settings module to Django via `--settings=apo_basi.test_settings`
or set `DJANGO_SETTINGS_MODULE=apo_basi.test_settings` when running tests.
"""
from .settings import *  # noqa: F401,F403
from decouple import config

# Use in-memory SQLite for fast, isolated tests
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}

# Use local-memory cache to avoid Redis during tests
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "test-cache",
    }
}

# Use in-memory channel layer to avoid Redis during channels tests
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",
    }
}

# Point Redis config to a harmless local placeholder (some code may still try to connect).
REDIS_HOST = config("REDIS_HOST", default="localhost")
REDIS_PORT = config("REDIS_PORT", default=6379, cast=int)
REDIS_DB = config("REDIS_DB", default=0, cast=int)
REDIS_PASSWORD = config("REDIS_PASSWORD", default=None)

# Leave LOGGING as-is; avoid mutating undefined LOGGING variable here.
