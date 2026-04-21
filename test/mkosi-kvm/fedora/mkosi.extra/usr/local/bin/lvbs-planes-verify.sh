#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="[LVBS-PLANES-VERIFY]"
PLANES_CONF="/etc/lvbs/planes.conf"
LOG_FILE="/var/log/lvbs-planes-verify.log"

log_info() {
    echo "$LOG_TAG INFO: $*" | tee -a "$LOG_FILE"
    systemd-cat -t lvbs-planes-verify -p info echo "$*" || true
}

log_error() {
    echo "$LOG_TAG ERROR: $*" | tee -a "$LOG_FILE" >&2
    systemd-cat -t lvbs-planes-verify -p err echo "$*" || true
}

log_success() {
    echo "$LOG_TAG SUCCESS: $*" | tee -a "$LOG_FILE"
    systemd-cat -t lvbs-planes-verify -p info echo "$*" || true
}

mkdir -p /var/log
: > "$LOG_FILE"

log_info "=== Starting VTL0/VTL1 Plane Verification ==="
log_info "Kernel: $(uname -r)"

if [ ! -f "$PLANES_CONF" ]; then
    log_error "Planes configuration not found at $PLANES_CONF"
    exit 1
fi

# shellcheck disable=SC1090
source "$PLANES_CONF"

log_info "Loaded plane configuration:"
log_info "  VTL0 kernel: $LVBS_VTL0_KERNEL ($LVBS_VTL0_TYPE)"
log_info "  VTL1 kernel: $LVBS_VTL1_KERNEL ($LVBS_VTL1_TYPE)"
log_info "  VTL1 loader: ${LVBS_VTL1_LOADER:-unset}"
log_info "  VTL1 target plane: ${LVBS_VTL1_TARGET_PLANE:-unset}"
log_info "  VTL1 load offset: $LVBS_VTL1_LOAD_OFFSET"

if [ "${LVBS_VTL1_TARGET_PLANE:-}" != "1" ]; then
    log_error "VTL1 target plane must be 1, got '${LVBS_VTL1_TARGET_PLANE:-unset}'"
    exit 1
fi

if [ -f "$LVBS_VTL0_KERNEL" ]; then
    current_sha="$(sha256sum "$LVBS_VTL0_KERNEL" | awk '{print $1}')"
    log_info "VTL0 SHA256 expected: $LVBS_VTL0_SHA256"
    log_info "VTL0 SHA256 actual:   $current_sha"
    if [ "$current_sha" = "$LVBS_VTL0_SHA256" ]; then
        log_success "VTL0 kernel hash verification passed"
    else
        log_error "VTL0 kernel hash verification failed"
    fi
else
    log_error "VTL0 kernel missing at $LVBS_VTL0_KERNEL"
fi

if [ -f "$LVBS_VTL1_KERNEL" ]; then
    current_sha="$(sha256sum "$LVBS_VTL1_KERNEL" | awk '{print $1}')"
    log_info "VTL1 SHA256 expected: $LVBS_VTL1_SHA256"
    log_info "VTL1 SHA256 actual:   $current_sha"
    log_info "VTL1 target plane:    $LVBS_VTL1_TARGET_PLANE"
    log_info "VTL1 load offset:     $LVBS_VTL1_LOAD_OFFSET"
    if [ "$current_sha" = "$LVBS_VTL1_SHA256" ]; then
        log_success "VTL1 kernel hash verification passed"
        log_info "VTL1 is ready to be loaded by VTL0 at $LVBS_VTL1_LOAD_OFFSET and entered in Plane $LVBS_VTL1_TARGET_PLANE"
    else
        log_error "VTL1 kernel hash verification failed"
    fi
else
    log_error "VTL1 kernel missing at $LVBS_VTL1_KERNEL"
fi

if [ -n "${LVBS_VTL1_LOADER:-}" ]; then
    if [ -f "$LVBS_VTL1_LOADER" ]; then
        loader_sha="$(sha256sum "$LVBS_VTL1_LOADER" | awk '{print $1}')"
        log_info "VTL1 loader SHA256 expected: ${LVBS_VTL1_LOADER_SHA256:-unset}"
        log_info "VTL1 loader SHA256 actual:   $loader_sha"
        if [ -n "${LVBS_VTL1_LOADER_SHA256:-}" ] && [ "$loader_sha" = "$LVBS_VTL1_LOADER_SHA256" ]; then
            log_success "VTL1 loader hash verification passed"
        elif [ -n "${LVBS_VTL1_LOADER_SHA256:-}" ]; then
            log_error "VTL1 loader hash verification failed"
        else
            log_info "VTL1 loader hash baseline not set; presence-only verification passed"
        fi
    else
        log_error "VTL1 loader missing at $LVBS_VTL1_LOADER"
    fi
fi

log_info "=== Plane Verification Complete ==="
