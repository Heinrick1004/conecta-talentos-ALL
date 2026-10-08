ConectaTalentos — PIM VII

Plataforma acadêmica de recrutamento: Web para empresas e Flutter para candidatos compartilham uma API ASP.NET Core .NET 8 e um banco SQL Server.

O aplicativo usa Dart, package:http e flutter_secure_storage. Autenticação JWT, vagas, favoritos, candidaturas, perfil e notificações utilizam dados reais da API. Capacitação apresenta conteúdo conceitual estático, sem inscrição ou progresso persistente.

Para executar a API, a partir da raiz do repositório:

```powershell
cd "Projeto_Conect_Talents/ConectaTalentos.Api"
dotnet restore
dotnet run --launch-profile http
```

Configure a conexão SQL Server e a chave JWT no `appsettings.json` local, ignorado pelo Git, usando `appsettings.example.json` como referência. A API atende em `http://localhost:5000`; Swagger em `http://localhost:5000/swagger`. O script `mySQL/ConectaTalentos_SQLServer.sql` serve para a instalação inicial e não deve ser executado novamente sobre um banco existente.

Para executar o mobile em um Android Emulator, a partir da raiz do repositório:

```powershell
cd "Projeto_Conect_Talents_Mobile/Nova pasta/conecta_talentos_app"
flutter pub get
flutter run
```

O endereço padrão da API no emulador é `http://10.0.2.2:5000`. Em outro ambiente, informe `--dart-define=API_BASE_URL=http://endereco:5000` ao executar o Flutter.

O projeto mantém `lib/models`, `lib/services`, `lib/screens`, `lib/widgets`, `lib/theme` e `lib/data`. Fixtures e fakes de testes ficam em `test/`.

Validação:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

A Web é HTML/CSS/JavaScript em `Projeto_Conect_Talents`; sirva essa pasta em `http://localhost:5500`, endereço permitido pelo CORS local da API.
