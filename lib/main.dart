import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin.dart';

// ───── core/area.dart ─────
/// Áreas disponíveis no app.
enum Area { estetica, psicologia }

extension AreaInfo on Area {
  String get nome => switch (this) {
        Area.estetica => 'Estética',
        Area.psicologia => 'Psicologia',
      };

  IconData get icone => switch (this) {
        Area.estetica => Icons.spa,
        Area.psicologia => Icons.psychology,
      };

  Color get cor => switch (this) {
        Area.estetica => const Color(0xFFD81B7A), // rosa
        Area.psicologia => const Color(0xFF3F7CAC), // azul
      };

  Color get corClara => switch (this) {
        Area.estetica => const Color(0xFFFFE3F0),
        Area.psicologia => const Color(0xFFE0EEF8),
      };
}

// ───── core/tema.dart ─────
ThemeData criarTema() => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF6C5CE7),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

/// Decoração padrão dos campos (a borda vem do tema).
InputDecoration decoracaoCampo(String label,
    {IconData? icone, Widget? sufixo, String? ajuda}) {
  return InputDecoration(
    labelText: label,
    helperText: ajuda,
    prefixIcon: icone == null ? null : Icon(icone),
    suffixIcon: sufixo,
  );
}

/// Celular (largura menor que 600 px).
bool telaEstreita(BuildContext c) => MediaQuery.sizeOf(c).width < 600;

// ───── core/formatadores.dart ─────
String doisDigitos(int n) => n.toString().padLeft(2, '0');

String formatarData(DateTime d) =>
    '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year}';

String formatarHora(DateTime d) =>
    '${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';

String formatarDataHora(DateTime d) => '${formatarData(d)} ${formatarHora(d)}';

/// Formata um valor em centavos como moeda (ex.: 15050 → "R$ 150,50").
String formatarReais(int centavos) {
  final sinal = centavos < 0 ? '-' : '';
  final abs = centavos.abs();
  return '${sinal}R\$ ${abs ~/ 100},${doisDigitos(abs % 100)}';
}

/// Converte texto digitado ("150,50" ou "150.5") em centavos.
int? parseCentavos(String texto) {
  final v = double.tryParse(texto.trim().replaceAll(',', '.'));
  if (v == null) return null;
  return (v * 100).round();
}

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Hoje, no horário informado.
DateTime hojeAs(int h, [int m = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, h, m);
}

/// Daqui a [horas] horas (negativo = no passado).
DateTime emHoras(int horas) => DateTime.now().add(Duration(hours: horas));

// ───── widgets/logo_unipora.dart ─────
/// Logo da Uniporá (com fallback se o asset não for encontrado).
class LogoUnipora extends StatelessWidget {
  const LogoUnipora({super.key, this.altura, this.larguraMax});

  final double? altura;
  final double? larguraMax;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/logo_unipora.png',
      height: altura,
      fit: BoxFit.contain,
      semanticLabel: 'Logo da Uniporá',
      errorBuilder: (context, erro, pilha) =>
          Icon(Icons.school, size: altura ?? 48),
    );
    if (larguraMax == null) return img;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: larguraMax!),
      child: img,
    );
  }
}

// ───── widgets/botao_principal.dart ─────
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.cor,
    required this.onPressed,
    this.carregando = false,
  });

  final String texto;
  final Color cor;
  final bool carregando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: carregando ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: carregando
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(texto, style: const TextStyle(fontSize: 16)),
    );
  }
}

// ───── widgets/campo_senha.dart ─────
/// Campo de senha com botão de mostrar/ocultar.
class CampoSenha extends StatefulWidget {
  const CampoSenha({
    super.key,
    required this.controller,
    this.label = 'Senha',
    this.validator,
    this.onSubmitted,
    this.novaSenha = false,
    this.ajuda,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final bool novaSenha;
  final String? ajuda;
  final TextInputAction? textInputAction;

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _oculta,
      textInputAction: widget.textInputAction,
      autofillHints: [
        widget.novaSenha ? AutofillHints.newPassword : AutofillHints.password,
      ],
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      decoration: decoracaoCampo(
        widget.label,
        icone: Icons.lock_outline,
        ajuda: widget.ajuda,
        sufixo: IconButton(
          tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
          icon: Icon(_oculta ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}

// ───── auth/validadores.dart ─────
String? validaEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
    return 'E-mail inválido';
  }
  return null;
}

/// No login só exigimos o campo preenchido (não revela a política de senha).
String? validaSenhaLogin(String? v) =>
    (v == null || v.isEmpty) ? 'Informe sua senha' : null;

/// No cadastro: mínimo de 8 caracteres, com letras e números.
String? validaSenhaNova(String? v) {
  if (v == null || v.isEmpty) return 'Crie uma senha';
  if (v.length < 8) return 'Mínimo de 8 caracteres';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'Use letras e números';
  }
  return null;
}

String? validaNome(String? v) =>
    (v == null || v.trim().length < 3) ? 'Informe seu nome completo' : null;

String? validaTelefone(String? v) {
  final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
  return digitos.length < 10 ? 'Informe um telefone válido' : null;
}

// ───── auth/telefone_formatter.dart ─────
/// Máscara (64) 99999-9999 / (64) 9999-9999.
class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue antigo, TextEditingValue novo) {
    var d = novo.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 11) d = d.substring(0, 11);
    final hifen = d.length > 10 ? 7 : 6;
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      if (i == hifen) b.write('-');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

// ───── auth/emblema.dart ─────
/// Emblema clicável (círculo com ícone + nome). Acessível por teclado e leitor de tela.
class Emblema extends StatefulWidget {
  const Emblema({super.key, required this.area, required this.onTap});

  final Area area;
  final VoidCallback onTap;

  @override
  State<Emblema> createState() => _EmblemaState();
}

class _EmblemaState extends State<Emblema> {
  bool _hover = false;
  bool _foco = false;

  bool get _ativo => _hover || _foco;

  @override
  Widget build(BuildContext context) {
    final area = widget.area;

    return Semantics(
      button: true,
      label: 'Entrar na área de ${area.nome}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _foco = v),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedScale(
            scale: _ativo ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [area.cor.withValues(alpha: 0.75), area.cor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: area.cor.withValues(alpha: _ativo ? 0.5 : 0.3),
                        blurRadius: _ativo ? 28 : 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(area.icone, size: 72, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  area.nome,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: area.cor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───── auth/cadastro_form.dart ─────
/// Cadastro de cliente.
class CadastroForm extends StatefulWidget {
  const CadastroForm({super.key, required this.area, required this.onConcluido});

  final Area area;
  final VoidCallback onConcluido;

  @override
  State<CadastroForm> createState() => _CadastroFormState();
}

class _CadastroFormState extends State<CadastroForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    // TODO: criar a conta no backend sempre com perfil "cliente" e
    // guardar a data/hora do consentimento (LGPD).
    // Contas de administrador devem ser criadas somente por você.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _carregando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro realizado! Faça seu login.')),
    );
    widget.onConcluido();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nomeCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: decoracaoCampo('Nome completo', icone: Icons.person_outline),
              validator: validaNome,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: decoracaoCampo('E-mail', icone: Icons.email_outlined),
              validator: validaEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [TelefoneFormatter()],
              decoration: decoracaoCampo('Telefone / WhatsApp', icone: Icons.phone_outlined),
              validator: validaTelefone,
            ),
            const SizedBox(height: 16),
            CampoSenha(
              controller: _senhaCtrl,
              novaSenha: true,
              textInputAction: TextInputAction.next,
              ajuda: 'Mínimo de 8 caracteres, com letras e números',
              validator: validaSenhaNova,
            ),
            const SizedBox(height: 16),
            CampoSenha(
              controller: _confirmaCtrl,
              label: 'Confirmar senha',
              novaSenha: true,
              validator: (v) => v != _senhaCtrl.text ? 'As senhas não conferem' : null,
              onSubmitted: (_) => _cadastrar(),
            ),
            const SizedBox(height: 8),
            FormField<bool>(
              initialValue: false,
              validator: (v) =>
                  v == true ? null : 'É necessário aceitar para criar a conta',
              builder: (campo) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: campo.value ?? false,
                    onChanged: campo.didChange,
                    activeColor: widget.area.cor,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Li e concordo com o tratamento dos meus dados pessoais '
                      'conforme a Política de Privacidade (LGPD).',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  if (campo.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        campo.errorText!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BotaoPrincipal(
              texto: 'Criar conta',
              cor: widget.area.cor,
              carregando: _carregando,
              onPressed: _cadastrar,
            ),
          ],
        ),
      ),
    );
  }
}

// ───── auth/login_form.dart ─────
/// Login (administrador e clientes).
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.area,
    required this.onCadastro,
    required this.onEsqueci,
  });

  final Area area;
  final VoidCallback onCadastro;
  final VoidCallback onEsqueci;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    // TODO: autenticação real (Firebase, API própria etc.).
    // O backend deve devolver o perfil (administrador ou cliente)
    // para você direcionar à tela certa.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _carregando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login de ${widget.area.nome} realizado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.area.cor;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: decoracaoCampo('E-mail', icone: Icons.email_outlined),
              validator: validaEmail,
            ),
            const SizedBox(height: 16),
            CampoSenha(
              controller: _senhaCtrl,
              validator: validaSenhaLogin,
              onSubmitted: (_) => _entrar(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onEsqueci,
                child: Text('Esqueci minha senha', style: TextStyle(color: cor)),
              ),
            ),
            const SizedBox(height: 8),
            BotaoPrincipal(
              texto: 'Entrar',
              cor: cor,
              carregando: _carregando,
              onPressed: _entrar,
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('É cliente e ainda não tem conta?'),
                TextButton(
                  onPressed: widget.onCadastro,
                  child: Text('Cadastre-se',
                      style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───── auth/recuperar_senha_form.dart ─────
/// Recuperação de senha por e-mail.
class RecuperarSenhaForm extends StatefulWidget {
  const RecuperarSenhaForm({
    super.key,
    required this.area,
    required this.onVoltarLogin,
  });

  final Area area;
  final VoidCallback onVoltarLogin;

  @override
  State<RecuperarSenhaForm> createState() => _RecuperarSenhaFormState();
}

class _RecuperarSenhaFormState extends State<RecuperarSenhaForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _carregando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    // TODO: dispare o e-mail de redefinição no backend.
    // Ex. com Firebase Auth:
    // await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _carregando = false;
      _enviado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.area.cor;

    if (_enviado) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 56, color: cor),
          const SizedBox(height: 16),
          Text(
            'Se o e-mail ${_emailCtrl.text.trim()} estiver cadastrado, '
            'você receberá em instantes um link para criar uma nova senha. '
            'Confira também a caixa de spam.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BotaoPrincipal(
            texto: 'Voltar ao login',
            cor: cor,
            onPressed: widget.onVoltarLogin,
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o e-mail da sua conta e enviaremos um link para '
            'redefinir sua senha.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: decoracaoCampo('E-mail', icone: Icons.email_outlined),
            validator: validaEmail,
            onFieldSubmitted: (_) => _enviar(),
          ),
          const SizedBox(height: 24),
          BotaoPrincipal(
            texto: 'Enviar link de recuperação',
            cor: cor,
            carregando: _carregando,
            onPressed: _enviar,
          ),
        ],
      ),
    );
  }
}

// ───── auth/formulario_login.dart ─────
/// Qual tela do fluxo de autenticação está aberta.
enum _Tela { login, cadastro, recuperar }

/// Cartão que alterna entre login, cadastro de cliente e recuperação de senha.
class FormularioLogin extends StatefulWidget {
  const FormularioLogin({super.key, required this.area, required this.onVoltar});

  final Area area;
  final VoidCallback onVoltar;

  @override
  State<FormularioLogin> createState() => _FormularioLoginState();
}

class _FormularioLoginState extends State<FormularioLogin> {
  _Tela _tela = _Tela.login;

  void _ir(_Tela t) => setState(() => _tela = t);

  String get _titulo => switch (_tela) {
        _Tela.login => 'Login ${widget.area.nome}',
        _Tela.cadastro => 'Cadastro de cliente',
        _Tela.recuperar => 'Recuperar senha',
      };

  Widget get _conteudo => switch (_tela) {
        _Tela.login => LoginForm(
            key: const ValueKey('login'),
            area: widget.area,
            onCadastro: () => _ir(_Tela.cadastro),
            onEsqueci: () => _ir(_Tela.recuperar),
          ),
        _Tela.cadastro => CadastroForm(
            key: const ValueKey('cadastro'),
            area: widget.area,
            onConcluido: () => _ir(_Tela.login),
          ),
        _Tela.recuperar => RecuperarSenhaForm(
            key: const ValueKey('recuperar'),
            area: widget.area,
            onVoltarLogin: () => _ir(_Tela.login),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final noLogin = _tela == _Tela.login;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(telaEstreita(context) ? 20 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: noLogin ? widget.onVoltar : () => _ir(_Tela.login),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(noLogin ? 'Voltar' : 'Voltar ao login'),
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 36,
                backgroundColor: area.cor,
                child: Icon(area.icone, size: 38, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                _titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: area.cor),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _conteudo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───── auth/login_page.dart ─────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Area? _areaSelecionada;

  @override
  Widget build(BuildContext context) {
    final area = _areaSelecionada;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: area == null
                ? [Area.estetica.corClara, Area.psicologia.corClara]
                : [area.corClara, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoUnipora(larguraMax: 300),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: area == null
                        ? _EscolhaArea(
                            key: const ValueKey('escolha'),
                            onSelecionar: (a) =>
                                setState(() => _areaSelecionada = a),
                          )
                        : FormularioLogin(
                            key: ValueKey(area),
                            area: area,
                            onVoltar: () =>
                                setState(() => _areaSelecionada = null),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela inicial com os dois emblemas.
class _EscolhaArea extends StatelessWidget {
  const _EscolhaArea({super.key, required this.onSelecionar});

  final ValueChanged<Area> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bem-vindo(a)',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Escolha sua área para entrar',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 40),
        Wrap(
          spacing: 32,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (final a in Area.values)
              Emblema(area: a, onTap: () => onSelecionar(a)),
          ],
        ),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminLoginPage())),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Acesso administrativo'),
        ),
      ],
    );
  }
}

// ───── main.dart ─────
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estética & Psicologia',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      home: const LoginPage(),
    );
  }
}