#!/usr/bin/env bash
# ============================================================================
# Arch Linux (pacman) プラットフォーム固有処理
# ============================================================================
#
# 目的:
#   Arch Linux系ディストリビューション向けの固有処理を提供します
#
# 対応ディストリビューション:
#   - Arch Linux (公式)
#   - Manjaro
#   - EndeavourOS
#   - その他Arch系ディストリビューション
#
# 提供機能:
#   - pacman パッケージマネージャーを使用したシステムパッケージインストール
#   - /etc/ca-certificates/trust-source/anchors/ での証明書管理
#   - trust extract-compat による証明書バンドル更新
#   - pacman -Q を使用したパッケージ存在確認
#
# 使用方法:
#   source "${SCRIPT_DIR}/scripts/platforms/arch.sh"
#
# 前提条件:
#   - scripts/lib/common.sh が事前に読み込まれていること
#   - pacman コマンドが利用可能であること
#   - sudo 権限（システムパッケージインストール時のみ）
#
# ============================================================================

set -Eeuo pipefail

# ============================================================================
# 証明書管理（Arch Linux系固有）
# ============================================================================

update_certificates_platform() {
    # Zscaler証明書をシステム証明書ストアに追加・更新 (Arch Linux系)
    # 引数: $1 = 証明書ファイルパス

    if [[ $# -lt 1 ]]; then
        log_error "update_certificates_platform: 証明書ファイルパスが指定されていません"
        return 1
    fi

    local cert_file="$1"
    local dest="/etc/ca-certificates/trust-source/anchors/$(basename "$cert_file")"
    local need_update=0

    log_info "証明書を追加中 (Arch Linux系): $cert_file"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo cp \"$cert_file\" \"$dest\""
        echo "[dry-run] sudo chmod 644 \"$dest\""
        echo "[dry-run] sudo trust extract-compat"
        return 0
    fi

    # 証明書ファイルをシステム cert ディレクトリにコピー
    if [[ ! -f "$dest" ]] || ! cmp -s "$cert_file" "$dest"; then
        log_debug "証明書ファイルをコピー中: $cert_file -> $dest"

        # ディレクトリが存在しない場合は作成
        sudo mkdir -p "$(dirname "$dest")"
        sudo cp "$cert_file" "$dest"
        sudo chmod 644 "$dest"
        need_update=1
    else
        log_debug "証明書ファイルは既に最新です: $dest"
    fi

    # 証明書バンドルに含まれているか検証
    if ! grep -q "Zscaler" /etc/ssl/certs/ca-certificates.crt 2>/dev/null; then
        log_warning "証明書バンドルにZscaler証明書が含まれていません。更新します..."
        need_update=1
    fi

    # 必要に応じて証明書ストアを更新
    if [[ $need_update -eq 1 ]]; then
        log_info "証明書ストアを更新中 (Arch Linux系)..."
        sudo trust extract-compat
        log_success "証明書ストアを更新しました (Arch Linux系)"
    else
        log_info "証明書バンドルは既に最新です"
    fi
    
    return 0
}

# ============================================================================
# システムパッケージ管理（Arch Linux系固有）
# ============================================================================

get_system_packages_platform() {
    # Arch Linux系で必要なシステムパッケージのリストを取得
    # 戻り値: パッケージ名の配列(標準出力)

    echo "python"
    echo "python-pip"
    echo "base-devel"
    echo "openssl"
    echo "libffi"
}

check_package_installed_platform() {
    # 指定されたパッケージがインストール済みかチェック (Arch Linux系)
    # 引数: $1 = パッケージ名
    # 戻り値: インストール済みなら0、未インストールなら1

    if [[ $# -lt 1 ]]; then
        log_error "check_package_installed_platform: パッケージ名が指定されていません"
        return 1
    fi

    local package="$1"

    log_debug "パッケージの存在確認 (pacman): $package"

    if pacman -Q "$package" >/dev/null 2>&1; then
        log_debug "パッケージはインストール済み: $package"
        return 0
    else
        log_debug "パッケージは未インストール: $package"
        return 1
    fi
}

get_missing_packages_platform() {
    # インストールされていないシステムパッケージのリストを取得
    # 戻り値: 未インストールパッケージ名の配列(標準出力)

    local -a missing_packages=()

    while IFS= read -r package; do
        if ! check_package_installed_platform "$package"; then
            missing_packages+=("$package")
        fi
    done < <(get_system_packages_platform)

    # 配列の各要素を出力
    printf '%s\n' "${missing_packages[@]}"
}

install_system_packages_platform() {
    # Ansible用のシステムレベル依存関係をインストール (Arch Linux系)
    # pacman パッケージマネージャーを使用

    log_info "システム依存関係をインストール中 (Arch Linux系)..."

    # 必要なパッケージリストを取得
    local -a packages=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(get_system_packages_platform)

    log_debug "インストール対象のシステムパッケージ: ${packages[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo pacman -Sy ${packages[*]}"
        return 0
    fi

    # インストール済みかチェック
    local -a missing_packages=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && missing_packages+=("$package")
    done < <(get_missing_packages_platform)

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "すべてのシステムパッケージが既にインストール済みです (Arch Linux系)"
        return 0
    fi

    log_info "不足しているパッケージをインストール中: ${missing_packages[*]}"
    log_warning "sudo権限で以下を実行します:"
    log_warning "  sudo pacman -Sy ${missing_packages[*]}"

    # パッケージデータベースを同期してからパッケージをインストール
    if ! sudo pacman -Sy --noconfirm "${missing_packages[@]}"; then
        log_error "システムパッケージのインストールに失敗しました"
        log_warning "手動で以下を実行してください:"
        log_warning "  sudo pacman -Sy ${missing_packages[*]}"
        return 1
    fi

    log_success "システムパッケージのインストールが完了しました (Arch Linux系)"
    return 0
}

# ============================================================================
# プラットフォーム固有のセットアップ関数
# ============================================================================

setup_platform_environment() {
    # Arch Linux系プラットフォーム固有の環境セットアップ

    log_info "Arch Linux系プラットフォーム環境をセットアップ中..."

    # 基本的な環境確認
    if ! command -v pacman >/dev/null 2>&1; then
        log_error "pacman コマンドが見つかりません。Arch Linux系環境でないか、pacmanが正しくインストールされていません。"
        return 1
    fi

    log_debug "pacman バージョン: $(pacman --version 2>/dev/null | head -n1 || echo 'unknown')"

    # AUR ヘルパーの存在確認（オプショナル）
    if command -v yay >/dev/null 2>&1; then
        log_debug "AUR ヘルパー: yay が利用可能"
    elif command -v pamac >/dev/null 2>&1; then
        log_debug "AUR ヘルパー: pamac が利用可能"
    else
        log_debug "AUR ヘルパーは見つかりませんでした（オプショナル）"
    fi

    log_success "Arch Linux系プラットフォーム環境の確認完了"
    return 0
}

get_platform_info() {
    # プラットフォーム情報を表示

    cat <<EOF
プラットフォーム: Arch Linux系 (pacman)
パッケージマネージャー: pacman
証明書ディレクトリ: /etc/ca-certificates/trust-source/anchors/
証明書更新コマンド: trust extract-compat
対応ディストリビューション: Arch Linux, Manjaro, EndeavourOS
EOF
}

# ============================================================================
# 接続テスト（Arch Linux系固有）
# ============================================================================

test_certificate_connectivity() {
    # 証明書インストール後の接続テストを実行
    # 引数: なし (デフォルトで www.google.com:443 をテスト)

    local test_host="${1:-www.google.com}"
    local test_port="${2:-443}"

    log_info "証明書インストール後の接続テスト: openssl s_client -connect ${test_host}:${test_port}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] openssl s_client -connect ${test_host}:${test_port} -CApath /etc/ssl/certs"
        return 0
    fi

    if ! openssl s_client -connect "${test_host}:${test_port}" -CApath /etc/ssl/certs < /dev/null 2>/dev/null | grep -q 'Verify return code: 0 (ok)'; then
        log_error "openssl s_client による接続テストに失敗しました (証明書ストアの反映を確認してください)"
        return 1
    else
        log_success "openssl s_client による接続テスト成功 (証明書ストアが有効です)"
        return 0
    fi
}

# ============================================================================
# AUR パッケージ管理（Arch Linux固有）
# ============================================================================

check_aur_helper() {
    # AUR (Arch User Repository) ヘルパーの存在確認
    # 戻り値: 利用可能なヘルパー名 または 空文字列

    local aur_helpers=("yay" "pamac" "trizen" "yaourt")

    for helper in "${aur_helpers[@]}"; do
        if command -v "$helper" >/dev/null 2>&1; then
            echo "$helper"
            return 0
        fi
    done

    echo ""
    return 1
}

install_aur_package() {
    # AUR パッケージをインストール（ヘルパーが利用可能な場合）
    # 引数: $1 = パッケージ名
    # 戻り値: 成功なら0、失敗なら1

    if [[ $# -lt 1 ]]; then
        log_error "install_aur_package: パッケージ名が指定されていません"
        return 1
    fi

    local package="$1"
    local aur_helper

    aur_helper=$(check_aur_helper)

    if [[ -z "$aur_helper" ]]; then
        log_warning "AUR ヘルパーが見つからないため、AUR パッケージのインストールをスキップします: $package"
        return 1
    fi

    log_info "AUR パッケージをインストール中: $package (ヘルパー: $aur_helper)"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] $aur_helper -S $package"
        return 0
    fi

    if "$aur_helper" -S --noconfirm "$package"; then
        log_success "AUR パッケージのインストールが完了しました: $package"
        return 0
    else
        log_error "AUR パッケージのインストールに失敗しました: $package"
        return 1
    fi
}

# ============================================================================
# パッケージデータベース管理
# ============================================================================

update_package_database() {
    # pacman パッケージデータベースを更新

    log_info "パッケージデータベースを更新中..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo pacman -Sy"
        return 0
    fi

    if sudo pacman -Sy --noconfirm; then
        log_success "パッケージデータベースの更新が完了しました"
        return 0
    else
        log_error "パッケージデータベースの更新に失敗しました"
        return 1
    fi
}

upgrade_system_packages() {
    # システム全体のパッケージをアップグレード（オプショナル）

    log_info "システムパッケージのアップグレードを確認中..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo pacman -Su"
        return 0
    fi

    # 利用可能なアップグレードがあるかチェック
    if pacman -Qu | grep -q .; then
        log_info "利用可能なパッケージアップグレードがあります"
        log_warning "手動でシステムをアップグレードすることが推奨されます:"
        log_warning "  sudo pacman -Su"
    else
        log_info "すべてのパッケージは最新です"
    fi

    return 0
}

# ============================================================================
