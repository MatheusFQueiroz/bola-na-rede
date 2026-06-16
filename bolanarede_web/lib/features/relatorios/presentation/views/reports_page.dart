import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Relatórios', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Ocupação'),
              Tab(text: 'Financeiro'),
              Tab(text: 'Canais'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOccupationTab(),
              _buildFinancialTab(),
              _buildChannelsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOccupationTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Cards resumo
          Row(
            children: [
              _SummaryCard(
                label: 'Taxa média',
                value: '78%',
                change: '-5% vs sem.',
                isPositive: false,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryCard(
                label: 'Slots disponíveis',
                value: '42',
                change: '',
                isPositive: true,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryCard(
                label: 'Slots reservados',
                value: '156',
                change: '',
                isPositive: true,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryCard(
                label: 'Taxa cancelamento',
                value: '3%',
                change: '-1% vs sem.',
                isPositive: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Gráfico de barras
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ocupação por dia da semana',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Seg',
                                'Ter',
                                'Qua',
                                'Qui',
                                'Sex',
                                'Sáb',
                                'Dom',
                              ];
                              return Text(
                                days[value.toInt()],
                                style: AppTextStyles.labelSmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: AppTextStyles.labelSmall,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _barGroup(0, 72),
                        _barGroup(1, 85),
                        _barGroup(2, 68),
                        _barGroup(3, 78),
                        _barGroup(4, 90),
                        _barGroup(5, 95),
                        _barGroup(6, 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 32,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xs),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              _SummaryCard(
                label: 'Receita bruta',
                value: 'R\$ 12.400',
                change: '+8% vs mês',
                isPositive: true,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryCard(
                label: 'Taxa plataforma',
                value: 'R\$ 744',
                change: '',
                isPositive: true,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryCard(
                label: 'Receita líquida',
                value: 'R\$ 11.656',
                change: '',
                isPositive: true,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryCard(
                label: 'Ticket médio',
                value: 'R\$ 118',
                change: '+R\$ 8 vs mês',
                isPositive: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receita por período',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final months = [
                                'Jan',
                                'Fev',
                                'Mar',
                                'Abr',
                                'Mai',
                                'Jun',
                              ];
                              return Text(
                                months[value.toInt()],
                                style: AppTextStyles.labelSmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'R\$ ${(value / 1000).toStringAsFixed(0)}k',
                                style: AppTextStyles.labelSmall,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 8000),
                            const FlSpot(1, 9200),
                            const FlSpot(2, 10500),
                            const FlSpot(3, 9800),
                            const FlSpot(4, 11200),
                            const FlSpot(5, 12400),
                          ],
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primarySurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Canal')),
                DataColumn(label: Text('Reservas')),
                DataColumn(label: Text('% do total')),
                DataColumn(label: Text('Ticket médio')),
                DataColumn(label: Text('Receita')),
              ],
              rows: [
                _channelRow('App BolaNaRede', '89', '57%', 'R\$ 120', 'R\$ 10.680'),
                _channelRow('WhatsApp', '32', '21%', 'R\$ 115', 'R\$ 3.680'),
                _channelRow('Manual', '18', '12%', 'R\$ 110', 'R\$ 1.980'),
                _channelRow('Telefone', '10', '6%', 'R\$ 100', 'R\$ 1.000'),
                _channelRow('Link', '7', '4%', 'R\$ 118', 'R\$ 826'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _channelRow(
    String channel,
    String bookings,
    String pct,
    String avgTicket,
    String revenue,
  ) {
    return DataRow(cells: [
      DataCell(Text(channel, style: AppTextStyles.bodyMedium)),
      DataCell(Text(bookings)),
      DataCell(Text(pct)),
      DataCell(Text(avgTicket)),
      DataCell(
        Text(
          revenue,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.statNumber),
            if (change.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
