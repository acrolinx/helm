#!/bin/sh
set -ef

usage()
{
    cat <<EOF
Usage:

$0 [options]

Options:
  -h                Print this help message and exit.
  -o <directory>    Output directory (defaults to '.')
  -n <namespace>    Acrolinx namespace (defaults to current namespace: ${curns})
  -s <namespace>    Operator installation namespace (defaults to acrolinx-system)
  -v                Verbose?
  -Z                Do not create an archive, and do not delete the support archive directory.
EOF
}

log() {
    if [ "${verbose?}" -eq 0 ]; then
        return
    fi

    printf '%s\n' "$*"
}

verbose=0
zip=1
outDir=.
sysns=acrolinx-system

curns=$(kubectl config view --minify --output 'jsonpath={..namespace}' || true)
[ -z "${curns?}" ] && curns=default

while getopts "ho:n:s:vZ" opt; do
    case "${opt?}" in
        h)
            usage
            exit 0
            ;;
        o)  outDir=${OPTARG?};;
        n)  curns=${OPTARG?};;
        s)  sysns=${OPTARG?};;
        v)  verbose=1;;
        Z)  zip=0;;
        '?')
            # error while parsing options:
            echo
            usage
            exit 1
            ;;
        *)
            echo "BUG: Unhandled option: ${opt?}"
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

[ x"$1" = x"--" ] && shift

if [ $# -gt 0 ]; then
  echo "Unexpected arguments: $*"
  echo
  usage
  exit 1
fi

if [ ${zip?} -eq 1 ] && ! command -v gzip >/dev/null; then
    echo "FATAL: gzip must be installed to create an archive."
    exit 1
fi

# ISO 8601
timestamp=$(date -u "+%Y%m%dT%H%M%SZ")
targetBase=support-package-${timestamp?}
targetDir=${outDir?}/${targetBase?}

log "🎬 Creating support package in '${targetDir?}'..."
mkdir -p "${targetDir?}"

log "⌚ Recording snapshot time..."
echo "${timestamp?}" >"${targetDir?}"/snapshot_time.txt

log "✉️  Recording default namespace..."
{ kubectl config view --minify --output 'jsonpath={..namespace}' || true; echo; } \
    >"${targetDir?}/default-namespace.txt"

all_namespaces=$(kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers)
# NB: curns will be the namespace that the Acrolinx objects are in.
for ns in "${curns?}" acrolinx "${sysns?}" kube-system olm operators; do
    if ! printf '%s\n' "${all_namespaces?}" | grep -qxF "${ns?}"; then
        log "⚠️  Skipping non-existent namespace: ${ns?}"
        continue
    fi

    log "✉️  Processing namespace: ${ns?}"
    nsDir=${targetDir?}/${ns?}
    mkdir -p "${nsDir?}"

    log "💠 [${ns?}] Retrieving Kubernetes objects..."

    # retrieve installation objects
    if [ x"${ns?}" = x"${sysns?}" ]; then
        kubectl -n "${ns?}" get csv         >"${nsDir?}"/install-versions.txt || true
        kubectl -n "${ns?}" get ip -oyaml   >"${nsDir?}"/install-plans.txt || true
        kubectl -n "${ns?}" get cm -oyaml   >"${nsDir?}"/install-config-maps.txt || true
    fi

    # capture the general state of the installation
    if [ x"${ns?}" = x"${curns?}" ] || [ x"${ns?}" = x"acrolinx" ]; then
        kubectl -n "${ns?}" get events --sort-by='{.lastTimestamp}' -A \
            >"${nsDir?}"/k8s-events.txt || true
        kubectl -n "${ns?}" describe configmap -l app.kubernetes.io/name=impfo \
            >"${nsDir?}"/k8s-impfo-config-maps.txt || true
        kubectl -n "${ns?}" get coreplatforms -o yaml \
            >"${nsDir?}"/k8s-coreplatforms.txt || true
    fi

    kubectl -n "${ns?}" get all                 >"${nsDir?}"/k8s-all.txt || true
    kubectl -n "${ns?}" describe pods           >"${nsDir?}"/k8s-pods.txt || true
    kubectl -n "${ns?}" describe deployments    >"${nsDir?}"/k8s-deployments.txt || true

    if [ x"${ns?}" = x"${curns?}" ] || [ x"${ns?}" = x"acrolinx" ]; then
        log "📜 [${ns?}] Retrieving logs..."
        pods=$(kubectl -n "${ns?}" get pods -o jsonpath='{.items[*].metadata.name}')

        log "🚢 [${ns?}] Found pods: ${pods?}"
        for pod in ${pods?}; do
            kubectl -n "${ns?}" logs "${pod?}" --prefix --timestamps --all-containers \
                >"${nsDir?}/k8s-${pod?}-logs.txt" || true
            kubectl -n "${ns?}" logs "${pod?}" --prefix --timestamps --all-containers -p \
                >"${nsDir?}/k8s-${pod?}-logs.previous.txt" || true
        done
    fi

    if [ x"${ns?}" = x"${sysns?}" ]; then
        kubectl -n "${ns?}" logs -l control-plane=controller-manager \
            --prefix --all-containers --tail=-1  --timestamps \
            >"${nsDir?}"/k8s-operator-logs.txt || true
    fi

    kubectl -n "${ns?}" logs -l grab-logs=true \
        --prefix --all-containers --tail=-1  --timestamps \
        >"${nsDir?}"/k8s-other-logs.txt || true
done

log "📰 Add journald logs for acrolinx as zip file. Works only if this streaming logs to journald is enabled and the user is in group system-journald"
# --output-fields=ACROLINX_CONTAINER,ACROLINX_POD,ACROLINX_FILENAME,MESSAGE
# cannot use that parameter, because journalctl on redhat is too old, needs at least version 236
# this makes the gz file a bit bigger than necessary
journalctl --identifier=acrolinx -o json | gzip -9 > "${targetDir?}/journald.gz"

log "🎬 Created support package in '${targetDir?}'."

if [ ${zip?} -eq 1 ]; then
  # Delete the support package directory when we exit:
  trap 'rm -rf "${targetDir?}"' EXIT ABRT FPE ILL INT SEGV TERM

  zipFile="${outDir?}/support-package-${timestamp?}.tar.gz"
  log "🎁 Creating archive at '${zipFile?}', and removing support package directory '${targetDir?}'..."
  tar -caf "${zipFile?}" --force-local --posix -C "${outDir?}" "${targetBase?}"
fi

exit 0
