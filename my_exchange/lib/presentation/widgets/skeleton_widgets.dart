import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

/// Skeleton for an operation card — mimics the layout of OperationCard
class SkeletonOperationCard extends StatelessWidget {
  const SkeletonOperationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white.withValues(alpha: 0.6),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                children: [
                  _chip(70, 24),
                  const SizedBox(width: 12),
                  _chip(60, 24),
                  const Spacer(),
                  _chip(80, 14),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _chip(100, 14),
                        const SizedBox(height: 6),
                        _chip(120, 18),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _chip(100, 20),
                      const SizedBox(height: 4),
                      _chip(70, 14),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              
              Row(
                children: [
                  _chip(120, 16),
                  const Spacer(),
                  _chip(80, 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// Skeleton for the today stats header card
class SkeletonTodayStats extends StatelessWidget {
  const SkeletonTodayStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white.withValues(alpha: 0.4),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _bar(20, 20),
                const SizedBox(width: 12),
                _bar(100, 18),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _statBox()),
                const SizedBox(width: 16),
                Expanded(child: _statBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _bar(28, 28, radius: 14),
          const SizedBox(height: 8),
          _bar(40, 16),
          const SizedBox(height: 4),
          _bar(50, 10),
          const SizedBox(height: 4),
          _bar(60, 10),
        ],
      ),
    );
  }

  Widget _bar(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for a currency card — mimics the layout of _CurrencyCard
class SkeletonCurrencyCard extends StatelessWidget {
  const SkeletonCurrencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white.withValues(alpha: 0.6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip(120, 18),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip(100, 14),
                        const SizedBox(width: 8),
                        _chip(100, 14),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _chip(40, 40, radius: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for a cash balance card — mimics the layout of _BalanceCard
class SkeletonBalanceCard extends StatelessWidget {
  const SkeletonBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white.withValues(alpha: 0.6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip(100, 16),
                    const SizedBox(height: 6),
                    _chip(140, 14),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _chip(100, 18),
                  const SizedBox(height: 4),
                  _chip(80, 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

