# Card Deck App

Um aplicativo Flutter para criar e revisar cards de estudo com sistema de fila inteligente.

## Funcionalidades

### ✅ Implementadas
- **Sistema de Cards**: Crie cards com título e conteúdo
- **Fila Inteligente**: Cards são organizados em uma fila, sempre mostrando o mais antigo primeiro
- **Botão "Visto"**: Marca o card como revisado e o move para o final da fila
- **Banco de Dados Local**: Todos os dados são salvos localmente usando SQLite
- **Suporte a Imagens**: Adicione imagens aos cards via câmera ou galeria
- **Interface Intuitiva**: Design limpo e fácil de usar

### 🚧 Em Desenvolvimento
- **Editor de Texto Rico**: Formatação avançada (negrito, itálico, listas)
- **Desenho à Mão**: Suporte para stylus e desenho manual
- **Sincronização**: Backup e sincronização entre dispositivos

## Como Usar

### Criando um Card
1. Toque no botão "+" na tela principal
2. Digite um título para o card
3. Adicione o conteúdo do card
4. Opcionalmente, adicione uma imagem tocando em "Adicionar Imagem"
5. Toque em "Salvar"

### Revisando Cards
1. Na tela principal, você verá o card mais antigo da fila
2. Leia o conteúdo do card
3. Quando terminar de revisar, toque no botão "Visto"
4. O card será movido para o final da fila e o próximo card aparecerá

### Editando Cards
1. Na tela principal, toque no ícone de edição (lápis) no canto superior direito
2. Faça as alterações desejadas
3. Toque em "Salvar"

### Excluindo Cards
1. Na tela principal, toque no ícone de lixeira no canto superior direito
2. Confirme a exclusão

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada do aplicativo
├── models/
│   └── card_model.dart      # Modelo de dados para cards
├── database/
│   └── database_helper.dart # Gerenciamento do banco SQLite
├── screens/
│   ├── home_screen.dart     # Tela principal
│   └── add_edit_card_screen.dart # Tela de criação/edição
├── widgets/
│   └── card_widget.dart     # Widget para exibir cards
└── services/
    └── image_service.dart   # Serviço para gerenciar imagens
```

## Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento
- **SQLite**: Banco de dados local
- **image_picker**: Seleção de imagens
- **path_provider**: Acesso ao sistema de arquivos

## Instalação e Execução

### Pré-requisitos
- Flutter SDK instalado
- Android Studio ou VS Code com extensões Flutter
- Dispositivo Android/iOS ou emulador

### Passos
1. Clone o repositório
2. Execute `flutter pub get` para instalar dependências
3. Execute `flutter run` para iniciar o aplicativo

## Funcionalidades Futuras

- **Categorias**: Organize cards por categorias
- **Estatísticas**: Veja quantas vezes cada card foi revisado
- **Busca**: Encontre cards específicos rapidamente
- **Exportação**: Exporte cards para outros formatos
- **Temas**: Personalize a aparência do aplicativo

## Contribuição

Este é um projeto em desenvolvimento. Sugestões e melhorias são bem-vindas!

## Licença

Este projeto é de código aberto e está disponível sob a licença MIT.

