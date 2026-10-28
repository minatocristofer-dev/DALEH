import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../theme/daleh_theme.dart';
import '../perfil/perfil_publico_screen.dart';
import 'models/parca.dart';
import 'parcas_providers.dart';

/// Busca de jogador pra seguir — por nome/apelido (parcial) ou e-mail
/// (precisa ser exato, ver `FollowsService.buscar` no backend). Aberta a
/// partir do ícone de busca em `ParcasScreen`, porque a aba Parças sozinha
/// só mostra quem você já segue/quem te segue, sem nenhum jeito de achar
/// gente nova.
class BuscarJogadoresScreen extends ConsumerStatefulWidget {
  const BuscarJogadoresScreen({super.key});

  @override
  ConsumerState<BuscarJogadoresScreen> createState() => _BuscarJogadoresScreenState();
}

class _BuscarJogadoresScreenState extends ConsumerState<BuscarJogadoresScreen> {
  final _controlador = TextEditingController();
  bool _buscando = false;
  String? _erro;
  List<Parca>? _resultados;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final termo = _controlador.text.trim();
    if (termo.length < 2) {
      setState(() {
        _erro = 'Digite pelo menos 2 letras.';
        _resultados = null;
      });
      return;
    }
    setState(() {
      _buscando = true;
      _erro = null;
    });
    try {
      final resultados = await ref.read(parcasActionsProvider).buscar(termo);
      if (!mounted) return;
      setState(() => _resultados = resultados);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _alternarSeguir(int indice) async {
    final parca = _resultados![indice];
    try {
      if (parca.jaSegue) {
        await ref.read(parcasActionsProvider).deixarDeSeguir(parca.id);
      } else {
        await ref.read(parcasActionsProvider).seguir(parca.id);
      }
      if (!mounted) return;
      setState(() {
        _resultados![indice] = Parca(
          id: parca.id,
          fullName: parca.fullName,
          nickname: parca.nickname,
          avatarUrl: parca.avatarUrl,
          jaSegue: !parca.jaSegue,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controlador,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _buscar(),
          decoration: const InputDecoration(
            hintText: 'Nome, apelido ou e-mail',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _buscando ? null : _buscar),
        ],
      ),
      body: _buildCorpo(),
    );
  }

  Widget _buildCorpo() {
    if (_buscando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DalehSpacing.xl),
          child: Text(_erro!, style: const TextStyle(color: DalehColors.danger), textAlign: TextAlign.center),
        ),
      );
    }
    final resultados = _resultados;
    if (resultados == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DalehSpacing.xl),
          child: Text(
            'Busque por nome, apelido ou e-mail de um jogador pra seguir.',
            style: TextStyle(color: DalehColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (resultados.isEmpty) {
      return const EmptyState(icon: Icons.search_off, titulo: 'Ninguém encontrado', subtitulo: 'Confere se digitou certo.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(DalehSpacing.lg),
      itemCount: resultados.length,
      separatorBuilder: (_, _) => const SizedBox(height: DalehSpacing.sm),
      itemBuilder: (context, i) {
        final parca = resultados[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CrestAvatar(url: parca.avatarUrl, nome: parca.nomeExibido, tamanho: 40),
            title: Text(parca.nomeExibido, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: parca.nickname != null ? Text(parca.fullName, style: const TextStyle(fontSize: 12)) : null,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: parca.id))),
            trailing: OutlinedButton(
              onPressed: () => _alternarSeguir(i),
              child: Text(parca.jaSegue ? 'SEGUINDO' : 'SEGUIR'),
            ),
          ),
        );
      },
    );
  }
}
