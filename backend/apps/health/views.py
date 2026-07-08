"""
Healthcheck endpoint for Docker container orchestration.
No authentication required — used by Docker healthcheck, load balancers, and monitoring.
"""
import logging

from django.db import connection, OperationalError
from django.http import JsonResponse
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)


def healthcheck(request):
    """
    Simple healthcheck endpoint.

    Checks:
      - Database connectivity (can establish a connection)
      - Redis connectivity (can ping the cache backend)

    Returns:
      200 OK — {"status": "healthy", "checks": {...}}
      503 Service Unavailable — {"status": "unhealthy", "checks": {...}}
    """
    checks = {}
    healthy = True

    # ── Database check ─────────────────────────────────────────
    try:
        connection.ensure_connection()
        # Run a trivial query to verify the connection is truly alive
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        checks["database"] = {"status": "ok"}
    except OperationalError as e:
        checks["database"] = {"status": "error", "detail": str(e)}
        healthy = False
        logger.error(f"Healthcheck — database: {e}")
    except Exception as e:
        checks["database"] = {"status": "error", "detail": str(e)}
        healthy = False
        logger.error(f"Healthcheck — database (unexpected): {e}")

    # ── Redis / Cache check ────────────────────────────────────
    try:
        cache.set("__healthcheck__", "1", timeout=5)
        result = cache.get("__healthcheck__")
        if result == "1":
            checks["cache"] = {"status": "ok"}
        else:
            checks["cache"] = {"status": "error", "detail": "cache write/read mismatch"}
            healthy = False
    except Exception as e:
        checks["cache"] = {"status": "error", "detail": str(e)}
        healthy = False
        logger.error(f"Healthcheck — cache: {e}")

    status_code = 200 if healthy else 503
    return JsonResponse(
        {"status": "healthy" if healthy else "unhealthy", "checks": checks},
        status=status_code,
    )
