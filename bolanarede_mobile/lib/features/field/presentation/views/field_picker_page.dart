import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class FieldPickerPage extends ConsumerWidget {
  const FieldPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldListProvider);

    return Scaffold(
      appBar: const AppGradientAppBar(
        title: 'Selecionar Campo',
        showBackButton: true,
      ),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar campos: $e')),
        data: (fields) {
          if (fields.isEmpty) {
            return const Center(child: Text('Nenhum campo disponível.'));
          }
          return ListView.separated(
            itemCount: fields.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = fields[index];
              return ListTile(
                title: Text(f.name),
                subtitle: Text(f.city),
                onTap: () => context.pop(<String, String>{
                  'id': f.id,
                  'name': f.name,
                  'address': f.city,
                }),
              );
            },
          );
        },
      ),
    );
  }
}
