# J Desk

Cliente de acesso remoto J Desk, da FC3 Consultoria, baseado no [RustDesk](https://github.com/rustdesk/rustdesk) (AGPL-3.0).

## Alterações em relação ao RustDesk original

- `src/common.rs`: `apply_jdesk_builtin()` fixa o nome do app (JDesk), o servidor `suporte.fc3consultoria.com.br` (ID e relay) e a chave pública, e oculta as configurações de servidor e proxy.
- `Cargo.toml` e `flutter/windows/runner/Runner.rc`: nome do produto, descrição e `jdesk.exe`.
- Ícones em `res/` e `flutter/windows/runner/resources/app_icon.ico`, e `flutter/assets/icon.svg`.
- `.github/workflows/jdesk-windows.yml`: compila só o Windows x64 e entrega o `jdesk.exe`.
- Integração com o painel de atendimentos:
  - `src/common.rs`: `api-server` fixo no endereço do painel (`JDESK_PAINEL`), aceite com um clique como padrão (`approve-mode=click`) e `jdesk_codigo()`, que lê o código do chamado no nome do arquivo (`jdesk-4F7K.exe`).
  - `src/hbbs_http/sync.rs`: o sinal de vida (`/api/heartbeat`) e as informações do computador (`/api/sysinfo`) levam o código, e só são enviados quando o arquivo tem código. As conexões são avisadas em `/api/audit/conn` pelo próprio RustDesk.

- **Modo pelo nome do arquivo** (`src/common.rs`, `apply_jdesk_builtin()` e `jdesk_modo_tecnico()`): o mesmo programa vira
  - **cliente** (só recebe conexões, tela simplificada): `jdesk.exe` e `jdesk-CODIGO.exe`;
  - **técnico** (app completo): `jdesk-tecnico.exe`. Depois de aberto uma vez como técnico, o computador fica lembrado como técnico (opção local `jdesk-tecnico`), inclusive se instalado. No Mac, por enquanto, é sempre técnico.
  - O workflow do Windows entrega os dois arquivos no artefato `jdesk-windows-x64`.
- Idioma padrão português (`lang = pt-br`) quando a pessoa não escolheu outro, mesmo com o sistema em inglês.
- Tela do cliente (`flutter/lib/desktop/pages/jdesk_client_pane.dart`): igual no `jdesk.exe` e no `jdesk-CODIGO.exe`; sem código, pede para informar o ID ao técnico e não consulta o painel. Com código: consulta `GET /api/chamado/CODIGO` a cada 2 s (uma consulta por vez) e mostra a situação real do atendimento (aguardando o técnico, técnico conectado ou encerrado), o código no formato K7MX-9QPR e o WhatsApp de ajuda como link.
- Janela de conexão (a que pede "Aceitar"): cores do J Desk e aberta no centro da tela, por cima da janela do J Desk, em vez de no canto direito (`main.dart`, `models/chat_model.dart`, `desktop/pages/server_page.dart`).
- App do técnico: cabeçalho com a marca J Desk no lugar do logotipo (`desktop_home_page.dart`).

## Compilar

1. Settings > Secrets and variables > Actions > New repository secret
   - Nome: `RS_PUB_KEY`
   - Valor: o conteúdo de `/opt/rustdesk/data/id_ed25519.pub` do servidor
2. Actions > "J Desk - Windows" > Run workflow
   - Opcional: variável `JDESK_PAINEL` com o endereço do painel (padrao: `https://jdesk.fc3consultoria.com.br`).
   - Opcional: em Settings > Secrets and variables > Actions > aba Variables, crie `JDESK_SERVER` com o dominio do servidor (padrao: `suporte.fc3consultoria.com.br`). Trocar de dominio = mudar essa variavel e recompilar.
3. Ao terminar (cerca de 1h), baixe o artefato `jdesk-windows-x64`, que contém o `jdesk.exe` (clientes) e o `jdesk-tecnico.exe` (técnicos).

## Mac (Apple Silicon)

- `.github/workflows/jdesk-macos.yml` ("J Desk - macOS (Apple Silicon)"): compila para Mac com chip Apple (M1 a M4) e entrega `jdesk-macos-apple-silicon.dmg`.
- A marca do Mac é aplicada só durante a compilação: nome do app `JDesk.app`, link `jdesk://` no `Info.plist` e ícone gerado a partir de `res/icon.png`.
- Sai **sem assinatura da Apple** (uso dos técnicos). Na primeira abertura: botão direito no app > Abrir > Abrir. Para distribuir a clientes, falta a conta Apple Developer (assinatura + notarização).

## Licença

AGPL-3.0, a mesma do RustDesk. O código-fonte desta versão é este repositório.
