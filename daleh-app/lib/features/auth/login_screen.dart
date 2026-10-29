import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/daleh_wordmark.dart';
import '../../shared/widgets/google_g_icon.dart';
import '../../theme/daleh_theme.dart';
import '../support/fale_conosco_screen.dart';
import 'auth_controller.dart';

/// Tela de login — reproduz a identidade visual aprovada (fundo de estádio
/// noturno em tela cheia, wordmark + slogan centralizados, formulário com
/// "Manter conectado" e recuperação de senha). Único ponto de entrada sem
/// sessão — `_Raiz` (`app.dart`) monta este widget como Scaffold próprio,
/// fora do card compartilhado com o Cadastro (que continua com o layout
/// antigo, fora do escopo desta tela).
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onIrParaCadastro;
  const LoginScreen({super.key, required this.onIrParaCadastro});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  String? _erro;
  bool _senhaVisivel = false;
  bool _manterConectado = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() => _erro = null);
    final erro = await ref.read(authControllerProvider.notifier).login(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
          manterConectado: _manterConectado,
        );
    if (!mounted) return;
    if (erro != null) setState(() => _erro = erro);
  }

  @override
  Widget build(BuildContext context) {
    final carregando = ref.watch(authControllerProvider).carregando;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _FundoEstadio(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: DalehSpacing.xxl, vertical: DalehSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: DalehSpacing.xl),
                      Center(
                        child: Column(
                          children: [
                            const DalehWordmark(size: 48),
                            const SizedBox(height: DalehSpacing.sm),
                            Text(
                              'CADA JOGO CONSTRÓI SUA HISTÓRIA.',
                              style: TextStyle(
                                color: DalehColors.text.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DalehSpacing.xxl * 1.5),
                      const Text(
                        'Bem-vindo de volta',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: DalehColors.text, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: DalehSpacing.xs),
                      Text(
                        'Acesse sua conta para continuar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: DalehColors.text.withValues(alpha: 0.65), fontSize: 14),
                      ),
                      const SizedBox(height: DalehSpacing.xxl),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: DalehSpacing.md),
                      TextField(
                        controller: _senhaCtrl,
                        obscureText: !_senhaVisivel,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => carregando ? null : _entrar(),
                        decoration: InputDecoration(
                          hintText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: DalehSpacing.sm),
                        Text(_erro!, style: const TextStyle(color: DalehColors.danger, fontSize: 13)),
                      ],
                      const SizedBox(height: DalehSpacing.md),
                      // `Wrap` em vez de `Row(spaceBetween)` — em telas estreitas
                      // "Manter conectado" + "Esqueci minha senha" não cabem numa
                      // linha só (achado real: estourava 52px num Pixel pequeno
                      // simulado); aqui o segundo item desce pra linha de baixo
                      // em vez de cortar/estourar.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: DalehSpacing.sm,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _manterConectado = !_manterConectado),
                            borderRadius: BorderRadius.circular(DalehRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _manterConectado,
                                    onChanged: (v) => setState(() => _manterConectado = v ?? true),
                                    activeColor: DalehColors.turf,
                                    checkColor: DalehColors.bg,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const SizedBox(width: DalehSpacing.xs),
                                  const Text('Manter conectado', style: TextStyle(color: DalehColors.text, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            // Ainda não existe recuperação de senha self-service (nem
                            // backend, nem envio de e-mail) — em vez de simular um
                            // fluxo que não faz nada, encaminha pro Fale Conosco de
                            // verdade, que já funciona.
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaleConoscoScreen())),
                            child: const Text(
                              'Esqueci minha senha',
                              style: TextStyle(
                                color: DalehColors.turf,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: DalehColors.turf,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DalehSpacing.xl),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: carregando ? null : _entrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DalehColors.turf,
                            foregroundColor: DalehColors.bg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DalehRadius.pill)),
                          ),
                          child: carregando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: DalehColors.bg),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: DalehSpacing.xl),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: DalehColors.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: DalehSpacing.md),
                            child: Text('ou', style: TextStyle(color: DalehColors.text.withValues(alpha: 0.5), fontSize: 13)),
                          ),
                          const Expanded(child: Divider(color: DalehColors.line)),
                        ],
                      ),
                      const SizedBox(height: DalehSpacing.xl),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).entrarComGoogle(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: DalehColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DalehRadius.pill)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GoogleGIcon(size: 20),
                              SizedBox(width: 12),
                              Text('Continuar com Google', style: TextStyle(color: DalehColors.text, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DalehSpacing.xl),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Não tem conta? ', style: TextStyle(color: DalehColors.text.withValues(alpha: 0.65), fontSize: 13)),
                            GestureDetector(
                              onTap: widget.onIrParaCadastro,
                              child: const Text(
                                'Criar conta',
                                style: TextStyle(
                                  color: DalehColors.turf,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationColor: DalehColors.turf,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DalehSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fundo "estádio de futebol noturno" — não existe nenhuma foto sem texto
/// nos assets do projeto (as únicas fotos de estádio que existem já têm
/// título/tagline do onboarding desenhados em cima). Em vez de usar uma
/// imagem errada, reproduz o efeito com gradientes: dois clarões suaves nos
/// cantos superiores (holofotes) + uma linha diagonal lima discreta perto
/// da base (referência ao gramado) sobre o fundo quase preto da marca. Pode
/// ser trocado por uma foto de verdade sem sem mexer no resto da tela — é
/// só substituir este widget.
class _FundoEstadio extends StatelessWidget {
  const _FundoEstadio();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DalehColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _clarao(220),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: _clarao(260),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            right: -40,
            height: 160,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      DalehColors.turf.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clarao(double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent],
        ),
      ),
    );
  }
}
