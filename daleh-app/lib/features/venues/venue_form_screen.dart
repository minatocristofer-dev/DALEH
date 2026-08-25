import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import 'models/venue.dart';
import 'venues_providers.dart';

/// Um formulário só, reaproveitado por Criar e Editar Quadra — os campos são
/// exatamente os mesmos nos dois casos (CreateVenueDto/UpdateVenueDto têm o
/// mesmo conjunto de campos, só muda o que é obrigatório).
class VenueFormScreen extends ConsumerStatefulWidget {
  final Venue? quadraParaEditar;
  const VenueFormScreen({super.key, this.quadraParaEditar});

  @override
  ConsumerState<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends ConsumerState<VenueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl = TextEditingController(text: widget.quadraParaEditar?.name ?? '');
  late final _enderecoCtrl = TextEditingController(text: widget.quadraParaEditar?.address ?? '');
  late final _precoCtrl = TextEditingController(
    text: widget.quadraParaEditar?.pricePerHour != null ? widget.quadraParaEditar!.pricePerHour!.toStringAsFixed(2) : '',
  );
  late bool _coberta = widget.quadraParaEditar?.covered ?? false;
  late bool _estacionamento = widget.quadraParaEditar?.hasParking ?? false;
  late bool _bar = widget.quadraParaEditar?.hasBar ?? false;
  late bool _vestiario = widget.quadraParaEditar?.hasLockerRoom ?? false;
  late bool _alugaColete = widget.quadraParaEditar?.rentsVests ?? false;
  late bool _alugaBola = widget.quadraParaEditar?.rentsBalls ?? false;
  bool _enviando = false;
  String? _erro;

  bool get _editando => widget.quadraParaEditar != null;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _enderecoCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });

    final preco = double.tryParse(_precoCtrl.text.trim().replaceAll(',', '.'));

    try {
      if (_editando) {
        await ref.read(venuesActionsProvider).editarQuadra(
              widget.quadraParaEditar!.id,
              name: _nomeCtrl.text.trim(),
              address: _enderecoCtrl.text.trim(),
              covered: _coberta,
              hasParking: _estacionamento,
              hasBar: _bar,
              hasLockerRoom: _vestiario,
              rentsVests: _alugaColete,
              rentsBalls: _alugaBola,
              pricePerHour: preco,
            );
      } else {
        await ref.read(venuesActionsProvider).criarQuadra(
              name: _nomeCtrl.text.trim(),
              address: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
              covered: _coberta,
              hasParking: _estacionamento,
              hasBar: _bar,
              hasLockerRoom: _vestiario,
              rentsVests: _alugaColete,
              rentsBalls: _alugaBola,
              pricePerHour: preco,
            );
      }
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
      appBar: AppBar(title: Text(_editando ? 'Editar quadra' : 'Criar quadra')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome da quadra'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Informe um nome com pelo menos 2 letras.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _enderecoCtrl,
                decoration: const InputDecoration(labelText: 'Endereço (opcional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço por hora (opcional)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _coberta,
                onChanged: (v) => setState(() => _coberta = v),
                title: const Text('Quadra coberta'),
                activeThumbColor: DalehColors.turf,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _estacionamento,
                onChanged: (v) => setState(() => _estacionamento = v),
                title: const Text('Estacionamento'),
                activeThumbColor: DalehColors.turf,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _vestiario,
                onChanged: (v) => setState(() => _vestiario = v),
                title: const Text('Vestiário'),
                activeThumbColor: DalehColors.turf,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _bar,
                onChanged: (v) => setState(() => _bar = v),
                title: const Text('Bar'),
                activeThumbColor: DalehColors.turf,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _alugaColete,
                onChanged: (v) => setState(() => _alugaColete = v),
                title: const Text('Aluga colete'),
                activeThumbColor: DalehColors.turf,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _alugaBola,
                onChanged: (v) => setState(() => _alugaBola = v),
                title: const Text('Aluga bola'),
                activeThumbColor: DalehColors.turf,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: _editando ? 'Salvar' : 'Criar quadra', onPressed: _salvar, carregando: _enviando),
            ],
          ),
        ),
      ),
    );
  }
}
