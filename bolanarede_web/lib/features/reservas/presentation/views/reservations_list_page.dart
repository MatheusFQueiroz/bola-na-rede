import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/reservas/domain/entities/reservation.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class ReservationsListPage extends StatefulWidget {
  const ReservationsListPage({super.key});

  @override
  State<ReservationsListPage> createState() => _ReservationsListPageState();
}

class _ReservationsListPageState extends State<ReservationsListPage> {
  final _searchController = TextEditingController();

  String _searchQuery = '';
  ReservationStatus? _statusFilter;
  ReservationChannel? _channelFilter;

  // Paginação
  int _currentPage = 1;
  static const int _pageSize = 8;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Reservation> get _filtered {
    var result = MockData.reservations.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((r) => r.bookerSnapshot.name.toLowerCase().contains(q))
          .toList();
    }

    if (_statusFilter != null) {
      result = result.where((r) => r.status == _statusFilter).toList();
    }

    if (_channelFilter != null) {
      result = result.where((r) => r.channel == _channelFilter).toList();
    }

    // Ordena por data decrescente
    result.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.startTime.compareTo(a.startTime);
    });

    return result;
  }

  List<Reservation> get _paginated {
    final all = _filtered;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= all.length) return [];
    return all.sublist(start, (start + _pageSize).clamp(0, all.length));
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999);

  bool get _hasActiveFilters =>
      _statusFilter != null ||
      _channelFilter != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = null;
      _channelFilter = null;
      _currentPage = 1;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _statusLabel(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return 'Pendente';
      case ReservationStatus.confirmed:
        return 'Confirmado';
      case ReservationStatus.cancelled:
        return 'Cancelado';
      case ReservationStatus.completed:
        return 'Concluído';
      case ReservationStatus.noShow:
        return 'No-show';
    }
  }

  String _channelLabel(ReservationChannel c) {
    switch (c) {
      case ReservationChannel.bolanarededbApp:
        return 'App';
      case ReservationChannel.manual:
        return 'Manual';
      case ReservationChannel.whatsapp:
        return 'WhatsApp';
      case ReservationChannel.phone:
        return 'Telefone';
      case ReservationChannel.link:
        return 'Link';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final paginated = _paginated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Text('Reservas', style: AppTextStyles.titleLarge),
            ),
            AppButton.primary(
              label: '+ Nova Reserva',
              icon: PhosphorIcons.plus(),
              width: 180,
              onPressed: () => context.go(AppRoutes.reservationNew),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Filtros
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Busca por nome
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome do cliente...',
                        prefixIcon: Icon(
                          PhosphorIcons.magnifyingGlass(),
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  PhosphorIcons.x(),
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _currentPage = 1;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      onChanged: (v) => setState(() {
                        _searchQuery = v;
                        _currentPage = 1;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Filtro de status
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<ReservationStatus?>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os status'),
                        ),
                        ...ReservationStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _statusFilter = v;
                        _currentPage = 1;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Filtro de canal
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<ReservationChannel?>(
                      value: _channelFilter,
                      decoration: InputDecoration(
                        labelText: 'Canal',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os canais'),
                        ),
                        ...ReservationChannel.values.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(_channelLabel(c)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _channelFilter = v;
                        _currentPage = 1;
                      }),
                    ),
                  ),

                  if (_hasActiveFilters) ...[
                    const SizedBox(width: AppSpacing.md),
                    AppButton.outline(
                      label: 'Limpar filtros',
                      icon: PhosphorIcons.funnel(),
                      width: 160,
                      height: AppSizes.buttonHeightSmall,
                      onPressed: _clearFilters,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Resumo dos resultados
              Row(
                children: [
                  Text(
                    '${filtered.length} reserva(s) encontrada(s)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Filtros ativos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Tabela
        AppCard(
          padding: EdgeInsets.zero,
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          PhosphorIcons.calendarBlank(),
                          size: 48,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Nenhuma reserva encontrada',
                          style: AppTextStyles.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _hasActiveFilters
                              ? 'Tente ajustar ou limpar os filtros'
                              : 'Crie a primeira reserva para começar',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppButton.outline(
                            label: 'Limpar filtros',
                            width: 160,
                            height: AppSizes.buttonHeightSmall,
                            onPressed: _clearFilters,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1100,
                    child: DataTable(
                      // Aumenta a altura mínima de cada linha para
                      // evitar overflow em células com duas linhas de texto
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(label: Text('Data/Hora')),
                        DataColumn(label: Text('Campo/Quadra')),
                        DataColumn(label: Text('Cliente')),
                        DataColumn(label: Text('Canal')),
                        DataColumn(label: Text('Valor')),
                        DataColumn(label: Text('Pgto')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: paginated.map((r) {
                        final fieldName = MockData.fields
                                .where((f) => f.id == r.fieldId)
                                .firstOrNull
                                ?.name ??
                            r.fieldId;

                        final courtName = r.courtId != null
                            ? (MockData.courts[r.fieldId] ?? [])
                                .where((c) => c.id == r.courtId)
                                .firstOrNull
                                ?.name
                            : null;

                        return DataRow(
                          cells: [
                            // Data/Hora — texto em linha única com quebra suave
                            DataCell(
                              Text(
                                '${_formatDate(r.date)}\n${r.startTime}–${r.endTime}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Campo/Quadra — usa RichText para evitar Column
                            DataCell(
                              courtName != null
                                  ? Text(
                                      '$fieldName\n$courtName',
                                      style: AppTextStyles.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    )
                                  : Text(
                                      fieldName,
                                      style: AppTextStyles.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),

                            DataCell(
                              Text(
                                r.bookerSnapshot.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(ChannelBadge(channel: r.channel)),
                            DataCell(
                              Text(
                                'R\$ ${r.price.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              PaymentBadge(status: r.paymentStatus),
                            ),
                            DataCell(StatusBadge(status: r.status)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      PhosphorIcons.eye(),
                                      size: 16,
                                    ),
                                    tooltip: 'Ver detalhes',
                                    onPressed: () => context.go(
                                      '/dashboard/reservations/${r.id}',
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      PhosphorIcons.pencilSimple(),
                                      size: 16,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Paginação
        if (_totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.caretLeft()),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              ...List.generate(_totalPages, (i) {
                final page = i + 1;
                final isActive = page == _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _currentPage = page),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            isActive ? AppColors.primary : null,
                        foregroundColor:
                            isActive ? AppColors.textOnPrimary : null,
                      ),
                      child: Text('$page'),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: Icon(PhosphorIcons.caretRight()),
                onPressed: _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}