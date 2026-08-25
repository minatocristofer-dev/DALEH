import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import 'team_detail_screen.dart';
import 'teams_providers.dart';

class CriarTimeScreen extends ConsumerStatefulWidget {
  const CriarTimeScreen({super.key});

  @override
  ConsumerState<CriarTimeScreen> createState() => _CriarTimeScreenState();
}

class _CriarTimeScreenState extends ConsumerState<CriarTimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final time = await ref.read(teamsActionsProvider).criarTime(
            name: _nomeCtrl.text.trim(),
            city: _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
            state: _estadoCtrl.text.trim().isEmpty ? null : _estadoCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: time.id)),
      );
    } on ApiException catch (e) {
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar time')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Comece pelo nome — dá pra completar o resto do perfil do time depois.',
                style: TextStyle(color: DalehColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome do time'),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Informe um nome com pelo menos 2 letras.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cidadeCtrl,
                decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _estadoCtrl,
                decoration: const InputDecoration(labelText: 'Estado (opcional)'),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 14),
                Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: 'Criar time', onPressed: _criar, carregando: _enviando),
            ],
          ),
        ),
      ),
    );
  }
}
