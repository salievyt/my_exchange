"""
Middleware for automatic audit logging.
"""
import json
from django.utils import timezone
from django.conf import settings
from .models import AuditLog, ActionType


class AuditLogMiddleware:
    """Middleware to automatically log API requests."""
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Process request
        response = self.get_response(request)
        
        # Log after response (for successful requests)
        if request.path.startswith('/api/') and request.user.is_authenticated:
            self._log_request(request, response)
        
        return response
    
    def _log_request(self, request, response):
        """Log API request to audit log."""
        # Skip read operations for performance
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return
        
        # Determine action type
        action_map = {
            'POST': ActionType.CREATE,
            'PUT': ActionType.UPDATE,
            'PATCH': ActionType.UPDATE,
            'DELETE': ActionType.DELETE,
        }
        
        action = action_map.get(request.method)
        if not action:
            return
        
        # Extract model name from URL
        model_name = self._extract_model_name(request.path)
        
        # Get object ID from URL
        object_id = self._extract_object_id(request.path)
        
        # Get request body for details
        details = {}
        if request.body:
            try:
                details = json.loads(request.body)
            except (json.JSONDecodeError, ValueError):
                pass
        
        # Create audit log entry
        AuditLog.objects.create(
            user=request.user,
            action=action,
            model_name=model_name,
            object_id=object_id,
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
            details={
                'path': request.path,
                'method': request.method,
                'status_code': response.status_code,
                'request_data': details if details else None,
            }
        )
    
    def _extract_model_name(self, path):
        """Extract model name from API path."""
        # Example: /api/operations/operations/123/ -> operations
        parts = path.strip('/').split('/')
        if len(parts) >= 3 and parts[0] == 'api':
            return parts[2]
        return ''
    
    def _extract_object_id(self, path):
        """Extract object ID from API path."""
        parts = path.strip('/').split('/')
        # Look for numeric ID in path
        for part in parts:
            if part.isdigit():
                return int(part)
        return None
    
    def _get_client_ip(self, request):
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
