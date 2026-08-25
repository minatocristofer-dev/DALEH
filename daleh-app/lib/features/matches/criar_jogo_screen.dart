import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import 'jogo_detail_screen.dart';
import 'matches_providers.dart';

const _modalidades = {'FUTSAL': 'Futsal', 'SOCIETY': 'Society', 'CAMPO11': 'Campo 11'};

class CriarJogoScreen extends ConsumerStatefulWidget {
  const CriarJogoScreen({super.key});

  @override
  ConsumerState<CriarJogoScreen> createState() => _CriarJogoScreenState();
}

class _CriarJogoScreenState extends ConsumerState<CriarJogoScreen> {
  String _modalidade = 'SOCIETY';
  DateTime? _data;
  TimeOfDay? _hora;
  final _maxPlayersCtrl = TextEditingController();
  bool _privada = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _maxPlayersCtrl.dispose();
    super.dispose();
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

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (escolhida != null) setState(() => _hora = escolhida);
  }

  Future<void> _criar() async {
    if (_data == null || _hora == null) {
      setState(() => _erro = 'Escolha a data e o horário do jogo.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });

    final scheduledAt = DateTime(_data!.year, _data!.month, _data!.day, _hora!.hour, _hora!.minute);
    final maxPlayers = int.tryParse(_maxPlayersCtrl.text.trim());

    try {
      final partida = await ref.read(matchesActionsProvider).criarPartida(
            modalidade: _modalidade,
            scheduledAt: scheduledAt.toIso8601String(),
            maxPlayers: maxPlayers,
            visibility: _privada ? 'private' : 'public',
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => JogoDetailScreen(matchId: partida.id)),
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
      appBar: AppBar(title: const Text('Criar jogo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Jogo avulso — sem time nem quadra vinculados por enquanto.',
              style: TextStyle(color: DalehColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _modalidade,
              decoration: const InputDecoration(labelText: 'MODALIDADE'),
              items: _modalidades.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _modalidade = v ?? _modalidade),
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
            InkWell(
              onTap: _escolherHora,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'HORÁRIO'),
                child: Text(_hora == null ? 'Escolher horário' : _hora!.format(context)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _maxPlayersCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidade máxima (opcional)'),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _privada,
              onChanged: (v) => setState(() => _privada = v),
              title: const Text('Jogo privado'),
              subtitle: const Text(
                'Só quem está envolvido consegue ver — sem isso, qualquer um encontra o jogo.',
                style: TextStyle(fontSize: 12),
              ),
              activeThumbColor: DalehColors.turf,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Criar jogo', onPressed: _criar, carregando: _enviando),
          ],
        ),
      ),
    );
  }
}
