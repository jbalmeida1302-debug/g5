# FITGESTAO — projeto-base e atualizações individuais

## Decisão de arquitetura

O repositório do FITGESTAO é a fonte oficial do código. Cada academia terá uma instalação independente, com aplicação, banco SQLite/PostgreSQL, arquivos, configurações e ciclo de atualização próprios. Uma atualização em uma instalação não deve alterar nenhuma outra.

## Identificação e versão implementadas nesta etapa

- `app/version.py`: versão e canal da aplicação. A versão só deve ser incrementada ao preparar uma release.
- `app/installation.py`: gera e persiste um UUID exclusivo em `instance/installation.json` na primeira execução de cada instalação.
- `app/routes/system.py` e `app/templates/system/version.html`: página autenticada `/sistema/versao` com versão e identificador local.
- `instance/installation.json`, `.env` e bancos de dados são dados locais e não devem ser incluídos em pacotes do projeto-base.

## Fluxo de atualização planejado

1. Desenvolver no projeto-base.
2. Criar uma release numerada e assinada, com manifesto, hash dos arquivos e instruções de migração.
3. Publicar a release em um serviço oficial de distribuição.
4. Cada instalação consulta se existe versão compatível.
5. O administrador local escolhe quando iniciar a atualização.
6. O atualizador verifica assinatura/hash, compatibilidade, espaço e integridade do pacote.
7. Faz backup do banco, arquivos e configuração; aplica migrações versionadas; troca o código de forma atômica.
8. Executa verificações de saúde e registra o resultado. Em falha, restaura o backup.

## Segurança e limites desta etapa

Esta etapa prepara apenas a identificação e exibição da versão. Ainda não existe servidor de releases, assinatura de pacotes, botão funcional de atualização, migração automatizada nem restauração automática. Esses componentes não devem ser simulados com download de ZIP não verificado ou execução arbitrária de comandos.

O código recebido nesta versão ainda não possui gerenciamento completo de cargos/permissões nem isolamento multi-instalação automatizado. Antes de disponibilizar atualização aos clientes, será necessário restringir a gestão ao administrador da academia, preparar migrações compatíveis e testar atualização/restauração em cópias de bancos reais.

## Distribuição

Nunca incluir no pacote de release: `.env`, `instance/academia.db`, `instance/installation.json`, fotos/biometrias, logs ou backups. Cada instalação mantém esses arquivos localmente.
