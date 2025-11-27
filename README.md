# GISTC - Sistema de Gestão de Inventário e Licenças

Este projeto foi desenvolvido como sistema de gestão para controle de inventário, notas fiscais e licenças. A aplicação utiliza Flutter com Firebase como backend e implementa controle de acesso por UF com auditoria completa de operações.

---

### Sobre o Projeto

O sistema permite o gerenciamento completo de inventário, notas fiscais e licenças, com diferentes níveis de permissão (Administrador, Operador, Usuário Básico). Inclui funcionalidades de auditoria, exportação de relatórios, controle de vencimento de licenças e gestão segmentada por Unidade Federativa.

**Estrutura de Arquivos:**

* **`lib/`**: Código-fonte principal da aplicação
  * **`core/`**: Componentes centralizados (design system, utilitários)
  * **`helpers/`**: Acesso a dados e operações CRUD
  * **`models/`**: Estruturas de dados
  * **`modules/`**: Telas e interfaces do usuário
  * **`services/`**: Lógica de negócio
* **`functions/`**: Cloud Functions do Firebase
* **`docs/`**: Documentação do projeto
* **`assets/`**: Recursos estáticos

---

### Autor

* **Nome:** X
* **Matrícula:** Y

---

### Como Executar o Projeto

Para executar a aplicação, siga os passos abaixo:

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/maestroanton/stc-unifor.git
    ```

2.  **Navegue até a pasta do projeto:**
    ```bash
    cd stc-unifor
    ```

3.  **Configure o Flutter:**
    (É necessário ter o Flutter instalado)
    ```bash
    flutter create .
    ```

4.  **Execute a aplicação no Chrome:**
    ```bash
    flutter run -d chrome
    ```

A aplicação será aberta no navegador Chrome.

---

### Documentação

* **`/docs/requirements/requirements.md`**: Contém a documentação completa dos requisitos funcionais e não-funcionais do sistema.
* **`/docs/api/api_documentation.md`**: Descreve as APIs, serviços, helpers e modelos utilizados no projeto.
* **`/docs/architecture/architecture.md`**: Detalha a arquitetura do sistema, padrões de código e fluxo de dados.
* **`/docs/validation/`**: Documentação de validação e evidências do público-alvo.

---

### Versão Deployada

Acesse a versão em produção: Z
