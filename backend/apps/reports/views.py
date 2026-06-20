"""
Views for Reports app.
Handles report generation and data export.
"""
from rest_framework import views, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django.db.models import Sum, Count, Avg, Q
from django.http import HttpResponse
from django.utils import timezone
from datetime import timedelta
import csv
import io
import json

from apps.operations.models import Operation, OperationStatus, OperationType
from apps.cash.models import CashTransaction, CashBalance, CashRegister
from apps.currencies.models import Currency
from apps.users.models import Role


class DailyReportView(views.APIView):
    """Generate daily report."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        date = request.query_params.get('date', timezone.now().date())
        
        # Filter operations for the day
        operations = Operation.objects.filter(created_at__date=date)
        
        # Role-based filtering
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        
        # Calculate stats
        active_ops = operations.filter(status=OperationStatus.ACTIVE)
        
        report = {
            'date': str(date),
            'total_operations': active_ops.count(),
            'buy_operations': active_ops.filter(operation_type=OperationType.BUY).count(),
            'sell_operations': active_ops.filter(operation_type=OperationType.SELL).count(),
            'total_turnover': active_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            'buy_turnover': active_ops.filter(
                operation_type=OperationType.BUY
            ).aggregate(total=Sum('total_amount'))['total'] or 0,
            'sell_turnover': active_ops.filter(
                operation_type=OperationType.SELL
            ).aggregate(total=Sum('total_amount'))['total'] or 0,
            'cancelled_operations': operations.filter(
                status=OperationStatus.CANCELLED
            ).count(),
            'cashiers_count': operations.values('cashier').distinct().count(),
        }
        
        # Add currency breakdown
        currency_breakdown = []
        for currency in Currency.objects.all():
            ops = active_ops.filter(currency=currency)
            currency_breakdown.append({
                'currency': currency.code,
                'operations': ops.count(),
                'total_amount': ops.aggregate(total=Sum('amount'))['total'] or 0,
                'turnover': ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            })
        
        report['currency_breakdown'] = currency_breakdown
        
        # Add cash balances
        balances = CashBalance.objects.select_related('currency').all()
        report['cash_balances'] = [
            {
                'currency': b.currency.code,
                'balance': float(b.balance),
            }
            for b in balances
        ]
        
        return Response(report)


class MonthlyReportView(views.APIView):
    """Generate monthly report."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        year = int(request.query_params.get('year', timezone.now().year))
        month = int(request.query_params.get('month', timezone.now().month))
        
        # Date range
        from datetime import date
        from calendar import monthrange
        
        _, last_day = monthrange(year, month)
        date_from = date(year, month, 1)
        date_to = date(year, month, last_day)
        
        # Filter operations
        operations = Operation.objects.filter(
            created_at__date__gte=date_from,
            created_at__date__lte=date_to,
            status=OperationStatus.ACTIVE
        )
        
        # Role-based filtering
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        
        report = {
            'year': year,
            'month': month,
            'total_operations': operations.count(),
            'total_turnover': operations.aggregate(total=Sum('total_amount'))['total'] or 0,
            'avg_operation_amount': operations.aggregate(avg=Avg('total_amount'))['avg'] or 0,
        }
        
        # Daily breakdown
        daily_stats = []
        for day in range(1, last_day + 1):
            current_date = date(year, month, day)
            day_ops = operations.filter(created_at__date=current_date)
            daily_stats.append({
                'date': str(current_date),
                'operations': day_ops.count(),
                'turnover': day_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            })
        
        report['daily_stats'] = daily_stats
        
        # Cashier statistics
        cashier_stats = []
        cashiers = operations.values('cashier', 'cashier__username', 'cashier__first_name', 'cashier__last_name')
        for cashier_info in cashiers.distinct():
            cashier_id = cashier_info['cashier']
            cashier_ops = operations.filter(cashier=cashier_id)
            cashier_stats.append({
                'cashier_id': cashier_id,
                'username': cashier_info['cashier__username'],
                'name': f"{cashier_info['cashier__first_name']} {cashier_info['cashier__last_name']}",
                'operations': cashier_ops.count(),
                'turnover': cashier_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            })
        
        report['cashier_stats'] = cashier_stats
        
        return Response(report)


class CashierReportView(views.APIView):
    """Generate report for specific cashier."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, cashier_id=None):
        if not cashier_id:
            cashier_id = request.user.id
        
        # Check permissions
        if request.user.role == Role.CASHIER and request.user.id != cashier_id:
            return Response(
                {"error": "Нет доступа к отчетам других кассиров"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        
        operations = Operation.objects.filter(cashier_id=cashier_id)
        
        if date_from:
            operations = operations.filter(created_at__date__gte=date_from)
        if date_to:
            operations = operations.filter(created_at__date__lte=date_to)
        
        active_ops = operations.filter(status=OperationStatus.ACTIVE)
        cancelled_ops = operations.filter(status=OperationStatus.CANCELLED)
        
        report = {
            'cashier_id': cashier_id,
            'period': {
                'from': date_from,
                'to': date_to,
            },
            'total_operations': active_ops.count(),
            'buy_operations': active_ops.filter(operation_type=OperationType.BUY).count(),
            'sell_operations': active_ops.filter(operation_type=OperationType.SELL).count(),
            'total_turnover': active_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            'cancelled_count': cancelled_ops.count(),
            'errors_count': cancelled_ops.count(),  # Treat cancellations as errors for stats
        }
        
        # Currency breakdown
        currency_stats = []
        for currency in Currency.objects.all():
            currency_ops = active_ops.filter(currency=currency)
            currency_stats.append({
                'currency': currency.code,
                'operations': currency_ops.count(),
                'total_amount': currency_ops.aggregate(total=Sum('amount'))['total'] or 0,
            })
        
        report['currency_stats'] = currency_stats
        
        return Response(report)


class ExportView(views.APIView):
    """Export data to various formats."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        export_format = request.query_params.get('format', 'csv')
        export_type = request.query_params.get('type', 'operations')
        
        if export_type == 'operations':
            return self.export_operations(request, export_format)
        elif export_type == 'cash':
            return self.export_cash(request, export_format)
        elif export_type == 'report':
            return self.export_report(request, export_format)
        elif export_type == 'cashier_shift':
            return self.export_cashier_shift(request, export_format)
        
        return Response(
            {"error": "Неподдерживаемый тип экспорта"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    def export_operations(self, request, export_format):
          """Export operations data."""
          operations = Operation.objects.select_related(
              'currency', 'cashier'
          ).all()
          
          # Apply filters
          date_from = request.query_params.get('date_from')
          date_to = request.query_params.get('date_to')
          if date_from:
              operations = operations.filter(created_at__date__gte=date_from)
          if date_to:
              operations = operations.filter(created_at__date__lte=date_to)
          
          # Role-based filtering
          if request.user.role == Role.CASHIER:
              operations = operations.filter(cashier=request.user)
          
          if export_format == 'csv':
              return self.export_to_csv(operations, 'operations')
          elif export_format == 'xlsx':
              return self.export_to_xlsx(operations, 'operations')
          elif export_format == 'pdf':
              return self.export_to_pdf(operations, 'operations')
          
          return Response(
              {"error": "Неподдерживаемый формат экспорта"},
              status=status.HTTP_400_BAD_REQUEST
          )
    
    def export_cash(self, request, export_format):
          """Export cash transactions."""
          transactions = CashTransaction.objects.select_related(
              'currency', 'cashier'
          ).all()
          
          if export_format == 'csv':
              return self.export_to_csv(transactions, 'cash')
          elif export_format == 'xlsx':
              return self.export_to_xlsx(transactions, 'cash')
          elif export_format == 'pdf':
              return self.export_to_pdf(transactions, 'cash')
          
          return Response(
              {"error": "Неподдерживаемый формат экспорта"},
              status=status.HTTP_400_BAD_REQUEST
          )
    
    def export_to_csv(self, queryset, export_type):
        """Export data to CSV format."""
        output = io.StringIO()
        writer = csv.writer(output)
        
        if export_type == 'operations':
            writer.writerow([
                'Номер операции', 'Дата', 'Время', 'Тип', 'Валюта',
                'Курс', 'Сумма', 'Общая сумма', 'Кассир', 'Статус', 'Комментарий'
            ])
            for obj in queryset:
                writer.writerow([
                    obj.operation_number,
                    obj.created_at.strftime('%Y-%m-%d'),
                    obj.created_at.strftime('%H:%M:%S'),
                    obj.get_operation_type_display(),
                    obj.currency.code,
                    obj.rate,
                    obj.amount,
                    obj.total_amount,
                    obj.cashier.username,
                    obj.get_status_display(),
                    obj.comment
                ])
        elif export_type == 'cash':
            writer.writerow([
                'Тип операции', 'Дата', 'Время', 'Валюта', 'Сумма',
                'Остаток до', 'Остаток после', 'Кассир', 'Комментарий'
            ])
            for obj in queryset:
                writer.writerow([
                    obj.get_transaction_type_display(),
                    obj.created_at.strftime('%Y-%m-%d'),
                    obj.created_at.strftime('%H:%M:%S'),
                    obj.currency.code,
                    obj.amount,
                    obj.balance_before,
                    obj.balance_after,
                    obj.cashier.username,
                    obj.comment
                ])
        
        response = HttpResponse(output.getvalue(), content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="export_{export_type}_{timezone.now().strftime("%Y%m%d")}.csv"'
        return response
    
    def export_to_xlsx(self, queryset, export_type):
        """Export data to Excel format."""
        try:
            from openpyxl import Workbook
            
            wb = Workbook()
            ws = wb.active
            ws.title = export_type
            
            if export_type == 'operations':
                ws.append([
                    'Номер операции', 'Дата', 'Время', 'Тип', 'Валюта',
                    'Курс', 'Сумма', 'Общая сумма', 'Кассир', 'Статус', 'Комментарий'
                ])
                for obj in queryset:
                    ws.append([
                        obj.operation_number,
                        obj.created_at.strftime('%Y-%m-%d'),
                        obj.created_at.strftime('%H:%M:%S'),
                        obj.get_operation_type_display(),
                        obj.currency.code,
                        float(obj.rate),
                        float(obj.amount),
                        float(obj.total_amount),
                        obj.cashier.username,
                        obj.get_status_display(),
                        obj.comment
                    ])
            elif export_type == 'cash':
                ws.append([
                    'Тип операции', 'Дата', 'Время', 'Валюта', 'Сумма',
                    'Остаток до', 'Остаток после', 'Кассир', 'Комментарий'
                ])
                for obj in queryset:
                    ws.append([
                        obj.get_transaction_type_display(),
                        obj.created_at.strftime('%Y-%m-%d'),
                        obj.created_at.strftime('%H:%M:%S'),
                        obj.currency.code,
                        float(obj.amount),
                        float(obj.balance_before),
                        float(obj.balance_after),
                        obj.cashier.username,
                        obj.comment
                    ])
            
            output = io.BytesIO()
            wb.save(output)
            output.seek(0)
            
            response = HttpResponse(
                output.getvalue(),
                content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            )
            response['Content-Disposition'] = f'attachment; filename="export_{export_type}_{timezone.now().strftime("%Y%m%d")}.xlsx"'
            return response
        except ImportError:
              return Response(
                  {"error": "Библиотека openpyxl не установлена"},
                  status=status.HTTP_500_INTERNAL_SERVER_ERROR
              )
    
    def export_to_pdf(self, queryset, export_type):
        """Export data to PDF format using reportlab."""
        try:
            from reportlab.lib.pagesizes import A4, landscape
            from reportlab.platypus import (
                SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
            )
            from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
            from reportlab.lib import colors
            from reportlab.lib.units import mm
            
            from reportlab.pdfbase import pdfmetrics
            from reportlab.pdfbase.ttfonts import TTFont

            # Try to register a Unicode font for Cyrillic support
            # If DejaVu is available, use it – otherwise fall back to Helvetica
            font_name = 'Helvetica'
            for candidate_path, candidate_name in [
                ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'DejaVuSans'),
                ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'DejaVu'),
                ('/usr/share/fonts/truetype/msttcorefonts/arial.ttf', 'Arial'),
            ]:
                try:
                    pdfmetrics.registerFont(TTFont(candidate_name, candidate_path))
                    font_name = candidate_name
                    break
                except Exception:
                    continue

            styles = getSampleStyleSheet()
            style_normal = ParagraphStyle(
                'TableHeader',
                parent=styles['Normal'],
                fontName=font_name,
                fontSize=8,
                leading=10,
            )
            style_header = ParagraphStyle(
                'TableHeaderBold',
                parent=styles['Normal'],
                fontName=font_name,
                fontSize=8,
                leading=10,
                textColor=colors.white,
            )
            style_title = ParagraphStyle(
                'Title',
                parent=styles['Normal'],
                fontName=font_name,
                fontSize=16,
                leading=20,
                spaceAfter=6,
            )
            style_subtitle = ParagraphStyle(
                'Subtitle',
                parent=styles['Normal'],
                fontName=font_name,
                fontSize=10,
                leading=14,
                textColor=colors.grey,
                spaceAfter=12,
            )

            def p(text, style=style_normal):
                return Paragraph(str(text if text is not None else ''), style)

            # Prepare table headers and data
            if export_type == 'operations':
                headers = [
                    'Номер', 'Дата', 'Время', 'Тип', 'Валюта',
                    'Курс', 'Сумма', 'Итого', 'Кассир', 'Статус',
                ]
                rows = []
                for obj in queryset:
                    rows.append([
                        obj.operation_number,
                        obj.created_at.strftime('%Y-%m-%d'),
                        obj.created_at.strftime('%H:%M'),
                        obj.get_operation_type_display(),
                        obj.currency.code,
                        f'{obj.rate:.4f}',
                        f'{obj.amount:.2f}',
                        f'{obj.total_amount:.2f}',
                        obj.cashier.username,
                        obj.get_status_display(),
                    ])
            elif export_type == 'cash':
                headers = [
                    'Тип', 'Дата', 'Время', 'Валюта', 'Сумма',
                    'Остаток до', 'Остаток после', 'Кассир', 'Комментарий',
                ]
                rows = []
                for obj in queryset:
                    rows.append([
                        obj.get_transaction_type_display(),
                        obj.created_at.strftime('%Y-%m-%d'),
                        obj.created_at.strftime('%H:%M'),
                        obj.currency.code,
                        f'{obj.amount:.2f}',
                        f'{obj.balance_before:.2f}',
                        f'{obj.balance_after:.2f}',
                        obj.cashier.username,
                        obj.comment or '',
                    ])
            else:
                return Response(
                    {"error": "Неподдерживаемый тип данных для PDF"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            date_str = timezone.now().strftime('%Y-%m-%d_%H%M%S')
            filename = f'export_{export_type}_{date_str}.pdf'

            # Use landscape for more columns
            page_size = landscape(A4) if len(headers) > 8 else A4

            output = io.BytesIO()
            doc = SimpleDocTemplate(
                output,
                pagesize=page_size,
                topMargin=20*mm,
                bottomMargin=15*mm,
                leftMargin=15*mm,
                rightMargin=15*mm,
            )

            elements = []

            # Title
            title_text = f'Экспорт {"операций" if export_type == "operations" else "кассы"}'
            elements.append(Paragraph(title_text, style_title))
            elements.append(
                Paragraph(f'Сформировано: {timezone.now().strftime("%d.%m.%Y %H:%M")}', style_subtitle)
            )
            elements.append(Spacer(1, 6*mm))

            # Build table
            table_data = [[p(h, style_header) for h in headers]]
            for row in rows:
                table_data.append([p(cell) for cell in row])

            col_width = page_size[0] / len(headers)
            available_width = page_size[0] - 30*mm
            col_widths = [available_width / len(headers)] * len(headers)

            table = Table(table_data, colWidths=col_widths, repeatRows=1)
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a73e8')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTSIZE', (0, 0), (-1, -1), 7),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#cccccc')),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
                ('FONTNAME', (0, 0), (-1, -1), font_name),
            ]))
            elements.append(table)

            # Footer
            elements.append(Spacer(1, 8*mm))
            elements.append(
                Paragraph(
                    f'Всего записей: {len(rows)}',
                    ParagraphStyle(
                        'Footer',
                        parent=styles['Normal'],
                        fontName=font_name,
                        fontSize=8,
                        textColor=colors.grey,
                    )
                )
            )

            doc.build(elements)
            pdf_bytes = output.getvalue()
            output.close()

            response = HttpResponse(pdf_bytes, content_type='application/pdf')
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            response['Content-Length'] = len(pdf_bytes)
            return response

        except ImportError:
            return Response(
                {"error": "Библиотека reportlab не установлена"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def export_cashier_shift(self, request, export_format):
        """Export cashier shift report as PDF."""
        from apps.cash.models import CashRegister
        from django.utils import timezone as tz
        from calendar import monthrange
        from datetime import date, timedelta

        today = timezone.now().date()

        # Get today's operations for the current cashier
        operations = Operation.objects.filter(
            created_at__date=today,
        )
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)

        # Get cashier's registers for today
        registers = CashRegister.objects.filter(
            opened_at__date=today,
        )
        if request.user.role == Role.CASHIER:
            registers = registers.filter(cashier=request.user)

        active_ops = operations.filter(status=OperationStatus.ACTIVE)
        buy_ops = active_ops.filter(operation_type=OperationType.BUY)
        sell_ops = active_ops.filter(operation_type=OperationType.SELL)

        buy_amount_total = float(buy_ops.aggregate(total=Sum('total_amount'))['total'] or 0)
        sell_amount_total = float(sell_ops.aggregate(total=Sum('total_amount'))['total'] or 0)
        total_turnover = buy_amount_total + sell_amount_total

        if export_format == 'pdf':
            return self._export_cashier_shift_pdf(
                request, operations, registers,
                today, total_turnover, buy_amount_total, sell_amount_total
            )

        return Response(
            {"error": "Для отчёта по смене доступен только PDF"},
            status=status.HTTP_400_BAD_REQUEST
        )

    def _export_cashier_shift_pdf(self, request, operations, registers,
                                    date, total_turnover, buy_amount, sell_amount):
        """Generate cashier shift PDF report."""
        try:
            from reportlab.lib.pagesizes import A4
            from reportlab.platypus import (
                SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
            )
            from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
            from reportlab.lib import colors
            from reportlab.lib.units import mm
            from reportlab.pdfbase import pdfmetrics
            from reportlab.pdfbase.ttfonts import TTFont

            font_name = 'Helvetica'
            for candidate_path, candidate_name in [
                ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'DejaVuSans'),
                ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 'DejaVu'),
            ]:
                try:
                    pdfmetrics.registerFont(TTFont(candidate_name, candidate_path))
                    font_name = candidate_name
                    break
                except Exception:
                    continue

            styles = getSampleStyleSheet()
            normal = ParagraphStyle('NormalFont', parent=styles['Normal'], fontName=font_name, fontSize=9, leading=12)
            bold_style = ParagraphStyle('BoldFont', parent=styles['Normal'], fontName=font_name, fontSize=9, leading=12)
            header_style = ParagraphStyle('HeaderFont', parent=styles['Normal'], fontName=font_name, fontSize=14, leading=18, spaceAfter=6, alignment=1)
            subheader = ParagraphStyle('SubFont', parent=styles['Normal'], fontName=font_name, fontSize=10, leading=14, textColor=colors.grey, alignment=1)
            small_style = ParagraphStyle('SmallFont', parent=styles['Normal'], fontName=font_name, fontSize=7, leading=9)

            def p(text, style=normal):
                return Paragraph(str(text) if text is not None else '', style)

            output = io.BytesIO()
            doc = SimpleDocTemplate(
                output, pagesize=A4,
                topMargin=20*mm, bottomMargin=15*mm,
                leftMargin=20*mm, rightMargin=20*mm,
            )

            elements = []

            # Title
            elements.append(Paragraph('Кассовая смена — Отчёт кассира', header_style))
            elements.append(Paragraph(
                f'Дата: {date.strftime("%d.%m.%Y")} | Кассир: {request.user.username}',
                subheader
            ))
            elements.append(Spacer(1, 6*mm))

            # Cashier info
            register_info = [['Параметр', 'Значение']]
            for reg in registers[:1]:  # Latest register
                register_info.append(['Кассир', f'{reg.cashier.username}'])
                register_info.append(['Смена открыта', reg.opened_at.strftime('%d.%m.%Y %H:%M')])
                if reg.closed_at:
                    register_info.append(['Смена закрыта', reg.closed_at.strftime('%d.%m.%Y %H:%M')])
                break

            register_info.append(['Всего операций', str(operations.count())])
            register_info.append(['Покупок', str(operations.filter(operation_type=OperationType.BUY).count())])
            register_info.append(['Продаж', str(operations.filter(operation_type=OperationType.SELL).count())])
            register_info.append(['Оборот (сом)', f'{total_turnover:.2f}'])
            register_info.append(['Покупок на сумму', f'{buy_amount:.2f} сом'])
            register_info.append(['Продаж на сумму', f'{sell_amount:.2f} сом'])

            table = Table(register_info, colWidths=[120, 300])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a73e8')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTNAME', (0, 0), (-1, -1), font_name),
                ('FONTSIZE', (0, 0), (-1, -1), 9),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#cccccc')),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ]))
            elements.append(table)
            elements.append(Spacer(1, 8*mm))

            # Operations table
            elements.append(Paragraph('Операции за день', ParagraphStyle('OpTitle', parent=normal, fontSize=12, spaceAfter=6, fontName=font_name)))

            if operations.count() == 0:
                elements.append(Paragraph('Нет операций за сегодня', normal))
            else:
                op_headers = ['№', 'Время', 'Тип', 'Валюта', 'Курс', 'Сумма', 'Итого', 'Клиент']
                op_data = [op_headers]
                for idx, op in enumerate(operations, 1):
                    op_data.append([
                        str(idx),
                        op.created_at.strftime('%H:%M'),
                        op.get_operation_type_display(),
                        op.currency.code,
                        f'{float(op.rate):.4f}',
                        f'{float(op.amount):.2f}',
                        f'{float(op.total_amount):.2f}',
                        op.client_name or '',
                    ])

                op_table = Table(op_data, colWidths=[25, 40, 45, 40, 45, 50, 50, 80])
                op_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a73e8')),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                    ('FONTNAME', (0, 0), (-1, -1), font_name),
                    ('FONTSIZE', (0, 0), (-1, -1), 8),
                    ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#cccccc')),
                    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('ALIGN', (1, 1), (-1, -1), 'CENTER'),
                ]))
                elements.append(op_table)

            # Footer
            elements.append(Spacer(1, 12*mm))
            elements.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#cccccc')))
            elements.append(Spacer(1, 3*mm))
            elements.append(Paragraph(
                f'Сформировано: {timezone.now().strftime("%d.%m.%Y %H:%M")}',
                small_style
            ))
            elements.append(Paragraph('My Exchange — Система управления обменными операциями', small_style))

            doc.build(elements)
            pdf_bytes = output.getvalue()
            output.close()

            response = HttpResponse(pdf_bytes, content_type='application/pdf')
            filename = f'cashier_shift_{date.strftime("%Y%m%d")}.pdf'
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            response['Content-Length'] = len(pdf_bytes)
            return response

        except ImportError:
            return Response(
                {"error": "Библиотека reportlab не установлена"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def export_report(self, request, export_format):
        """Export report data."""
        date = request.query_params.get('date', timezone.now().date())
        
        operations = Operation.objects.filter(
            created_at__date=date,
            status=OperationStatus.ACTIVE
        )
        
        report_data = {
            'date': str(date),
            'total_operations': operations.count(),
            'total_turnover': float(operations.aggregate(total=Sum('total_amount'))['total'] or 0),
        }
        
        if export_format == 'json':
            return Response(report_data)
        elif export_format == 'csv':
            output = io.StringIO()
            writer = csv.writer(output)
            writer.writerow(['Параметр', 'Значение'])
            for key, value in report_data.items():
                writer.writerow([key, value])
            
            response = HttpResponse(output.getvalue(), content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename="report_{date}.csv"'
            return response
        
        return Response(
            {"error": "Неподдерживаемый формат экспорта"},
            status=status.HTTP_400_BAD_REQUEST
        )
