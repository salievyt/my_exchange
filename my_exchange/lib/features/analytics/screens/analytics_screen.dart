import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardCard(
              title: 'Общая статистика',
              icon: Icons.dashboard,
              children: [
                _StatRow(label: 'Операций сегодня', value: '0'),
                const Divider(),
                _StatRow(label: 'Оборот (сом)', value: '0.00'),
                const Divider(),
                _StatRow(label: 'Прибыль', value: '0.00'),
              ],
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              title: 'Популярные валюты',
              icon: Icons.currency_exchange,
              children: [
                _CurrencyStatRow(code: 'USD', name: 'Доллар США', count: 0),
                const Divider(),
                _CurrencyStatRow(code: 'EUR', name: 'Евро', count: 0),
                const Divider(),
                _CurrencyStatRow(
                  code: 'RUB',
                  name: 'Российский рубль',
                  count: 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              title: 'Кассиры',
              icon: Icons.people,
              children: [
                _CashierStatRow(name: '—', operations: 0, amount: '0.00'),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: AppColors.info),
                    const SizedBox(height: 16),
                    const Text(
                      'Аналитика загружается',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Здесь будет отображаться статистика по операциям, прибыли и работе кассиров',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CurrencyStatRow extends StatelessWidget {
  final String code;
  final String name;
  final int count;

  const _CurrencyStatRow({
    required this.code,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Text(
            '$count оп.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CashierStatRow extends StatelessWidget {
  final String name;
  final int operations;
  final String amount;

  const _CashierStatRow({
    required this.name,
    required this.operations,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0] : '—',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$operations оп.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
