# Ambiente de desenvolvimento no Windows (Bloco 3)

Este é o roteiro da máquina principal de desenvolvimento — **Windows x64**, onde acontece
o trabalho de UI com emulador e hot reload (Fase 5+). Os outros dois ambientes têm cada um
o seu caminho e **não** são cobertos aqui:

| Ambiente | Para quê | Como se monta |
|---|---|---|
| **Windows** (este doc) | UI, emulador, hot reload, aparelho físico | passos abaixo |
| **Sessão de nuvem (Linux)** | `desmalha_core`, testes, `analyze`, APK debug | `bash tool/setup_env.sh` |
| **Codemagic** | iOS em simulador e build de release | `codemagic.yaml` |

O `tool/setup_env.sh` **é só do Linux** — não tem equivalente em PowerShell de propósito:
no Windows o Android SDK vem do instalador do Android Studio, que é o mesmo caminho que a
máquina precisaria de qualquer jeito para ter emulador e depurador. O que existe para os
três ambientes é o **verificador**, e é ele que diz se a instalação ficou correta:

```powershell
fvm dart run tool/verificar_ambiente.dart --android
```

> ⚠️ **A versão do Flutter não muda aqui.** O pin vive no `.fvmrc` (hoje **3.44.7**) e só
> muda por decisão explícita registrada no board. Instalar "o Flutter mais novo" e deixar o
> Android Studio apontar para ele é exatamente a divergência silenciosa que o verificador
> existe para pegar.

---

## 1. O que instalar

| Item | Versão | Observação |
|---|---|---|
| Git para Windows | atual | habilite **suporte a caminhos longos** no instalador |
| **JDK 17** (Temurin) | 17.x | major 17 exata — o Gradle do projeto compila com `sourceCompatibility 17` |
| Android Studio | atual | traz Android SDK, emulador e Device Manager |
| **FVM** | atual | `dart pub global activate fvm`, ou `choco install fvm` |

Não instale o Flutter "solto" pelo instalador oficial: quem gerencia a versão é o FVM, a
partir do `.fvmrc`. Se você já tem um Flutter avulso no `PATH`, ou remova-o, ou aceite o
aviso que o verificador vai dar sobre o `PATH` divergir do pin.

## 2. Variáveis de ambiente

O Android Studio instala o SDK em `%LOCALAPPDATA%\Android\Sdk`. Defina, no perfil do
usuário (Painel de Controle → *Editar variáveis de ambiente para sua conta*):

```
JAVA_HOME      = C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot
ANDROID_HOME   = C:\Users\<voce>\AppData\Local\Android\Sdk
```

E acrescente ao `Path` do usuário:

```
%JAVA_HOME%\bin
%ANDROID_HOME%\platform-tools
%LOCALAPPDATA%\Pub\Cache\bin        (onde o `dart pub global activate` põe o fvm)
```

Feche e reabra o terminal — variável de ambiente não se propaga para janela já aberta.

## 3. Flutter pinado, pelo FVM

Do diretório raiz do repositório:

```powershell
fvm install          # lê o .fvmrc e baixa exatamente 3.44.7
fvm flutter --version
```

Depois, aponte o Flutter para o SDK do Android e aceite as licenças:

```powershell
fvm flutter config --android-sdk "$env:ANDROID_HOME"
fvm flutter doctor --android-licenses
```

## 4. Componentes do Android SDK

As versões **não** são escolha livre: são as que o Flutter 3.44.7 declara, e são as mesmas
constantes do `tool/setup_env.sh` (`ANDROID_PLATFORM`, `BUILD_TOOLS`, `NDK_VERSION`). Pelo
SDK Manager do Android Studio, ou pela linha de comando:

```powershell
$sdkmanager = "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat"
& $sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"
```

O **NDK** parece dispensável agora e não é: o SQLCipher entra na Fase 4 e é código nativo.
Sem ele o build quebra no meio da tarefa, e não aqui, onde é barato resolver.

## 5. Android Studio apontando para o SDK pinado

Este é o ponto onde FVM e IDE se desencontram com mais frequência. O plugin do Flutter no
Android Studio **não** passa pelo `fvm`: ele usa o caminho configurado na IDE e o
`local.properties` do módulo Android (que é gerado e fica fora do versionamento).

Em *Settings → Languages & Frameworks → Flutter → Flutter SDK path*, aponte para o SDK que
o FVM baixou:

```
C:\Users\<voce>\fvm\versions\3.44.7
```

(o caminho exato sai de `fvm list`). Se este passo for pulado, o app compila — só que com
outra versão de Flutter que a do CI e a das sessões de nuvem, e a diferença só aparece
quando alguma coisa quebra em um ambiente e não no outro. O verificador reporta isso como
aviso na linha `Flutter (PATH)`.

## 6. Emulador (AVD)

Pelo Device Manager do Android Studio: *Create Device* → escolha um telefone (Pixel serve)
→ imagem de sistema **API 34 ou superior**.

Restrição real: `minSdk = 26`, então qualquer imagem de API ≥ 26 roda o app. Prefira uma
próxima do `compileSdk` (**android-36**) para que o comportamento no emulador seja o mesmo
do build que vai para a loja.

Aceleração por hardware: no Windows, o emulador usa WHPX. Se ele reclamar, habilite
*Plataforma do Hipervisor do Windows* nos recursos opcionais do sistema.

Pela linha de comando:

```powershell
fvm flutter emulators                       # lista
fvm flutter emulators --launch <id>         # sobe
```

## 7. Aparelho físico (opcional, mas recomendado)

1. No aparelho: *Sobre o telefone* → toque 7× em *Número da versão* → volte → *Opções do
   desenvolvedor* → ligue **Depuração USB**.
2. Conecte por USB e autorize a impressão digital RSA que aparece na tela.
3. `adb devices` deve listar o aparelho como `device` (não `unauthorized`).

Em alguns fabricantes o Windows precisa do driver OEM para o modo ADB.

## 8. Verificação — é isto que fecha o Bloco 3

Com o emulador subido (ou o aparelho conectado), da raiz do repositório:

```powershell
fvm dart run tool/verificar_ambiente.dart --android
```

Ele confere, e falha alto quando algo não bate:

- o Flutter **em uso** contra o `.fvmrc`, e o `.fvmrc` contra o `tool/setup_env.sh`;
- o `flutter` do `PATH` (o que o Android Studio enxerga) contra o mesmo pin;
- JDK major 17;
- `ANDROID_HOME`, platform `android-36`, build-tools, NDK, `platform-tools` e licenças;
- `applicationId = com.desmalha.app` e `minSdk = 26` no `build.gradle.kts` — decisões
  travadas que um `flutter create` futuro reescreveria em silêncio;
- e, com `--android`, a existência de um alvo Android conectado.

Saída `Ambiente OK` e código de saída 0 = passou.

Depois, a bateria de sempre e o hot reload propriamente dito:

```powershell
cd packages\desmalha_core ; fvm dart test
cd ..\..\apps\desmalha_app ; fvm flutter analyze ; fvm flutter test
fvm flutter run                       # com o emulador/aparelho ativo
```

Com o app rodando, edite um texto visível em `lib/` e salve: pressione **`r`** no terminal
para hot reload (**`R`** para hot restart). A alteração tem de aparecer na tela em segundos.
**É este o critério do Bloco 3** — ambiente verificado + ciclo de edição funcionando na
máquina de UI.

---

## Problemas conhecidos no Windows

**Build de Gradle absurdamente lento.** O Defender varre cada arquivo que o Gradle escreve.
Adicione exclusões de pasta para `%USERPROFILE%\.gradle`, `%LOCALAPPDATA%\Pub\Cache`,
`%LOCALAPPDATA%\Android\Sdk` e o diretório do repositório.

**`Filename too long` no Git ou no build.** Habilite caminhos longos:

```powershell
git config --global core.longpaths true
```

e a política `LongPathsEnabled` do Windows (o instalador do Git oferece isso).

**O verificador reclama do `PATH` mas o `fvm flutter` está certo.** É o cenário da seção 5:
existe outro Flutter no `PATH`. Inofensivo na linha de comando via `fvm`, mas é o SDK que o
Android Studio vai usar.

**`adb devices` mostra `unauthorized`.** A autorização RSA não foi aceita no aparelho.
`adb kill-server ; adb start-server`, reconecte e aceite o diálogo.

**Nunca** coloque keystore, `key.properties`, senha ou service account no repositório — nem
nesta máquina, dentro da pasta do projeto. Assinatura de release é Play App Signing +
variáveis cifradas do Codemagic.
