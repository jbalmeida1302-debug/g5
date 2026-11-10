# Perfil da academia — implementação

## Arquivos adicionados
- `app/routes/academy.py`: rota protegida por login para visualizar e salvar o perfil.
- `app/templates/academy/profile.html`: formulário cadastral.

## Arquivos alterados
- `app/models.py`: modelo `AcademyProfile`.
- `app/forms.py`: formulário `AcademyProfileForm`.
- `app/__init__.py`: registro do blueprint `academy`.
- `app/templates/base.html`: atalho independente no canto superior direito.
- `app/static/css/style.css`: estilos do atalho e formulário.

## Campos disponíveis
Nome fantasia, razão social, CNPJ, telefone, e-mail, site, Instagram e endereço completo.

## Observação importante sobre múltiplas academias
A versão recebida ainda não possui estrutura multiempresa (`academy_id`) nem separação dos alunos, planos, pagamentos e usuários por academia. Por isso, esta implementação salva um único perfil por instalação do FITGESTAO (registro de ID 1). Ela não deve ser interpretada como isolamento multi-tenant. Para permitir várias academias na mesma instalação com segurança, será necessária uma etapa estrutural separada que associe todos os registros à academia e aplique essa separação em todas as consultas e operações.

## Migração
O projeto já executa `db.create_all()` na inicialização. A nova tabela `academy_profile` será criada sem apagar as tabelas existentes. Nenhuma alteração manual no banco é necessária para esta funcionalidade.

## Testes realizados
- Compilação sintática de todos os 17 arquivos Python: aprovada.
- Teste de inicialização/rotas do Flask: não executado neste ambiente, pois as dependências Flask/SQLAlchemy/Flask-WTF não estão instaladas.
