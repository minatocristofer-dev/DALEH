import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import '../teams/teams_providers.dart';
import 'challenges_providers.dart';
import 'escolher_time_dialog.dart';

const _modalidades = {'FUTSAL': 'Futsal', 'SOCIETY': 'Society', 'CAMPO11': 'Campo 11'};
const _niveis = {'iniciante': 'Iniciante', 'intermediario': 'Intermediário', 'avancado': 'Avançado'};

class CriarDesafioScreen extends ConsumerStatefulWidget {
  const CriarDesafioScreen({super.key});

  @override
  ConsumerState<CriarDesafioScreen> createState() => _CriarDesafioScreenState();
}

class _CriarDesafioScreenState extends ConsumerState<CriarDesafioScreen> {
  String? _teamId;
  String? _teamNome;
  String _modalidade = 'SOCIETY';
  final _cidadeCtrl = TextEditingController();
  DateTime? _data;
  final _horaCtrl = TextEditingController();
  String _nivel = 'intermediario';
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _cidadeCtrl.dispose();
    _horaCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherTime() async {
    final teamId = await escolherTimeDialog(context, ref, titulo: 'Qual time vai desafiar?');
    if (teamId == null) return;
    final times = ref.read(meusTimesProvider).valueOrNull ?? [];
    final time = times.where((t) => t.id == teamId).toList();
    setState(() {
      _teamId = teamId;
      _teamNome = time.isNotEmpty ? time.first.name : null;
    });
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 365)),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _criar() async {
    if (_teamId == null) {
      setState(() => _erro = 'Escolha qual time vai desafiar.');
      return;
    }
    if (_cidadeCtrl.text.trim().isEmpty || _data == null || _horaCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha cidade, data e horário.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(challengesActionsProvider).criarDesafio(
            teamId: _teamId!,
            modalidade: _modalidade,
            city: _cidadeCtrl.text.trim(),
            scheduledDate: _data!.toIso8601String(),
            scheduledTime: _horaCtrl.text.trim(),
            desiredLevel: _nivel,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar desafio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _escolherTime,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'TIME ORGANIZADOR'),
                child: Text(_teamNome ?? 'Escolher time'),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _modalidade,
              decoration: const InputDecoration(labelText: 'MODALIDADE'),
              items: _modalidades.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _modalidade = v ?? _modalidade),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _cidadeCtrl,
              decoration: const InputDecoration(labelText: 'CIDADE'),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _escolherData,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'DATA'),
                child: Text(_data == null
                    ? 'Escolher data'
                    : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}'),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _horaCtrl,
              decoration: const InputDecoration(labelText: 'HORÁRIO (ex: 20:00)'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _nivel,
              decoration: const InputDecoration(labelText: 'NÍVEL DESEJADO'),
              items: _niveis.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _nivel = v ?? _nivel),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Criar desafio', onPressed: _criar, carregando: _enviando),
          ],
        ),
      ),
    );
  }
}
