#!/usr/bin/env bash
set -euo pipefail

readonly STOW_PKG="home"
readonly DOTFILES_DIR="${HOME}/dotfiles"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR
readonly REPO_URL="https://github.com/xdagiz/dots.git"
readonly SSH_REMOTE="git@github.com:xdagiz/dots.git"
readonly BACKUP_PREFIX="${HOME}/.dotfiles-backup"
readonly SSH_KEY="${HOME}/.ssh/id_ed25519"
readonly KEY_COMMENT="xdagiz@protonmail.com"
readonly AUR_LEFTOVERS="scc ttf-geist-mono"

DRY_RUN=0
SKIP_PACKAGES=0
SKIP_SSH=0
NONINTERACTIVE="${NONINTERACTIVE:-0}"

if [[ -t 1 ]]; then
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' CYAN='\033[0;36m' BOLD='\033[1m' RESET='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

TOTAL_STEPS=6
CURRENT_STEP=0
WOULD_RUN=0
BACKUP_DIR=""
SSH_VERIFIED=0
INSTALLED_COUNT=0
MISSING_COUNT=0

info() { printf '%b\n' "${CYAN}i${RESET} $*"; }
ok() { printf '%b\n' "${GREEN}✓${RESET} $*"; }
warn() { printf '%b\n' "${YELLOW}⚠${RESET} $*" >&2; }
fail() { printf '%b\n' "${RED}✗${RESET} $*" >&2; exit 1; }
header() { printf '\n%b%b==> %s%b\n' "$BOLD" "$CYAN" "$1" "$RESET"; }
step() { ((++CURRENT_STEP)); printf '%b[%d/%d]%b %s\n' "$BOLD" "$CURRENT_STEP" "$TOTAL_STEPS" "$RESET" "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if (( DRY_RUN )); then
    info "[dry-run] $*"
    ((++WOULD_RUN))
  else
    "$@"
  fi
}

run_sh() {
  if (( DRY_RUN )); then
    info "[dry-run] bash -c '$1'"
    ((++WOULD_RUN))
  else
    bash -c "$1"
  fi
}

confirm() {
  local prompt="${1:-Continue?}" response
  if (( NONINTERACTIVE )) || (( DRY_RUN )); then return 0; fi
  read -r -p "$prompt [y/N]: " response
  [[ "$response" =~ ^[yY] ]]
}

usage() {
  cat <<EOF
Usage: ./bootstrap.sh [options]

Options:
  --dry-run         Print every mutating command without executing it
  --skip-packages   Skip Phase 1 (pacman install)
  --skip-ssh        Skip Phase 4 (SSH key + GitHub remote flip)
  -h, --help        Show this help

Environment:
  NONINTERACTIVE=1  Auto-answer prompts, skip the SSH upload gate
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --skip-packages) SKIP_PACKAGES=1 ;;
      --skip-ssh) SKIP_SSH=1 ;;
      -h|--help) usage; exit 0 ;;
      *) fail "Unknown option: $1 (see --help)" ;;
    esac
    shift
  done
}

preflight() {
  step "Preflight"
  if (( EUID == 0 )); then fail "Refusing to run as root. Create a user and run with sudo available."; fi
  have pacman || fail "pacman not found in PATH."
  have sudo || fail "sudo not found in PATH."
  have curl || fail "curl not found in PATH."
  USER="${USER:-$(id -un)}"
  curl -fsSI --max-time 10 https://github.com >/dev/null 2>&1 || fail "No network access to github.com."
  info "Host: $(uname -n)"
  info "Home: $HOME"
  info "Repo: $REPO_DIR"
  if (( DRY_RUN )); then warn "Dry-run mode: nothing will be modified."; fi
  confirm "Run bootstrap on this machine?" || fail "Aborted."
}

load_packages() {
  local group_dir="$REPO_DIR/packages/group"
  local host_dir="$group_dir/${HOSTNAME:-$(uname -n)}"
  local files=("$group_dir/base" "$group_dir/desktop")
  if compgen -G "$host_dir/*" >/dev/null; then
    files+=("$host_dir"/*)
  fi
  declare -gA ORIGINS=()
  declare -gA SEEN=()
  PKGS=()
  local file pkg line_no fname
  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    fname="$(basename "$file")"
    while IFS= read -r line_no || [[ -n "$line_no" ]]; do
      line_no="${line_no%%#*}"
      pkg="$(trim "$line_no")"
      [[ -n "$pkg" ]] || continue
      if [[ -z "${SEEN[$pkg]:-}" ]]; then
        SEEN[$pkg]=1
        ORIGINS[$pkg]="$fname"
        PKGS+=("$pkg")
      fi
    done < "$file"
  done
  ((${#PKGS[@]})) || fail "No packages declared in ${group_dir}/{base,desktop}."
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

install_packages() {
  step "Packages"
  load_packages
  local available=() missing=() pkg
  for pkg in "${PKGS[@]}"; do
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
      warn "Not in any enabled repo, skipping: $pkg (from ${ORIGINS[$pkg]})"
    fi
  done
  INSTALLED_COUNT=${#available[@]}
  MISSING_COUNT=${#missing[@]}
  info "Installing $INSTALLED_COUNT packages (${#missing[@]} unavailable)."
  if (( ! DRY_RUN )); then
    sudo pacman -Syu --needed --noconfirm "${available[@]}"
    sudo pacman -D --asexplicit --noconfirm "${available[@]}" >/dev/null
    ok "Packages installed and marked explicit."
  else
    run sudo pacman -Syu --needed --noconfirm "${available[@]}"
  fi
}

repo_matches() {
  local url
  url="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
  [[ "$url" == *github.com[:/]xdagiz/dots* ]]
}

clone_dotfiles() {
  step "Clone"
  if [[ ! -e "$DOTFILES_DIR" ]]; then
    run git clone "$REPO_URL" "$DOTFILES_DIR"
  elif repo_matches; then
    if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
      warn "$DOTFILES_DIR has uncommitted changes; leaving it untouched."
    else
      run git -C "$DOTFILES_DIR" fetch origin
      if ! git -C "$DOTFILES_DIR" merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
        run git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not fast-forward $DOTFILES_DIR; continuing with current checkout."
      else
        ok "$DOTFILES_DIR already up to date."
      fi
    fi
  elif [[ -e "$DOTFILES_DIR/.git" ]]; then
    fail "$DOTFILES_DIR exists but tracks a different repository. Resolve manually."
  else
    fail "$DOTFILES_DIR exists and is not a git repository. Resolve manually."
  fi
}

managed_paths() {
  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$REPO_DIR" ls-files -z "$STOW_PKG"
  else
    find "$REPO_DIR/$STOW_PKG" -mindepth 1 \( -name node_modules -o -name .git \) -prune -o -print0
  fi
}

collect_conflicts() {
  CONFLICTS=()
  local src rel tgt
  while IFS= read -r -d '' path; do
    src="$REPO_DIR/$path"
    rel="${path#"$STOW_PKG/"}"
    tgt="$HOME/$rel"
    if [[ ! -e "$src" && ! -L "$src" ]]; then continue; fi
    if [[ -d "$src" ]]; then
      if [[ -e "$tgt" && ! -d "$tgt" ]]; then CONFLICTS+=("$rel"); fi
    elif [[ -L "$tgt" ]]; then
      [[ "$(readlink -f "$tgt")" == "$(readlink -f "$src")" ]] || CONFLICTS+=("$rel")
    elif [[ -e "$tgt" ]]; then
      CONFLICTS+=("$rel")
    fi
  done < <(managed_paths)
}

stow_dotfiles() {
  step "Stow"
  if ! have stow; then
    if (( DRY_RUN )); then
      warn "GNU Stow is not installed yet; dry-run will only print the stow command."
    else
      fail "GNU Stow is not installed. Re-run without --skip-packages."
    fi
  fi
  collect_conflicts
  if ((${#CONFLICTS[@]})); then
    local old
    for old in "$BACKUP_PREFIX".*; do
      [[ -d "$old" ]] || continue
      if (( DRY_RUN )); then
        info "[dry-run] rm -rf $old"
        ((++WOULD_RUN))
      else
        rm -rf "$old"
      fi
    done
    BACKUP_DIR="$BACKUP_PREFIX.$(date +%Y%m%d-%H%M%S)"
    info "${#CONFLICTS[@]} conflicting path(s), backing up to $BACKUP_DIR:"
    printf '  %s\n' "${CONFLICTS[@]}"
    if (( ! DRY_RUN )); then
      local rel
      for rel in "${CONFLICTS[@]}"; do
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$HOME/$rel" "$BACKUP_DIR/$rel"
      done
    fi
  fi
  run stow -R -v -d "$REPO_DIR" -t "$HOME" "$STOW_PKG"
  ok "Dotfiles stowed."
}

ssh_config_ready() {
  grep -q "Host github.com$" "$HOME/.ssh/config" 2>/dev/null
}

setup_ssh() {
  step "Git + SSH"
  run mkdir -p "$HOME/.ssh"
  run chmod 700 "$HOME/.ssh"
  if [[ -f "$SSH_KEY" ]]; then
    ok "SSH key already exists at $SSH_KEY"
  else
    run ssh-keygen -t ed25519 -N "" -C "$KEY_COMMENT" -f "$SSH_KEY"
    ok "Generated new ed25519 key."
  fi
  if ! ssh_config_ready; then
    run_sh "printf 'Host github.com\\n    IdentityFile ~/.ssh/id_ed25519\\n    IdentitiesOnly yes\\n    AddKeysToAgent yes\\n' >> ~/.ssh/config"
    run chmod 600 "$HOME/.ssh/config"
  fi
  if (( DRY_RUN )); then
    info "[dry-run] ssh-agent start + ssh-add"
    ((++WOULD_RUN))
    info "[dry-run] print pubkey, wait for GitHub upload, ssh -T verify"
    ((++WOULD_RUN))
    return 0
  fi
  if ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
  ssh-add "$SSH_KEY" 2>/dev/null || true
  echo
  echo -e "${BOLD}Add this public key to GitHub:${RESET}"
  echo -e "${CYAN}$(cat "$SSH_KEY.pub")${RESET}"
  echo -e "at ${BOLD}https://github.com/settings/ssh/new${RESET}"
  echo
  ssh_probe && return 0
  if (( NONINTERACTIVE )); then
    warn "Key could not be verified against GitHub yet (NONINTERACTIVE). Run 'ssh -T git@github.com' after adding the key."
    return 0
  fi
  until ssh_probe; do
    read -r -p "Paste the key on github.com/settings/ssh/new, then press Enter to re-check (or Ctrl+C): "
  done
}

ssh_probe() {
  local out
  out="$(ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 git@github.com 2>&1 || true)"
  if [[ "$out" == *"successfully authenticated"* ]]; then
    SSH_VERIFIED=1
    ok "GitHub SSH authentication confirmed."
    git -C "$DOTFILES_DIR" remote set-url origin "$SSH_REMOTE"
    ok "Origin flipped to SSH ($SSH_REMOTE)."
    return 0
  fi
  warn "GitHub SSH check failed${out:+: $out}. Has the key been added to your GitHub account?"
  return 1
}

finalize() {
  step "Finalize"
  local fish_path
  fish_path="$(command -v fish || true)"
  if (( DRY_RUN )); then
    info "[dry-run] ensure fish in /etc/shells + chsh -s"
    ((++WOULD_RUN))
  elif [[ -z "$fish_path" ]]; then
    warn "fish is not installed; skipping login-shell setup."
  elif ! getent passwd "$USER" | cut -d: -f7 | grep -qx "$fish_path"; then
    if grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
      :
    else
      run_sh "printf '%s\n' '$fish_path' >> /etc/shells" || warn "Could not write $fish_path to /etc/shells."
    fi
    run sudo chsh -s "$fish_path" "$USER" || warn "chsh failed; run 'sudo chsh -s $fish_path' manually."
    ok "Login shell set to fish (re-login required)."
  else
    ok "fish already the login shell."
  fi
  if (( DRY_RUN )); then
    info "[dry-run] install fisher + run against fish_plugins"
    ((++WOULD_RUN))
    info "[dry-run] clone TPM + headless plugin install"
    ((++WOULD_RUN))
  elif have fish; then
    if ! fish -c "type -q fisher" 2>/dev/null; then
      info "Installing fisher..."
      run_sh "fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'" || warn "fisher install failed."
    fi
    run fish -c "fisher update" || warn "fisher update failed; check ~/.config/fish/fish_plugins manually."
  fi
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if have tmux && grep -q "tpm" "$HOME/.config/tmux/tmux.conf" 2>/dev/null && [[ ! -d "$tpm_dir" ]]; then
    run git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || warn "Could not clone TPM."
  fi
  if [[ -x "$tpm_dir/bin/install_plugins.sh" ]]; then
    run "$tpm_dir/bin/install_plugins.sh" || warn "TPM headless install failed; press prefix+I inside tmux once."
  fi
  local secrets="$HOME/.config/fish/secrets.fish"
  if [[ ! -e "$secrets" ]]; then
    run mkdir -p "$(dirname "$secrets")"
    run touch "$secrets"
  fi
  [[ -d "$HOME/Music" ]] || run mkdir -p "$HOME/Music"
  doctor
}

doctor() {
  header "Doctor"
  local issues=0 broken=0 rel tgt
  while IFS= read -r -d '' p; do
    rel="${p#"$STOW_PKG/"}"
    tgt="$HOME/$rel"
    if [[ -L "$tgt" && ! -e "$tgt" ]]; then
      warn "Broken symlink: ~/$rel"
      ((++broken))
    fi
  done < <(managed_paths)
  if ((broken)); then
    ((++issues))
  else
    ok "No broken dotfile symlinks."
  fi
  if getent passwd "$USER" | cut -d: -f7 | grep -q "/fish$"; then
    ok "Login shell is fish."
  else
    warn "Login shell is not fish yet (takes effect after re-login)."
    ((++issues))
  fi
  if (( SSH_VERIFIED )); then
    ok "GitHub SSH verified."
  elif (( SKIP_SSH )); then
    info "SSH setup skipped by flag."
  else
    warn "GitHub SSH not verified this run."
  fi
  if (( MISSING_COUNT )); then
    warn "$MISSING_COUNT package(s) skipped as unavailable in enabled repos."
  fi
  if [[ -n "$AUR_LEFTOVERS" ]]; then
    echo
    echo -e "${BOLD}AUR packages referenced by your configs (install manually):${RESET}"
    echo -e "  ${CYAN}paru -S $AUR_LEFTOVERS${RESET}"
    echo
  fi
  if (( DRY_RUN )); then
    header "DRY RUN complete: $WOULD_RUN commands would execute."
    return 0
  fi
  if ((issues)); then
    warn "Bootstrap finished with $issues issue(s); see warnings above."
  else
    header "Bootstrap complete. Log out, log back into fish, start niri."
  fi
}

main() {
  parse_args "$@"
  preflight
  if (( SKIP_PACKAGES )); then
    TOTAL_STEPS=$((TOTAL_STEPS - 1))
    info "Skipping packages (--skip-packages)."
  else
    install_packages
  fi
  clone_dotfiles
  stow_dotfiles
  if (( SKIP_SSH )); then
    TOTAL_STEPS=$((TOTAL_STEPS - 1))
    info "Skipping SSH (--skip-ssh)."
  else
    setup_ssh
  fi
  finalize
}

main "$@"
