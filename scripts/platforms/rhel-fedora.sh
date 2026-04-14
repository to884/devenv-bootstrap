#!/usr/bin/env bash
# ============================================================================
# RHEL/CentOS/Fedora (dnf/yum) プラットフォーム固有処理
# ============================================================================
#
# 目的:
#   RHEL、CentOS、Fedora系ディストリビューション向けの固有処理を提供します
#
# 対応ディストリビューション:
#   - Fedora (すべてのバージョン)
#   - RHEL (Red Hat Enterprise Linux)
#   - CentOS (すべてのバージョン)
#   - Rocky Linux
#   - AlmaLinux
#   - その他RHEL系ディストリビューション
#
# 提供機能:
#   - dnf/yum パッケージマネージャーを使用したシステムパッケージインストール
#   - /etc/pki/ca-trust/source/anchors/ での証明書管理
#   - update-ca-trust による証明書バンドル更新
#   - rpm を使用したパッケージ存在確認
#   - dnf/yum の自動選択
#
# 使用方法:
#   source "${SCRIPT_DIR}/scripts/platforms/rhel-fedora.sh"
#
# 前提条件:
#   - scripts/lib/common.sh が事前に読み込まれていること
#   - dnf または yum コマンドが利用可能であること
#   - sudo 権限（システムパッケージインストール時のみ）
#
# ============================================================================

set -Eeuo pipefail

# ============================================================================
# 証明書管理（RHEL/Fedora系固有）
# ============================================================================

update_certificates_platform() {
    # Zscaler証明書をシステム証明書ストアに追加・更新 (RHEL/Fedora系)
    # 引数: $1 = 証明書ファイルパス

    if [[ $# -lt 1 ]]; then
        log_error "update_certificates_platform: 証明書ファイルパスが指定されていません"
        return 1
    fi

    local cert_file="$1"
    local dest="/etc/pki/ca-trust/source/anchors/$(basename "$cert_file")"
    local need_update=0

    log_info "証明書を追加中 (RHEL/Fedora系): $cert_file"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo cp \"$cert_file\" \"$dest\""
        echo "[dry-run] sudo chmod 644 \"$dest\""
        echo "[dry-run] sudo update-ca-trust extract"
        return 0
    fi

    # 証明書ファイルをシステム cert ディレクトリにコピー
    if [[ ! -f "$dest" ]] || ! cmp -s "$cert_file" "$dest"; then
        log_debug "証明書ファイルをコピー中: $cert_file -> $dest"
        sudo cp "$cert_file" "$dest"
        sudo chmod 644 "$dest"
        need_update=1
    else
        log_debug "証明書ファイルは既に最新です: $dest"
    fi

    # 証明書バンドルに含まれているか検証
    if ! grep -q "Zscaler" /etc/pki/tls/certs/ca-bundle.crt 2>/dev/null; then
        log_warning "証明書バンドルにZscaler証明書が含まれていません。更新します..."
        need_update=1
    fi

    # 必要に応じて証明書ストアを更新
    if [[ $need_update -eq 1 ]]; then
        log_info "証明書ストアを更新中 (RHEL/Fedora系)..."
        sudo update-ca-trust extract
        log_success "証明書ストアを更新しました (RHEL/Fedora系)"
    else
        log_info "証明書バンドルは既に最新です"
    fi
    
    return 0
}

# ============================================================================
# パッケージマネージャー選択（RHEL/Fedora系固有）
# ============================================================================

get_package_manager_platform() {
    # 利用可能なパッケージマネージャー（dnf または yum）を取得
    # 戻り値: "dnf" または "yum"

    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    else
        log_error "dnf も yum も見つかりません"
        exit 3
    fi
}

# ============================================================================
# システムパッケージ管理（RHEL/Fedora系固有）
# ============================================================================

get_system_packages_platform() {
    # RHEL/Fedora系で必要なシステムパッケージのリストを取得
    # 戻り値: パッケージ名の配列(標準出力)

    echo "python3"
    echo "python3-pip"
    echo "python3-virtualenv"
    echo "gcc"
    echo "openssl-devel"
    echo "libffi-devel"
}

check_package_installed_platform() {
    # 指定されたパッケージがインストール済みかチェック (RHEL/Fedora系)
    # 引数: $1 = パッケージ名
    # 戻り値: インストール済みなら0、未インストールなら1

    if [[ $# -lt 1 ]]; then
        log_error "check_package_installed_platform: パッケージ名が指定されていません"
        return 1
    fi

    local package="$1"

    log_debug "パッケージの存在確認 (rpm): $package"

    if rpm -q "$package" >/dev/null 2>&1; then
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
    # Ansible用のシステムレベル依存関係をインストール (RHEL/Fedora系)
    # dnf または yum パッケージマネージャーを使用

    log_info "システム依存関係をインストール中 (RHEL/Fedora系)..."

    # パッケージマネージャーを決定
    local pkg_mgr
    pkg_mgr=$(get_package_manager_platform)
    log_debug "使用するパッケージマネージャー: $pkg_mgr"

    # 必要なパッケージリストを取得
    local -a packages=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(get_system_packages_platform)

    log_debug "インストール対象のシステムパッケージ: ${packages[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo $pkg_mgr install -y ${packages[*]}"
        return 0
    fi

    # インストール済みかチェック
    local -a missing_packages=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && missing_packages+=("$package")
    done < <(get_missing_packages_platform)

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "すべてのシステムパッケージが既にインストール済みです (RHEL/Fedora系)"
        return 0
    fi

    log_info "不足しているパッケージをインストール中: ${missing_packages[*]}"
    log_warning "sudo権限で以下を実行します:"
    log_warning "  sudo $pkg_mgr install -y ${missing_packages[*]}"

    # パッケージをインストール
    if ! sudo "$pkg_mgr" install -y "${missing_packages[@]}"; then
        log_error "システムパッケージのインストールに失敗しました"
        log_warning "手動で以下を実行してください:"
        log_warning "  sudo $pkg_mgr install -y ${missing_packages[*]}"
        return 1
    fi

    log_success "システムパッケージのインストールが完了しました (RHEL/Fedora系)"
    return 0
}

# ============================================================================
# プラットフォーム固有のセットアップ関数
# ============================================================================

setup_platform_environment() {
    # RHEL/Fedora系プラットフォーム固有の環境セットアップ

    log_info "RHEL/Fedora系プラットフォーム環境をセットアップ中..."

    # パッケージマネージャーの確認
    local pkg_mgr
    pkg_mgr=$(get_package_manager_platform)

    log_debug "$pkg_mgr バージョン: $("$pkg_mgr" --version 2>/dev/null | head -n1 || echo 'unknown')"
    log_success "RHEL/Fedora系プラットフォーム環境の確認完了 (パッケージマネージャー: $pkg_mgr)"
    return 0
}

get_platform_info() {
    # プラットフォーム情報を表示

    local pkg_mgr
    pkg_mgr=$(get_package_manager_platform)

    cat <<EOF
プラットフォーム: RHEL/Fedora系 ($pkg_mgr)
パッケージマネージャー: $pkg_mgr
証明書ディレクトリ: /etc/pki/ca-trust/source/anchors/
証明書更新コマンド: update-ca-trust extract
対応ディストリビューション: Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux
EOF
}

# ============================================================================
# 接続テスト（RHEL/Fedora系固有）
# ============================================================================

test_certificate_connectivity() {
    # 証明書インストール後の接続テストを実行
    # 引数: なし (デフォルトで www.google.com:443 をテスト)

    local test_host="${1:-www.google.com}"
    local test_port="${2:-443}"

    log_info "証明書インストール後の接続テスト: openssl s_client -connect ${test_host}:${test_port}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] openssl s_client -connect ${test_host}:${test_port} -CAfile /etc/pki/tls/certs/ca-bundle.crt"
        return 0
    fi

    if ! openssl s_client -connect "${test_host}:${test_port}" -CAfile /etc/pki/tls/certs/ca-bundle.crt < /dev/null 2>/dev/null | grep -q 'Verify return code: 0 (ok)'; then
        log_error "openssl s_client による接続テストに失敗しました (証明書ストアの反映を確認してください)"
        return 1
    else
        log_success "openssl s_client による接続テスト成功 (証明書ストアが有効です)"
        return 0
    fi
}

# ============================================================================
# EPEL リポジトリ管理（RHEL/CentOS固有）
# ============================================================================

enable_epel_repository() {
    # EPEL (Extra Packages for Enterprise Linux) リポジトリを有効化
    # CentOS/RHEL環境で一部のパッケージに必要

    log_info "EPEL リポジトリの状態をチェック中..."

    local pkg_mgr
    pkg_mgr=$(get_package_manager_platform)

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] EPELリポジトリの確認とインストール"
        return 0
    fi

    # EPELが既に利用可能かチェック
    if "$pkg_mgr" repolist enabled | grep -q epel; then
        log_info "EPEL リポジトリは既に有効です"
        return 0
    fi

    # EPELパッケージをインストール
    case "$pkg_mgr" in
        dnf)
            log_info "EPEL リポジトリを有効化中 (dnf)..."
            if sudo dnf install -y epel-release; then
                log_success "EPEL リポジトリが有効化されました"
                return 0
            else
                log_warning "EPEL リポジトリの有効化に失敗しました (続行します)"
                return 1
            fi
            ;;
        yum)
            log_info "EPEL リポジトリを有効化中 (yum)..."
            if sudo yum install -y epel-release; then
                log_success "EPEL リポジトリが有効化されました"
                return 0
            else
                log_warning "EPEL リポジトリの有効化に失敗しました (続行します)"
                return 1
            fi
            ;;
        *)
            log_warning "不明なパッケージマネージャー、EPEL リポジトリの有効化をスキップします"
            return 1
            ;;
    esac
}

# ============================================================================
