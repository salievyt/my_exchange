"""
Signals for Registration Requests app.
Fires notifications to Telegram bot when a new request is created.
"""
import django.dispatch

request_created = django.dispatch.Signal()
