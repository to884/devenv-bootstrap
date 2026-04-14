#!/usr/bin/env bash
# ============================================================================
# Zscaler証明書検証スクリプト
# ============================================================================
#
# 目的:
#   Zscaler証明書がシステム証明書ストアに正しく登録されているかを検証します。
#
# 対応ディストリビューション:
#   - Ubuntu/Debian (apt)
#   - RHEL/CentOS/Fedora (dnf/yum)
#   - Arch Linux (pacman)
#
# 使用方法:
#   ./verify-zscaler-cert.sh [オプション]
#
# オプション:
#   -v, --verbose   詳細な出力を表示
#   -h, --help      このヘルプメッセージを表示
#
# 終了コード:
#   0 - 証明書は正しく登録されています
#   1 - 証明書が未登録、または登録に問題があります
#   2 - 証明書が無効です
#   3 - サポート外のプラットフォーム
#
# 使用例:
#   ./verify-zscaler-cert.sh
#   ./verify-zscaler-cert.sh --verbose
#
# ============================================================================

set -Eeuo pipefail

# ============================================================================
# 変数の初期化
# ============================================================================

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# スクリプト名を設定（common.sh を source する前に設定）
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# 共通関数ライブラリを読み込み
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

VERBOSE="${VERBOSE:-false}"

# ============================================================================
# 引数解析
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                log_error "不明なオプション: $1"
                show_usage
                ;;
        esac
    done
}

# ============================================================================
# 使用方法表示
# ============================================================================

show_usage() {
    cat <<EOF
使用方法: $SCRIPT_NAME [オプション]

Zscaler証明書がシステム証明書ストアに正しく登録されているかを検証します。

オプション:
  -v, --verbose   詳細な出力を表示
  -h, --help      このヘルプメッセージを表示

終了コード:
  0 - 証明書は正しく登録されています
  1 - 証明書が未登録、または登録に問題があります
  2 - 証明書が無効です
  3 - サポート外のプラットフォーム

使用例:
  $SCRIPT_NAME
  $SCRIPT_NAME --verbose

EOF
    exit 0
}

# ============================================================================
# 証明書検証
# ============================================================================

verify_zscaler_certificate() {
    # Zscaler証明書の登録状況を検証
    
    local distro
    distro=$(detect_linux_distro)
    
    log_info "プラットフォームを検出: $distro"
    
    # 証明書バンドルとストアのパスを取得
    local cert_bundle
    cert_bundle=$(get_cert_bundle_path "$distro")
    
    local cert_store
    cert_store=$(get_cert_store_path "$distro")
    
    if [[ -z "$cert_bundle" ]] || [[ -z "$cert_store" ]]; then
        log_error "サポート外のプラットフォーム: $distro"
        return 3
    fi
    
    log_debug "証明書バンドルパス: $cert_bundle"
    log_debug "証明書ストアパス: $cert_store"
    
    # ソース証明書ファイルの確認
    local source_cert="${HOME}/.certs/ZscalerRootCA.cer"
    local source_pem="${HOME}/.certs/ZscalerRootCA.pem"
    
    local found_source=false
    if [[ -f "$source_cert" ]]; then
        log_info "✓ ソース証明書が見つかりました: $source_cert"
        found_source=true
    fi
    
    if [[ -f "$source_pem" ]]; then
        log_info "✓ 変換済み証明書が見つかりました: $source_pem"
        found_source=true
    fi
    
    if [[ "$found_source" == "false" ]]; then
        log_warning "✗ ソース証明書が見つかりません: ~/.certs/ZscalerRootCA.{cer,pem}"
        log_warning "  証明書ファイルを配置してから bootstrap.sh を実行してください"
    fi
    
    # システム証明書ストアの確認
    local system_cert_pattern="ZscalerRootCA"
    local found_system=false
    
    if find "$cert_store" -type f -name "*${system_cert_pattern}*" 2>/dev/null | grep -q .; then
        log_success "✓ システム証明書ストアに Zscaler 証明書が見つかりました"
        find "$cert_store" -type f -name "*${system_cert_pattern}*" 2>/dev/null | while read -r file; do
            log_debug "  - $file"
        done
        found_system=true
    else
        log_error "✗ システム証明書ストアに Zscaler 証明書が見つかりません"
        log_error "  期待されるパス: $cert_store/*${system_cert_pattern}*"
        found_system=false
    fi
    
    # 証明書バンドルの確認
    if [[ -f "$cert_bundle" ]]; then
        if grep -q "Zscaler" "$cert_bundle" 2>/dev/null; then
            log_success "✓ 証明書バンドルに Zscaler 証明書が含まれています"
            log_debug "  証明書バンドル: $cert_bundle"
        else
            log_error "✗ 証明書バンドルに Zscaler 証明書が含まれていません"
            log_error "  証明書バンドル: $cert_bundle"
            log_error "  証明書ストアを更新する必要があります"
            found_system=false
        fi
    else
        log_error "✗ 証明書バンドルが見つかりません: $cert_bundle"
        found_system=false
    fi
    
    # openssl による証明書の検証（オプション）
    if command -v openssl >/dev/null 2>&1 && [[ -f "$source_pem" ]]; then
        log_info "証明書の有効性を確認中..."
        
        if openssl x509 -noout -text -in "$source_pem" >/dev/null 2>&1; then
            log_success "✓ 証明書は有効なPEM形式です"
            
            # 証明書の詳細情報を表示
            if [[ "$VERBOSE" == "true" ]]; then
                local subject
                subject=$(openssl x509 -noout -subject -in "$source_pem" 2>/dev/null | sed 's/^subject=//')
                log_debug "  Subject: $subject"
                
                local issuer
                issuer=$(openssl x509 -noout -issuer -in "$source_pem" 2>/dev/null | sed 's/^issuer=//')
                log_debug "  Issuer: $issuer"
                
                local not_before
                not_before=$(openssl x509 -noout -startdate -in "$source_pem" 2>/dev/null | sed 's/^notBefore=//')
                log_debug "  有効期限開始: $not_before"
                
                local not_after
                not_after=$(openssl x509 -noout -enddate -in "$source_pem" 2>/dev/null | sed 's/^notAfter=//')
                log_debug "  有効期限終了: $not_after"
            fi
        else
            log_error "✗ 証明書が無効です: $source_pem"
            return 2
        fi
    fi
    
    # 結果判定
    if [[ "$found_system" == "true" ]]; then
        log_success ""
        log_success "========================================"
        log_success "Zscaler証明書は正しく登録されています"
        log_success "========================================"
        return 0
    else
        log_error ""
        log_error "========================================"
        log_error "Zscaler証明書が未登録、または問題があります"
        log_error "========================================"
        log_error ""
        log_error "対処方法:"
        log_error "1. 証明書ファイルを配置: ~/.certs/ZscalerRootCA.cer"
        log_error "2. bootstrap.sh を実行して証明書を登録"
        log_error "3. このスクリプトで再確認"
        return 1
    fi
}

# ============================================================================
# メイン処理
# ============================================================================

main() {
    parse_arguments "$@"
    
    log_info "Zscaler証明書の検証を開始します"
    log_debug "Verboseモード: $VERBOSE"
    
    # verify_zscaler_certificate の戻り値を取得
    # set -e によるエラー伝播を防ぐため、明示的に戻り値を処理
    local exit_code=0
    verify_zscaler_certificate || exit_code=$?
    
    exit $exit_code
}

# スクリプト実行
main "$@"
