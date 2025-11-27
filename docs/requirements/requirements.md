# Requisitos do Sistema

## Requisitos Funcionais

### Autenticação e Autorização

**RF001 - Login:** Firebase Auth (email/senha), sessão ativa

**RF002 - Primeiro Login:** Detecção automática, mudança obrigatória de senha (min 8 chars, especiais, números), bloqueio até conclusão

**RF003 - Permissões:**
- Usuário Básico: acesso limitado
- Operador: inventário + licenças
- Administrador: acesso completo + admin + relatórios
- Validação antes de cada ação
- Permissão especial para módulos de teste

**RF004 - Gestão por UF:** Segmentação por UF, operadores restritos à sua UF, admins cross-UF, metadados: displayName, active, testAccess

### Inventário

**RF005 - Cadastro:** Produto, descrição, valor, número de série, data de garantia, disponibilidade (presente/ausente), tipo (equipamento/mobília/veículo), localização. ID interno único

**~~RF006 - OCR~~** *(Descartado)*

**RF007 - Dashboard:** Estatísticas em tempo real (total itens, valor total, distribuição por estado, itens alto valor >R$1k, tipo, localização), navegação filtrada, atualização automática

**RF008 - Gestão:** Busca e filtros (texto livre, faixas de valor, estado, tipo, localização, datas), edição/exclusão, soft delete com lixeira, restauração (admin)

**RF009 - Exportação:** Excel com todos campos, filtros aplicados, totalizadores, registro em auditoria

### Licenças

**RF010 - Predefinidas por UF:**
- CE: ANTT, Alvará, Apólice RCF-DC, Autorização Ambiental, Cert. IBAMA, Isenção Sanitária, Bombeiros, Polícia Federal
- SP: ANTT, Alvará, Apólice RCTR-C, Cert. Regularidade, Polícia Civil, Polícia Federal, Bombeiros, Exército

**~~RF011 - Upload Inteligente~~** *(Descartado)*

**RF012 - Status Automático:** Válida (>30 dias), Próximo Vencimento (≤30 dias), Vencida (expirado). Indicadores visuais

**RF013 - Arquivos:** Storage Firebase, visualização, download, metadados para auditoria

**RF014 - Interface:** Cards visuais, indicador arquivo, edição manual datas, validação formatos, registro auditoria

### Administrativo

**RF015 - Auditoria:** Registro de todas ações (Create, Update, Delete, View, Export, Login, Logout, Duplicate, Backup, Restore) em inventário/licenças. Metadados: usuário (ID, email, displayName, UF, isAdmin), timestamp, oldData, newData, recordId, descrição. Logs imutáveis, retenção 1 ano

**RF016 - Consulta Logs:** Filtros por período, usuário, ação, módulo, UF. Exibição tabular com cores, ícones, detalhes usuário, diff alterações

**RF017 - Emails:** Notificações automáticas para licenças próximas vencimento/vencidas

**~~RF018/RF019 - OCR/DeepSeek~~** *(Descartado)*

## Requisitos Não Funcionais

### Performance

**RNF001 - Tempo:** Consulta, dashboard, exportação ≤1s

**RNF002 - Escalabilidade:** 5GB/ano, índices Firestore

**RNF003 - Limites:** Upload 10MB, logs 1 ano

### Segurança

**RNF004 - Auth:** Senha min 8 chars (maiúsculas, números, especiais), sessão expira 8h inatividade, auditoria completa, validação por requisição, primeiro login obrigatório

**RNF005 - Proteção:** HTTPS, permissões Storage, chaves API seguras, logs sanitizados, validação input

**RNF006 - Backup:** Soft delete restaurável, logs imutáveis

### Usabilidade

**RNF007 - Responsivo:** Desktop/mobile, adaptação automática, consistência visual (DesignSystem), animações suaves

**RNF008 - UX:** Erros claros, manutenção estado, undo/redo admin

### Integração

**RNF009 - APIs:** Firebase (Auth, Firestore, Storage)

**RNF010 - Formatos:** PDF, DOC, DOCX, XLS, XLSX, JPG, PNG, GIF, WEBP. Excel formatado, datas DD/MM/AAAA, valores R$ 1.234,56

## Casos de Uso

**Primeiro Login:** Login senha temporária → detecção automática → tela mudança senha (bloqueio) → validação → update Firebase Auth → marca concluído Firestore → auditoria → redireciona

**~~OCR Licença/Inventário~~** *(Descartado)*

**Auditoria:** Ação → captura contexto → registra (usuário, timestamp, ação, módulo, dados) → log imutável Firestore → admin consulta com filtros → histórico completo

---

**Nota:** OCR descartado (complexidade/custo vs benefício diário, proteção de chaves). Tecnicamente viável para implementação futura.
