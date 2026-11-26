#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [LIBRENMS_DIRECTORY]\nDefault: /opt/librenms\n' "${0##*/}"
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    usage
    exit 0
fi
if (( $# > 1 )); then
    usage >&2
    exit 2
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
librenms_dir=${1:-/opt/librenms}
php_file=LibreNMS/OS/SensaphoneWeb600.php
files=(
    resources/definitions/os_detection/sensaphone-web600.yaml
    "$php_file"
    html/images/os/sensaphone-web600.svg
)
reference_names=(generic.yaml Generic.php generic.svg)

if [[ ! -f $librenms_dir/lnms ]]; then
    printf 'LibreNMS was not found in %s\n' "$librenms_dir" >&2
    exit 1
fi

for index in "${!files[@]}"; do
    file=${files[index]}
    source=$source_dir/$file
    destination=$librenms_dir/$file
    reference=${destination%/*}/${reference_names[index]}
    if [[ ! -f $source ]]; then
        printf 'Missing package file %s\n' "$source" >&2
        exit 1
    fi
    if [[ ! -f $reference || -L $reference ]]; then
        printf 'Expected a regular LibreNMS file to match ownership at %s\n' "$reference" >&2
        exit 1
    fi
    if [[ -L $destination || -e $destination ]]; then
        if [[ -L $destination || ! -f $destination ]] || ! cmp -s -- "$source" "$destination"; then
            printf 'Existing file differs or is not a regular file. Review %s before installing.\n' "$destination" >&2
            exit 1
        fi
    fi
done

php -l "$source_dir/$php_file" >/dev/null

for index in "${!files[@]}"; do
    file=${files[index]}
    destination=$librenms_dir/$file
    reference=${destination%/*}/${reference_names[index]}
    if [[ ! -L $destination && -f $destination ]] && cmp -s -- "$source_dir/$file" "$destination"; then
        if [[ $(stat -c '%u:%g' -- "$destination") != $(stat -c '%u:%g' -- "$reference") ]]; then
            chown --no-dereference --reference="$reference" -- "$destination"
        fi
        continue
    fi

    temporary_file=$(mktemp -- "${destination%/*}/.web600-install.XXXXXXXX")
    trap 'rm -f -- "$temporary_file"' EXIT
    install -m 0644 -- "$source_dir/$file" "$temporary_file"
    if [[ $(stat -c '%u:%g' -- "$temporary_file") != $(stat -c '%u:%g' -- "$reference") ]]; then
        chown --reference="$reference" -- "$temporary_file"
    fi
    # Link the completed file into place without overwriting a file created concurrently.
    if ! ln -T -- "$temporary_file" "$destination"; then
        printf 'Could not install %s. Check the destination and run the installer again.\n' "$destination" >&2
        exit 1
    fi
    rm -f -- "$temporary_file"
    trap - EXIT
done

printf 'WEB600 support is installed in %s\n' "$librenms_dir"
