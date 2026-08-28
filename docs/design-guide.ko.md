# 개발환경 설계 가이드

이 문서는 dotfiles를 처음 접하는 개발자를 위한 설명서입니다. 명령을 그대로
복사하기 전에, 이 저장소가 무엇을 관리하고 각 도구가 어떻게 연결되는지 이해하는
것을 목표로 합니다.

> 중요한 안전 원칙: 저장소를 clone하는 것만으로는 현재 Mac이 바뀌지 않습니다.
> `./install.sh`도 기본적으로 미리보기만 수행합니다. 실제 변경은 사용자가
> `--apply`를 명시했을 때만 시작됩니다.

## 1. 우리가 해결하려는 문제

새 Mac을 설정한다고 생각해 봅시다. 보통은 다음 작업을 하나씩 수동으로 합니다.

1. 프로그램을 검색해서 설치합니다.
2. 터미널, 셸, Git, 에디터 설정을 다시 만듭니다.
3. Node 버전과 Python 도구를 맞춥니다.
4. 예전에 사용하던 단축키와 agent 규칙을 기억해서 복원합니다.

이 방식은 시간이 오래 걸릴 뿐 아니라, 시간이 지나면 어떤 설정이 왜 존재하는지
알기 어렵습니다. 이 저장소는 개발환경을 코드처럼 관리하여 다음 질문에 답합니다.

- 어떤 기반 프로그램을 설치해야 하는가? → `Brewfile`
- Claude Code와 Codex를 어떻게 설치하는가? → `scripts/agents.sh`
- 각 프로그램은 어떻게 동작해야 하는가? → Stow 패키지 안의 설정 파일
- 어떤 Node 버전을 사용할 것인가? → mise 설정
- coding agent는 어떤 원칙으로 일해야 하는가? → `AGENTS.md`
- 설정을 어떻게 안전하게 적용하는가? → `install.sh`

## 2. 전체 구조를 먼저 이해하기

이 환경은 다섯 개 계층으로 나뉩니다.

```text
┌─────────────────────────────────────────────────────────┐
│ 1. 패키지 계층                                           │
│    Brewfile → Ghostty, Git, Neovim, tmux 등을 설치       │
│    Publisher installer → Claude Code와 Codex 설치        │
├─────────────────────────────────────────────────────────┤
│ 2. 설정 계층                                             │
│    dotfiles 파일 → GNU Stow → 홈 디렉터리 symbolic link │
├─────────────────────────────────────────────────────────┤
│ 3. 셸과 런타임 계층                                      │
│    zsh → mise / Starship / zoxide / fzf / Atuin         │
├─────────────────────────────────────────────────────────┤
│ 4. 작업 계층                                             │
│    Ghostty → tmux 또는 Herdr → shell / Neovim / agents  │
├─────────────────────────────────────────────────────────┤
│ 5. 정책 계층                                             │
│    global AGENTS.md + project AGENTS.md + 현재 요청     │
└─────────────────────────────────────────────────────────┘
```

계층을 분리한 이유는 문제가 생겼을 때 원인을 좁히기 쉽기 때문입니다. 예를 들어
`node` 명령을 찾지 못하면 Ghostty 테마를 볼 필요가 없습니다. Homebrew가 mise를
설치했는지, mise가 Node를 설치했는지, zsh가 mise를 활성화했는지만 확인하면 됩니다.

## 3. 먼저 알아둘 용어

### dotfiles

Unix 계열 시스템에서는 이름이 `.`으로 시작하는 파일을 숨김 파일이라고 부릅니다.
`~/.zshrc`, `~/.gitconfig`처럼 많은 개발 도구가 이 파일에 설정을 저장합니다.
이러한 설정 파일을 모아 관리하는 저장소를 보통 dotfiles라고 부릅니다.

여기서 `~`는 현재 사용자의 홈 디렉터리입니다. macOS에서는 대개 다음과 같습니다.

```text
/Users/사용자이름
```

### symbolic link

symbolic link 또는 symlink는 한 위치에서 다른 파일을 가리키는 링크입니다.
Windows의 바로가기와 비슷하지만, 대부분의 프로그램은 symlink를 실제 파일처럼
읽습니다.

```text
~/.config/nvim
        │
        └── 가리킴 ──→ ~/dotfiles/nvim/.config/nvim
```

이 구조에서는 Neovim 설정을 수정하면 실제로 dotfiles 저장소 안의 파일이
수정됩니다. 따라서 `git status`로 설정 변경을 바로 확인할 수 있습니다.

### GNU Stow

Stow는 위 symlink를 패키지 단위로 만들고 정리하는 도구입니다. 예를 들어
`nvim/` 디렉터리 내부는 홈 디렉터리 구조를 그대로 흉내 냅니다.

```text
dotfiles/nvim/.config/nvim/init.lua
          └─────────┬───────────┘
                    │ Stow
                    ▼
           ~/.config/nvim/init.lua
```

이 저장소는 `stow --adopt`를 사용하지 않습니다. `--adopt`는 홈에 있던 파일을
dotfiles 쪽으로 가져오면서 저장소 파일을 바꿀 수 있기 때문입니다. 기존 파일과
충돌하면 자동으로 처리하지 않고 멈추는 것이 이 설계의 핵심 안전장치입니다.

### Homebrew와 Brewfile

Homebrew는 macOS 패키지 관리자입니다. `brew install tmux`처럼 프로그램을 설치할
수 있습니다. `Brewfile`은 여러 설치 항목을 한 파일에 선언한 목록입니다.

```ruby
brew "tmux"       # 명령행 프로그램
cask "ghostty"    # macOS 애플리케이션
```

Homebrew는 프로그램 자체를 설치하고, Stow는 그 프로그램의 사용자 설정을
연결합니다. 두 도구의 책임은 서로 다릅니다.

### mise와 uv

mise는 머신에서 사용할 언어 런타임 버전을 관리합니다. 이 저장소는 Node 24를
선언합니다.

```toml
[tools]
node = "24"
```

uv는 Python 프로젝트의 가상환경과 의존성을 관리합니다. 역할을 단순화하면 다음과
같습니다.

```text
mise = 이 컴퓨터에서 어떤 runtime 버전을 사용할지 관리
uv   = 한 Python 프로젝트의 환경과 패키지를 관리
```

## 4. 저장소 디렉터리 둘러보기

```text
dotfiles/
├── Brewfile
├── install.sh
├── AGENTS.md
├── agents/AGENTS.md
├── scripts/
│   ├── bootstrap.sh
│   ├── check.sh
│   └── macos.sh
├── ghostty/
├── zsh/
├── starship/
├── atuin/
├── tmux/
├── herdr/
├── mise/
├── nvim/
└── git/
```

각 항목의 역할은 다음과 같습니다.

| 위치 | 역할 |
|---|---|
| `Brewfile` | 설치할 명령행 도구와 macOS 앱 목록 |
| `install.sh` | 사용자가 실행하는 안전한 진입점 |
| `scripts/bootstrap.sh` | 옵션 처리, Stow 실행, agent 링크 생성 |
| `scripts/agents.sh` | Claude Code와 Codex의 native 설치·업데이트 관리 |
| `scripts/check.sh` | 임시 홈에서 설치 방법을 검증 |
| `scripts/macos.sh` | Finder와 키 반복 설정을 선택적으로 적용 |
| `AGENTS.md` | 이 dotfiles 프로젝트에만 적용되는 작업 규칙 |
| `agents/AGENTS.md` | 모든 프로젝트에서 사용할 전역 agent 규칙 |
| `ghostty/`, `zsh/` 등 | 프로그램별 Stow 패키지 |

## 5. 설치 명령은 실제로 무엇을 하는가

### `./install.sh`

기본 명령은 dry-run입니다.

```bash
./install.sh
```

내부에서는 Stow의 `--simulate` 옵션을 사용합니다. 생성할 symlink와 충돌만
출력하며 홈 디렉터리에 파일을 쓰지 않습니다. 출력에 `LINK`가 보여도 마지막에
simulation 경고가 있다면 실제 링크는 만들어지지 않았습니다.

### `./install.sh --packages`

`Brewfile`에 선언한 프로그램이 설치되어 있는지 확인합니다. 빠진 항목을 설치하지는
않습니다.

### `./install.sh --apply`

패키지는 설치하지 않고 설정 symlink만 생성합니다. 이미 일반 파일이나 다른 곳을
가리키는 symlink가 있으면 중단합니다.

### `./install.sh --apply --packages`

가장 큰 범위의 명령입니다.

```text
Brewfile 패키지 설치
        ↓
Stow 설정 링크 생성
        ↓
Codex와 Claude 전역 정책 링크 생성
```

처음부터 이 명령을 실행하기보다 dry-run 결과를 먼저 읽는 것을 권장합니다.

### Claude Code와 Codex native 설치

두 agent CLI는 빠르게 변하고 각 publisher가 standalone installer를 제공하므로
`Brewfile`에 넣지 않습니다. 대신 저장소가 관리하는 별도 명령을 사용합니다.

```bash
./scripts/agents.sh status
./scripts/agents.sh install
```

두 번째 명령도 dry-run이므로 실제 설치는 일어나지 않습니다. 출력 내용을 확인한
뒤에만 다음을 실행합니다.

```bash
./scripts/agents.sh install --apply
```

Claude Code는 기본적으로 stable channel을 선택하고 native background updater를
사용합니다. Codex는 최신 standalone release를 설치하며, 업데이트할 때 OpenAI의
installer를 다시 실행합니다. 저장소는 두 동작을 한 명령으로 묶습니다.

```bash
./scripts/agents.sh update
./scripts/agents.sh update --apply
```

native launcher는 `~/.local/bin`에 생성됩니다. `.zprofile`이 이 디렉터리를 PATH에
추가하므로 새 터미널에서 `claude`와 `codex` 명령을 찾을 수 있습니다. Homebrew나
npm으로 같은 CLI를 중복 설치하면 PATH 순서에 따라 다른 버전이 실행될 수 있으므로
한 가지 설치 방식만 사용해야 합니다.

## 6. 터미널을 열었을 때의 흐름

Ghostty를 실행하면 다음 순서로 환경이 준비됩니다.

```text
Ghostty 실행
    ↓
zsh 시작
    ↓
~/.zprofile
    └── Apple Silicon 또는 Intel Homebrew 경로 활성화
    ↓
~/.zshrc
    ├── mise: Node 같은 runtime 활성화
    ├── zoxide: 자주 가는 디렉터리 학습
    ├── fzf: fuzzy finder와 셸 단축키
    ├── Atuin: 셸 명령 기록 검색
    └── Starship: prompt 표시
```

`.zprofile`은 로그인 셸의 기반 환경을 준비하고, `.zshrc`는 대화형 셸에서 사용할
도구와 alias를 준비합니다. 셸 스크립트 같은 비대화형 실행에서는 `.zshrc`의
interactive 설정이 적용되지 않도록 방어 코드가 들어 있습니다.

주요 alias는 다음과 같습니다.

```text
t       tmux 실행
h       Herdr 실행
v       Neovim 실행
ll      자세한 파일 목록
tree    디렉터리 트리
```

## 7. tmux와 Herdr를 함께 설치하는 이유

두 도구 모두 하나의 터미널 창을 여러 pane과 session으로 나누지만 사용 목적이
다릅니다.

| 상황 | 추천 도구 | 이유 |
|---|---|---|
| 일반 개발 | tmux | 오래 검증되었고 서버에서도 흔히 사용됨 |
| SSH 장기 작업 | tmux | 원격 환경에서 쉽게 사용할 수 있음 |
| 여러 coding agent 작업 | Herdr | agent 상태와 workspace를 한눈에 확인 가능 |
| Claude/Codex 병렬 관찰 | Herdr | working, blocked, done 같은 상태를 표시 |

기본 사용은 둘 중 하나를 선택하는 방식입니다.

```text
Ghostty → tmux  → shell / Neovim / server

또는

Ghostty → Herdr → Claude / Codex / Neovim / tests
```

`Ghostty → tmux → Herdr`처럼 항상 중첩하지 않는 이유는 pane, session, prefix key가
두 겹이 되어 초보자에게 혼란을 주기 때문입니다. 이 설정에서 tmux prefix는
`Ctrl-a`, Herdr는 기본 `Ctrl-b`입니다.

## 8. Neovim을 변경 검토 도구로 사용하기

Neovim 설정은 모든 기능을 한 번에 넣지 않고 agent가 만든 변경을 검토하는 데
필요한 네 가지 중심 플러그인으로 시작합니다.

| 플러그인 | 하는 일 |
|---|---|
| Gitsigns | 현재 파일에서 추가·수정·삭제된 줄 표시 |
| Neogit | 저장소 전체 변경 확인, stage, commit 인터페이스 |
| Snacks | 파일 찾기, 문자열 검색, Git 기록 탐색 |
| which-key | leader key를 누른 뒤 가능한 단축키 안내 |

기본 검토 흐름은 다음과 같습니다.

1. agent가 코드 수정을 마칩니다.
2. Neovim에서 변경 파일을 엽니다.
3. `]h`, `[h`로 변경 묶음(hunk) 사이를 이동합니다.
4. `<leader>hp`로 해당 변경을 미리 봅니다.
5. `<leader>gg`로 Neogit을 열어 저장소 전체 diff를 검토합니다.
6. 테스트가 통과했는지 확인한 뒤 필요한 변경만 stage합니다.

여기서 `<leader>`는 Space 키입니다. 따라서 `<leader>gg`는 Space를 누른 다음 `g`,
`g`를 누르는 뜻입니다.

Neovim을 처음 실행하면 `lazy.nvim`과 플러그인을 GitHub에서 내려받습니다. 이는
설정 링크 생성과는 별개인 Neovim의 최초 실행 동작입니다.

## 9. 전역 AGENTS.md와 프로젝트 AGENTS.md

coding agent에게 전달되는 지침은 다음처럼 쌓입니다.

```text
전역 정책
  ~/.codex/AGENTS.md
        +
프로젝트 정책
  프로젝트/AGENTS.md
        +
현재 사용자의 요청
        ↓
이번 작업에서 agent가 따라야 할 행동
```

### 전역 정책

`agents/AGENTS.md`가 원본입니다. 설치기는 같은 원본을 다음 위치에 연결합니다.

```text
agents/AGENTS.md
    ├──→ ~/.codex/AGENTS.md
    └──→ ~/.claude/CLAUDE.md
```

여기에는 모든 프로젝트에서 지키고 싶은 일반 원칙을 둡니다. 예를 들면 테스트 없이
성공했다고 말하지 않기, 비밀정보를 노출하지 않기, 요청 없이 commit하지 않기
등입니다.

### 프로젝트 정책

각 코드 저장소의 루트에 commit합니다. 이 저장소의 루트 `AGENTS.md`가 실제
예시입니다. 프로젝트의 설치·테스트 명령, 디렉터리 구조, 도메인 규칙을 기록합니다.

```markdown
# Project Instructions

## Commands

- Install: `uv sync`
- Test: `uv run pytest`
- Lint: `uv run ruff check .`
```

전역 파일에 특정 프로젝트 명령을 넣으면 다른 프로젝트에서는 틀린 지침이 됩니다.
반대로 프로젝트 파일에 개인의 보편적인 작업 원칙을 반복하면 저장소마다 내용이
달라집니다. 두 범위를 나누는 것이 중요합니다.

Codex의 정확한 탐색 순서와 override 규칙은 [OpenAI 공식 AGENTS.md 문서](https://developers.openai.com/codex/guides/agents-md/)에서 확인할 수 있습니다.

## 10. 초보자를 위한 첫 적용 순서

### 1단계: 현재 상태 확인

현재 홈 설정을 삭제하거나 옮기지 말고 먼저 존재 여부만 확인합니다.

```bash
ls -la ~/.zshrc ~/.zprofile ~/.gitconfig 2>/dev/null
ls -la ~/.config/nvim ~/.config/ghostty 2>/dev/null
```

파일이 보이는 것은 문제가 아닙니다. dry-run에서 충돌로 보고될 가능성이 있다는
뜻입니다.

### 2단계: Stow만 준비

```bash
brew install stow
```

Stow는 미리보기와 링크 생성에 필요한 도구입니다.

### 3단계: dry-run 실행

```bash
cd ~/dotfiles
./install.sh
```

충돌이 없다면 어떤 링크가 만들어질지 확인합니다. 충돌이 있다면 다음 절의 안전한
처리 방법을 따릅니다.

### 4단계: 패키지 목록 검토

`Brewfile`을 열어 실제로 원하는 앱인지 확인합니다. 이 저장소는 GUI editor로
Zed를 선택했습니다. VS Code를 원한다면 적용 전에 다음 줄을 바꿀 수 있습니다.

```ruby
# 기존
cask "zed"

# 변경
cask "visual-studio-code"
```

### 5단계: 원하는 범위만 적용

프로그램이 이미 설치되어 있고 링크만 만들려면:

```bash
./install.sh --apply
```

프로그램 설치도 함께 하려면:

```bash
./install.sh --apply --packages
```

### 6단계: 새 셸 확인

Ghostty를 완전히 새로 열고 다음 명령을 확인합니다.

```bash
git --version
mise --version
node --version
nvim --version
tmux -V
herdr --version
```

그다음 agent 설치를 별도로 미리 보고 적용합니다.

```bash
./scripts/agents.sh install
./scripts/agents.sh install --apply
claude --version
codex --version
```

## 11. 기존 설정과 충돌할 때

예를 들어 다음 메시지가 나온다고 가정합니다.

```text
existing target is neither a link nor a directory: .zshrc
```

이때 기존 파일을 바로 삭제하지 마세요. 먼저 차이를 읽습니다.

```bash
diff -u ~/.zshrc ~/dotfiles/zsh/.zshrc
```

그다음 세 가지 중 하나를 선택합니다.

1. 기존 설정에서 필요한 줄을 dotfiles 파일로 수동 병합합니다.
2. 새 설정을 원하지 않으면 `scripts/bootstrap.sh`의 `stow_packages` 목록에서 해당
   패키지를 제외합니다.
3. 기존 파일을 안전한 백업 위치로 직접 옮긴 뒤 dry-run을 다시 실행합니다.

예를 들어 백업하려면 날짜가 포함된 명확한 이름을 사용합니다.

```bash
mv ~/.zshrc ~/.zshrc.before-dotfiles
./install.sh
```

`~/.gitconfig`에는 이름과 이메일이 이미 있을 가능성이 큽니다. 이 저장소의 Git
설정에는 개인 신원을 넣지 않았으므로, 기존 값을 무작정 버리지 말고 다음처럼 먼저
확인해야 합니다.

```bash
git config --global --get user.name
git config --global --get user.email
```

## 12. 자주 하는 변경

### Node 버전 바꾸기

`mise/.config/mise/config.toml`의 값을 수정합니다.

```toml
[tools]
node = "22"
```

새 셸을 열거나 다음 명령으로 설치·활성화 상태를 갱신합니다.

```bash
mise install
```

### 셸 alias 추가하기

`zsh/.zshrc`에 추가합니다.

```zsh
alias gs="git status"
```

이미 symlink가 적용된 상태라면 파일을 저장하는 순간 dotfiles 저장소가 변경됩니다.
새 터미널을 열거나 `source ~/.zshrc`로 현재 셸에 반영할 수 있습니다.

### Homebrew 프로그램 추가하기

`Brewfile`에 한 줄을 추가합니다.

```ruby
brew "shellcheck"
```

그다음 패키지만 적용하려면 다음을 실행합니다.

```bash
brew bundle --file ~/dotfiles/Brewfile
```

### Neovim 플러그인 추가하기

`nvim/.config/nvim/lua/plugins/` 아래의 Lua 파일에 lazy.nvim plugin spec을
추가합니다. 처음에는 기존 `review.lua`를 읽어 plugin 이름, lazy-loading 조건,
단축키, 옵션이 어떻게 묶이는지 이해한 뒤 추가하는 것이 좋습니다.

## 13. Git worktree와 Herdr를 나중에 결합하기

Git worktree는 하나의 저장소에서 여러 branch를 서로 다른 디렉터리로 동시에 열게
해 줍니다.

```bash
git worktree add ../project-refactor -b refactor
git worktree add ../project-eval -b eval
```

그다음 각 디렉터리에서 Herdr workspace를 열면 agent가 같은 파일을 동시에 수정하는
충돌을 줄일 수 있습니다.

```text
project/           main branch       Claude 구현
project-refactor/  refactor branch   Codex 리팩터링
project-eval/      eval branch       테스트와 평가
```

worktree는 Git 기본 사용과 branch 개념에 익숙해진 뒤 도입해도 늦지 않습니다.

## 14. 문제를 찾는 순서

설정이 기대대로 동작하지 않을 때는 위에서부터 무작정 재설치하지 말고 다음 순서를
따릅니다.

### 명령 자체가 없는 경우

```bash
command -v herdr
brew list herdr
```

Homebrew 설치 계층을 확인합니다.

### 설정이 적용되지 않는 경우

```bash
ls -la ~/.config/herdr
readlink ~/.config/herdr
```

Stow 링크 계층을 확인합니다.

### Node 버전이 다른 경우

```bash
command -v node
mise current
mise doctor
```

mise와 셸 활성화 계층을 확인합니다.

### prompt나 셸 도구가 보이지 않는 경우

```bash
zsh -lic 'command -v starship; command -v mise; command -v atuin'
```

`.zprofile`과 `.zshrc` 로딩을 확인합니다.

### agent가 프로젝트 규칙을 읽지 않는 경우

- 파일 이름이 정확히 `AGENTS.md`인지 확인합니다.
- 프로젝트 Git root와 현재 작업 디렉터리를 확인합니다.
- Codex session을 새로 시작합니다. Codex는 session 시작 시 지침을 다시 읽습니다.

## 15. 이 설계에서 의도적으로 하지 않은 것

- 기존 홈 파일을 자동으로 가져오거나 덮어쓰지 않습니다.
- Git 이름, 이메일, 인증정보를 저장소에 넣지 않습니다.
- tmux 안에서 Herdr를 항상 중첩 실행하지 않습니다.
- 전역 정책과 프로젝트 정책의 내용을 복사해서 중복 관리하지 않습니다.
- macOS defaults를 bootstrap에 자동 포함하지 않습니다.
- 처음부터 Nix를 도입하지 않습니다.

이 선택들은 기능 부족이 아니라 학습 가능성과 복구 가능성을 우선한 경계입니다.
Homebrew, Stow, mise 각각의 역할을 이해한 뒤 더 강한 재현성이 필요해지면
`nix-darwin`이나 Home Manager를 검토할 수 있습니다.

## 16. 적용 전 최종 체크리스트

- [ ] `Brewfile`의 앱을 모두 원하는지 읽었다.
- [ ] Zed와 VS Code 중 사용할 editor를 선택했다.
- [ ] `./install.sh` dry-run 결과를 읽었다.
- [ ] 기존 `.zshrc`, `.gitconfig`, Neovim 설정의 충돌 여부를 확인했다.
- [ ] 기존 설정을 삭제하지 않고 필요한 내용을 병합하거나 백업했다.
- [ ] `agents/AGENTS.md`의 정책이 내 작업 방식에 맞는지 읽었다.
- [ ] agent native installer의 dry-run 결과를 확인했다.
- [ ] Claude Code와 Codex를 Homebrew/npm으로 중복 설치하지 않았다.
- [ ] 실제 적용에는 `--apply`가 필요하다는 점을 이해했다.

이 체크리스트를 모두 확인했다면 이 저장소의 구조와 적용 범위를 충분히 이해한
상태입니다.
