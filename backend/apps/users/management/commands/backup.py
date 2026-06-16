"""
Management command for database backup.
"""
from django.core.management.base import BaseCommand
from django.conf import settings
import sys
import os

# Add project root to path
sys.path.insert(0, str(settings.BASE_DIR))

from utils.backup import DatabaseBackup


class Command(BaseCommand):
    help = 'Create database backup'

    def handle(self, *args, **options):
        self.stdout.write('Starting backup...')
        
        backup = DatabaseBackup()
        result = backup.create_backup()
        
        if result['success']:
            self.stdout.write(
                self.style.SUCCESS(f"Backup created successfully: {result['file']}")
            )
        else:
            self.stdout.write(
                self.style.ERROR(f"Backup failed: {result.get('error', 'Unknown error')}")
            )
            sys.exit(1)
