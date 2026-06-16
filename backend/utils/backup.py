"""
Database backup utilities.
"""
import os
import subprocess
import gzip
import shutil
from datetime import datetime
from pathlib import Path
from django.conf import settings


class DatabaseBackup:
    """Handle database backup and restore operations."""
    
    def __init__(self):
        self.backup_dir = Path(settings.BACKUP_DIR)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        self.db_name = settings.DATABASES['default']['NAME']
        self.db_user = settings.DATABASES['default']['USER']
        self.db_host = settings.DATABASES['default']['HOST']
        self.db_port = settings.DATABASES['default']['PORT']
    
    def create_backup(self):
        """Create database backup."""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_file = self.backup_dir / f'{self.db_name}_{timestamp}.sql'
        
        try:
            # Run pg_dump
            cmd = [
                'pg_dump',
                '-h', self.db_host,
                '-p', str(self.db_port),
                '-U', self.db_user,
                '-d', self.db_name,
                '-F', 'p',  # Plain text format
                '-f', str(backup_file)
            ]
            
            # Set password via environment
            env = os.environ.copy()
            env['PGPASSWORD'] = settings.DATABASES['default']['PASSWORD']
            
            subprocess.run(cmd, env=env, check=True)
            
            # Compress backup
            compressed_file = self._compress_file(backup_file)
            
            # Remove uncompressed file
            backup_file.unlink()
            
            # Clean old backups
            self._cleanup_old_backups()
            
            return {
                'success': True,
                'file': str(compressed_file),
                'timestamp': timestamp,
            }
            
        except subprocess.CalledProcessError as e:
            return {
                'success': False,
                'error': f'Backup failed: {str(e)}',
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Unexpected error: {str(e)}',
            }
    
    def _compress_file(self, file_path):
        """Compress backup file using gzip."""
        compressed_path = Path(str(file_path) + '.gz')
        
        with open(file_path, 'rb') as f_in:
            with gzip.open(compressed_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        
        return compressed_path
    
    def _cleanup_old_backups(self):
        """Remove backups older than configured days."""
        keep_days = getattr(settings, 'BACKUP_KEEP_DAYS', 30)
        cutoff = datetime.now().timestamp() - (keep_days * 24 * 60 * 60)
        
        for backup_file in self.backup_dir.glob('*.sql.gz'):
            if backup_file.stat().st_mtime < cutoff:
                backup_file.unlink()
    
    def restore_backup(self, backup_file):
        """Restore database from backup."""
        backup_path = Path(backup_file)
        
        if not backup_path.exists():
            return {
                'success': False,
                'error': 'Backup file not found',
            }
        
        try:
            # Decompress if needed
            if str(backup_path).endswith('.gz'):
                temp_file = backup_path.with_suffix('')
                with gzip.open(backup_path, 'rb') as f_in:
                    with open(temp_file, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                restore_file = temp_file
            else:
                restore_file = backup_path
            
            # Run psql to restore
            cmd = [
                'psql',
                '-h', self.db_host,
                '-p', str(self.db_port),
                '-U', self.db_user,
                '-d', self.db_name,
                '-f', str(restore_file)
            ]
            
            env = os.environ.copy()
            env['PGPASSWORD'] = settings.DATABASES['default']['PASSWORD']
            
            subprocess.run(cmd, env=env, check=True)
            
            # Clean up temp file
            if str(backup_path).endswith('.gz'):
                restore_file.unlink()
            
            return {
                'success': True,
                'message': 'Database restored successfully',
            }
            
        except subprocess.CalledProcessError as e:
            return {
                'success': False,
                'error': f'Restore failed: {str(e)}',
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Unexpected error: {str(e)}',
            }
    
    def list_backups(self):
        """List all available backups."""
        backups = []
        
        for backup_file in sorted(self.backup_dir.glob('*.sql.gz'), reverse=True):
            stat = backup_file.stat()
            backups.append({
                'filename': backup_file.name,
                'path': str(backup_file),
                'size': stat.st_size,
                'created': datetime.fromtimestamp(stat.st_mtime).isoformat(),
            })
        
        return backups
