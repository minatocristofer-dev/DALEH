import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session_guard.dart';
import 'perfil_providers.dart';

class EditarFotoState {
  final bool enviando;
  const EditarFotoState({this.enviando = false});

  EditarFotoState copyWith({bool? enviando}) => EditarFotoState(enviando: enviando ?? this.enviando);
}

/// Ação de enviar a foto composta (rosto + camisa do DALEH) pro backend —
/// mesmo padrão de `AuthController` (estado de carregamento + mensagem de
/// erro devolvida em vez de lançada, pra tela decidir como mostrar).
class EditarFotoController extends StateNotifier<EditarFotoState> {
  final Ref _ref;
  EditarFotoController(this._ref) : super(const EditarFotoState());

  Future<String?> enviarAvatar(List<int> pngBytes) async {
    state = state.copyWith(enviando: true);
    try {
      await comSessao(_ref, (token) => _ref.read(perfilRepositoryProvider).enviarAvatar(pngBytes, token));
      _ref.invalidate(meuPerfilProvider);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      state = state.copyWith(enviando: false);
    }
  }
}

final editarFotoControllerProvider = StateNotifierProvider.autoDispose<EditarFotoController, EditarFotoState>((ref) {
  return EditarFotoController(ref);
});
