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

## Compilar

1. Settings > Secrets and variables > Actions > New repository secret
   - Nome: `RS_PUB_KEY`
   - Valor: o conteúdo de `/opt/rustdesk/data/id_ed25519.pub` do servidor
2. Actions > "J Desk - Windows" > Run workflow
   - Opcional: variável `JDESK_PAINEL` com o endereço do painel (padrao: `https://jdesk.fc3consultoria.com.br`).
   - Opcional: em Settings > Secrets and variables > Actions > aba Variables, crie `JDESK_SERVER` com o dominio do servidor (padrao: `suporte.fc3consultoria.com.br`). Trocar de dominio = mudar essa variavel e recompilar.
3. Ao terminar (cerca de 1h), baixe o artefato `jdesk-windows-x64`, que contém o `jdesk.exe`.

## Licença

AGPL-3.0, a mesma do RustDesk. O código-fonte desta versão é este repositório.
