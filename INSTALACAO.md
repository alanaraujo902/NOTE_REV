# Instruções de Instalação - Card Deck App

## Pré-requisitos

### 1. Instalar Flutter
- Baixe o Flutter SDK em: https://flutter.dev/docs/get-started/install
- Siga as instruções para seu sistema operacional (Windows, macOS, Linux)
- Adicione o Flutter ao PATH do sistema

### 2. Configurar Ambiente de Desenvolvimento
- **Android Studio** (recomendado) ou **VS Code**
- **Android SDK** (para desenvolvimento Android)
- **Xcode** (apenas para macOS, desenvolvimento iOS)

### 3. Verificar Instalação
Execute no terminal:
```bash
flutter doctor
```
Certifique-se de que não há erros críticos.

## Instalação do Aplicativo

### 1. Obter o Código
O código fonte está na pasta `card_deck_app/`

### 2. Instalar Dependências
```bash
cd card_deck_app
flutter pub get
```

### 3. Executar o Aplicativo

#### Em um Emulador/Dispositivo Android:
```bash
flutter run
```

#### Para Gerar APK (Android):
```bash
flutter build apk --release
```
O APK será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

#### Para iOS (apenas macOS):
```bash
flutter build ios --release
```

## Dependências do Projeto

O aplicativo utiliza as seguintes dependências:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.0
  path: ^1.8.3
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_quill: ^9.6.0
  signature: ^5.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

## Estrutura de Arquivos

```
card_deck_app/
├── lib/
│   ├── main.dart                    # Ponto de entrada
│   ├── models/
│   │   ├── card_model.dart         # Modelo de dados
│   │   └── card_model.g.dart       # Código gerado
│   ├── database/
│   │   └── database_helper.dart    # Gerenciador SQLite
│   ├── screens/
│   │   ├── home_screen.dart        # Tela principal
│   │   └── add_edit_card_screen.dart # Tela de edição
│   ├── widgets/
│   │   └── card_widget.dart        # Widget de card
│   └── services/
│       └── image_service.dart      # Serviço de imagens
├── android/                        # Configurações Android
├── ios/                            # Configurações iOS
├── README.md                       # Documentação principal
├── INSTALACAO.md                   # Este arquivo
└── pubspec.yaml                    # Dependências
```

## Solução de Problemas

### Erro de Permissões (Android)
Se houver problemas com câmera ou galeria, verifique se as permissões estão corretas no `android/app/src/main/AndroidManifest.xml`

### Problemas de Build
1. Execute `flutter clean`
2. Execute `flutter pub get`
3. Tente novamente `flutter run`

### Problemas com Dependências
Execute:
```bash
flutter pub deps
flutter pub upgrade
```

## Funcionalidades Implementadas

✅ **Sistema de Cards com Fila**
- Criação, edição e exclusão de cards
- Sistema de fila inteligente (mais antigo primeiro)
- Botão "Visto" para marcar como revisado

✅ **Banco de Dados Local**
- Armazenamento SQLite
- Persistência de dados
- Controle de posição na fila

✅ **Suporte a Imagens**
- Seleção via câmera ou galeria
- Armazenamento local
- Visualização nos cards

✅ **Interface Intuitiva**
- Design limpo e responsivo
- Navegação simples
- Feedback visual

## Funcionalidades Futuras

🚧 **Em Desenvolvimento:**
- Editor de texto rico (formatação avançada)
- Suporte a desenho com stylus
- Categorização de cards
- Estatísticas de revisão
- Sincronização na nuvem

## Suporte

Para dúvidas ou problemas:
1. Verifique a documentação do Flutter: https://flutter.dev/docs
2. Consulte o README.md do projeto
3. Verifique se todas as dependências estão instaladas corretamente

## Licença

Este projeto é de código aberto sob licença MIT.

