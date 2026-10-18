// JDesk: tela simplificada do cliente.
// Aparece no computador do cliente: no jdesk.exe e no arquivo baixado no painel
// (jdesk-CODIGO.exe). Mostra o ID e a instrução de clicar em Aceitar; quando há
// código, mostra também o técnico e a situação do atendimento (aguardando,
// técnico conectado, encerrado). O app do técnico é o jdesk-tecnico.exe.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const kJDeskVerde = Color(0xFF0B7A75);
const kJDeskVerdeEscuro = Color(0xFF0A3B38);
const kJDeskVerdeMeio = Color(0xFF0B5E5A);
const kJDeskTexto = Color(0xFF0F1B2D);
const kJDeskTexto2 = Color(0xFF536170);
const kJDeskFundo = Color(0xFFF1F8F6);
const kJDeskBorda = Color(0xFFD9E7E3);
const kJDeskStatus = Color(0xFF15803D);
const kJDeskLaranja = Color(0xFFF59E0B);

/// Código do chamado (ex.: K7MX9QPR) quando o app veio do painel; vazio no app do técnico.
String jdeskCodigo() => bind.mainGetBuildinOption(key: 'jdesk-codigo');

bool isJDeskClientMode() =>
    bind.isIncomingOnly() &&
    (bind.mainGetBuildinOption(key: 'jdesk-cliente') == 'Y' ||
        jdeskCodigo().isNotEmpty);

/// Códigos de 8 caracteres aparecem em dois blocos (K7MX-9QPR), como no painel.
String jdeskCodigoFormatado(String c) =>
    c.length == 8 ? '${c.substring(0, 4)}-${c.substring(4)}' : c;

/// Link para abrir uma conversa no WhatsApp com o telefone informado (Brasil sem DDI ganha 55).
String jdeskWhatsapp(String telefone) {
  var d = telefone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
  if (d.isEmpty) return '';
  if (d.length == 10 || d.length == 11) d = '55$d';
  return 'https://wa.me/$d';
}

class JDeskClientPane extends StatefulWidget {
  final Key contentKey;
  final VoidCallback onResize;

  const JDeskClientPane(
      {Key? key, required this.contentKey, required this.onResize})
      : super(key: key);

  @override
  State<JDeskClientPane> createState() => _JDeskClientPaneState();
}

class _JDeskClientPaneState extends State<JDeskClientPane> {
  String _empresa = '';
  String _tecnico = '';
  String _contato = '';
  String _telefone = '';
  // "aguardando", "conectado" ou "encerrado", conforme o painel
  String _situacao = 'aguardando';
  String _tecnicoConectado = '';
  Timer? _timer;
  // Evita consultas sobrepostas quando a hospedagem do painel demora a responder.
  bool _consultando = false;

  @override
  void initState() {
    super.initState();
    // Sem código (jdesk.exe baixado direto) não há atendimento no painel para consultar.
    if (jdeskCodigo().isEmpty) return;
    _carregar();
    // A situação muda quando o técnico conecta ou desconecta: consulta o painel a cada 2 s
    // (uma consulta por vez), para o aviso "técnico conectado" aparecer logo.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _carregar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final codigo = jdeskCodigo();
    final painel = bind.mainGetBuildinOption(key: 'jdesk-painel');
    if (codigo.isEmpty || painel.isEmpty) return;
    if (_consultando) return;
    _consultando = true;
    try {
      final resp = await http
          .get(Uri.parse('$painel/api/chamado/$codigo'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;
      final dados = jsonDecode(utf8.decode(resp.bodyBytes));
      if (dados is! Map) return;
      if (!mounted) return;
      final antes = '$_empresa|$_tecnico|$_contato|$_telefone|$_situacao|$_tecnicoConectado';
      final empresa = (dados['empresa'] ?? '').toString();
      final tecnico = (dados['tecnico'] ?? '').toString();
      final contato = (dados['contato'] ?? '').toString();
      final telefone = (dados['telefone'] ?? '').toString();
      final situacao = (dados['situacao'] ?? 'aguardando').toString();
      final conectado = (dados['tecnico_conectado'] ?? '').toString();
      if (antes == '$empresa|$tecnico|$contato|$telefone|$situacao|$conectado') {
        return;
      }
      setState(() {
        _empresa = empresa;
        _tecnico = tecnico;
        _contato = contato;
        _telefone = telefone;
        _situacao = situacao;
        _tecnicoConectado = conectado;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onResize());
    } catch (e) {
      debugPrint('JDesk: dados do chamado indisponiveis: $e');
    } finally {
      _consultando = false;
    }
  }

  Future<void> _abrirWhatsapp() async {
    final link = jdeskWhatsapp(_telefone);
    if (link.isEmpty) return;
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('JDesk: nao abriu o WhatsApp: $e');
    }
  }

  Widget _faixaSituacao(bool escuro) {
    late final Color fundo;
    late final Color texto;
    late final Color ponto;
    late final String titulo;
    String? detalhe;
    final quem = _tecnicoConectado.isNotEmpty ? _tecnicoConectado : _tecnico;
    if (_situacao == 'conectado') {
      fundo = escuro ? const Color(0xFF3A2A06) : const Color(0xFFFFF4DC);
      texto = escuro ? const Color(0xFFFDE68A) : const Color(0xFF6E4700);
      ponto = kJDeskLaranja;
      titulo = quem.isEmpty
          ? 'Técnico conectado ao seu computador'
          : '$quem está conectado ao seu computador';
      detalhe = 'Você pode acompanhar tudo na tela.';
    } else if (_situacao == 'encerrado') {
      fundo = escuro ? const Color(0xFF1F2937) : const Color(0xFFEBF2F0);
      texto = escuro ? const Color(0xFFE5E7EB) : kJDeskTexto2;
      ponto = const Color(0xFF94A3B8);
      titulo = 'Atendimento encerrado';
      detalhe = 'Já pode fechar o JDesk.';
    } else {
      fundo = escuro ? const Color(0xFF11351F) : const Color(0xFFE3F5E9);
      texto = escuro ? const Color(0xFFBBF7D0) : const Color(0xFF14532D);
      ponto = kJDeskStatus;
      titulo = 'Pronto · aguardando o técnico';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: ponto, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        color: texto,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                if (detalhe != null)
                  Text(detalhe,
                      style: TextStyle(color: texto, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final corCartao = escuro ? const Color(0xFF132B29) : Colors.white;
    final corTexto = escuro ? Colors.white : kJDeskTexto;
    final corTexto2 = escuro ? const Color(0xFFA9C9C5) : kJDeskTexto2;
    final corBorda = escuro ? const Color(0xFF23403E) : kJDeskBorda;
    final nome = _contato.trim();
    final codigo = jdeskCodigo();
    final conectado = _situacao == 'conectado';
    final encerrado = _situacao == 'encerrado';
    final temWhats = jdeskWhatsapp(_telefone).isNotEmpty;

    final String subtitulo;
    if (conectado) {
      subtitulo = 'O atendimento está em andamento.';
    } else if (encerrado) {
      subtitulo = 'Obrigado! Este atendimento foi concluído.';
    } else if (codigo.isEmpty) {
      subtitulo = 'Passe o seu ID ao técnico. Quando ele se conectar, clique em Aceitar.';
    } else if (_tecnico.isEmpty) {
      subtitulo = 'O técnico já foi avisado e vai se conectar em instantes.';
    } else {
      subtitulo = 'O técnico $_tecnico já foi avisado e vai se conectar em instantes.';
    }

    final cabecalho = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kJDeskVerdeEscuro, kJDeskVerdeMeio, kJDeskVerde],
        ),
      ),
      child: Column(
        children: [
          SvgPicture.asset('assets/icon.svg', width: 60, height: 60),
          const SizedBox(height: 10),
          Text(
            _empresa.isEmpty
                ? 'GESTÃO DE SUPORTE'
                : 'SUPORTE · ${_empresa.toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFA9D8D1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            nome.isEmpty ? 'Tudo pronto!' : 'Tudo pronto, $nome!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFD3ECE8), fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );

    final cartao = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: corCartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBorda),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A0A3B38), blurRadius: 24, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          _faixaSituacao(escuro),
          const SizedBox(height: 16),
          Text('SEU ID JDESK',
              style: TextStyle(
                  color: corTexto2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          const SizedBox(height: 4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: gFFI.serverModel.serverId,
            builder: (context, value, child) => SelectableText(
              value.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: 1.5,
                  color: corTexto),
            ),
          ),
          const SizedBox(height: 4),
          Text(
              codigo.isEmpty
                  ? 'Informe este número ao técnico.'
                  : 'Só passe este número se o técnico pedir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: corTexto2, fontSize: 12)),
          const SizedBox(height: 14),
          Divider(height: 1, color: corBorda),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 22,
                  color: escuro ? const Color(0xFF5CC5BC) : kJDeskVerde),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  conectado
                      ? 'Para encerrar o acesso a qualquer momento, é só fechar o JDesk.'
                      : 'Quando aparecer o aviso, clique em Aceitar. Para encerrar o acesso a qualquer momento, é só fechar o JDesk.',
                  style: TextStyle(
                      color: escuro
                          ? const Color(0xFFCFE3DF)
                          : const Color(0xFF334155),
                      fontSize: 13,
                      height: 1.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final rodape = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (codigo.isNotEmpty)
            Text('Atendimento ',
                style: TextStyle(color: corTexto2, fontSize: 12)),
          if (codigo.isNotEmpty)
            Text(jdeskCodigoFormatado(codigo),
                style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: corTexto)),
          const Spacer(),
          if (_telefone.isNotEmpty)
            Flexible(
              child: InkWell(
                onTap: temWhats ? _abrirWhatsapp : null,
                child: Text(
                    temWhats
                        ? 'Ajuda? WhatsApp $_telefone'
                        : 'Precisa de ajuda? $_telefone',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: temWhats
                            ? (escuro ? const Color(0xFF5CC5BC) : kJDeskVerde)
                            : corTexto2,
                        decoration: temWhats ? TextDecoration.underline : null,
                        fontSize: 12)),
              ),
            ),
        ],
      ),
    );

    return Container(
      width: 380,
      color: escuro ? const Color(0xFF0C1F1E) : kJDeskFundo,
      child: SingleChildScrollView(
        child: Column(
          key: widget.contentKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            cabecalho,
            // O cartão sobe sobre o cabeçalho, como na proposta aprovada.
            Transform.translate(offset: const Offset(0, -36), child: cartao),
            Transform.translate(offset: const Offset(0, -24), child: rodape),
            Transform.translate(
              offset: const Offset(0, -20),
              child: OnlineStatusWidget(onSvcStatusChanged: widget.onResize),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho com a marca JDesk no app do técnico (no lugar do logotipo do RustDesk).
class JDeskMarcaTecnico extends StatelessWidget {
  const JDeskMarcaTecnico({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kJDeskVerdeEscuro, kJDeskVerdeMeio, kJDeskVerde],
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icon.svg', width: 40, height: 40),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JDesk',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text('GESTÃO DE SUPORTE',
                    style: TextStyle(
                        color: Color(0xFFA9D8D1),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
