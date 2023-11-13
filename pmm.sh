#!/usr/bin/env bash

################################################################################
# MIT License
#
# Copyright (c) 2023 saihon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

# set -eux

NAME="$(basename "$0")"
readonly NAME
readonly VERSION="v0.0.1"

func_output_error() {
    echo "Error: $1." 1>&2
    exit 1
}

if [ -v PMM_JSON_FILE_PATH ]; then
    # Environmental variables
    JSON_FILE="$PMM_JSON_FILE_PATH"
elif [ "$(uname)" == 'Darwin' ]; then
    # MacOS
    JSON_FILE="$HOME/Library/Application/pmm/pmm.json"
elif [ "$(uname)" == 'Linux' ]; then
    # Linux
    # $XDG_DATA_HOME or $HOME/.local/share
    JSON_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/pmm/pmm.json"
else
    func_output_error "$(uname) is not supported"
fi

# Splits option name and value by '=' such as -c=command.
func_split_by_equals() {
    IFS='=' read -ra a <<<"$1"
    OPTION="${a[0]}"
    if [[ "${#a[@]}" -gt 1 ]]; then
        VALUE="${a[1]}"
        NO_SPLIT=false
    fi
}

func_verify_option() {
    if [[ "$1" =~ ^-([^-]+|$) ]] && [[ "$1" =~ ^-(.*[^$PATTERN_SHORT]+.*|)$ ]]; then
        func_output_error "invalid option -- ‘$1‘"
    fi
    if [[ "$1" =~ ^-{2,} ]] && [[ ! "$1" =~ ^-{2}($PATTERN_LONG)$ ]]; then
        func_output_error "invalid option -- ‘$1‘"
    fi
}

func_verify_required_option_error() {
    if [[ -z "$VALUE" ]]; then
        func_output_error "required argument ‘$OPTION‘"
    fi
    if "${NO_SPLIT}" && [[ "$VALUE" =~ ^-+ ]]; then
        func_output_error "invalid argument ‘$VALUE‘ for ‘$OPTION‘"
    fi
}

############################
# sub command add
############################
func_subcmd_add_usage() {
    printf "\nUsage: %s add [options] [package...]\n" "$NAME"
    printf "\nOptions:\n"
    printf "  -c, --command  Specifies the command.\n"
    printf "  -j, --json     Specifies the path of JSON file.\n"
    printf "  -n, --name     Specifies the name.\n"
    printf "  -h, --help     Show this help and exit.\n"
    printf "\n"
    exit 0
}

# (foo bar baz) to "foo", "bar", "baz"
func_array_join() {
    local v
    v=$(printf ",\"%s\"" "$@")
    # must use the echo
    echo "${v:1}"
}

func_subcmd_add() {
    # Select name
    if [ -z "$O_NAME" ]; then
        O_NAME="$(jq -e -M -r 'keys[]' "$JSON_FILE" | fzf --no-sort)"
    fi
    if [ -z "$O_NAME" ]; then
        func_output_error "No name specified or selected"
    fi

    local expression packages
    packages=$(func_array_join "${ARGV[@]}")

    if [ "$(jq -e -M --arg name "$O_NAME" 'any(keys[]; . == $name)' "$JSON_FILE")" == 'false' ]; then
        # If name is not there, create new
        expression=".[\$name] += {"cmds":[\$cmds],"pkgs":[$packages]}"
    elif [ -n "$O_COMMAND" ] && [ -n "$packages" ]; then
        expression=".[\$name].cmds += [\$cmds] | .[\$name].pkgs += [$packages]"
    elif [ -n "$O_COMMAND" ]; then
        expression=".[\$name].cmds += [\$cmds]"
    elif [ -n "$packages" ]; then
        expression=".[\$name].pkgs += [$packages]"
    fi
    # Remove duplicated value and empty value
    expression="$expression | .[\$name].cmds |= map(select(length > 0)) | .[\$name].cmds |= unique"
    expression="$expression | .[\$name].pkgs |= map(select(length > 0)) | .[\$name].pkgs |= unique"

    local v
    if v=$(jq -e -M --arg name "$O_NAME" --arg cmds "$O_COMMAND" "$expression" "$JSON_FILE"); then
        [ -n "$v" ] && echo -e "$v" >"$JSON_FILE"
    fi
}

func_subcmd_add_set_value() {
    if [[ "$OPTION" =~ ^(-[^-]*c|--command$) ]]; then
        func_verify_required_option_error
        O_COMMAND="$VALUE"
        if "${NO_SPLIT}"; then SKIP_NEXT=true; fi
    fi
    if [[ "$OPTION" =~ ^(-[^-]*j|--json$) ]]; then
        func_verify_required_option_error
        JSON_FILE="$VALUE"
        "${NO_SPLIT}" && SKIP_NEXT=true
    fi
    if [[ "$OPTION" =~ ^(-[^-]*n|--name$) ]]; then
        func_verify_required_option_error
        O_NAME="$VALUE"
        if "${NO_SPLIT}"; then SKIP_NEXT=true; fi
    fi
}

########################
# sub command edit
########################
func_subcmd_edit_usage() {
    printf "\nUsage: %s edit [options]\n" "$NAME"
    printf "\nOptions:\n"
    printf "  -c, --command  Specifies the command name to use.\n"
    printf "                 By default is \$EDITOR.\n"
    printf "  -j, --json     Specifies the path of JSON file.\n"
    printf "  -h, --help     Show this help and exit.\n"
    printf "\n"
    exit 0
}

func_subcmd_edit() {
    if ! type "$O_COMMAND" >/dev/null 2>&1; then
        func_output_error "Command ‘$O_COMMAND‘ not found"
    fi
    eval "$O_COMMAND $JSON_FILE"
}

func_subcmd_edit_set_value() {
    if [[ "$OPTION" =~ ^(-[^-]*c|--command$) ]]; then
        func_verify_required_option_error
        O_COMMAND="$VALUE"
        if "${NO_SPLIT}"; then SKIP_NEXT=true; fi
    fi
    if [[ "$OPTION" =~ ^(-[^-]*j|--json$) ]]; then
        func_verify_required_option_error
        JSON_FILE="$VALUE"
        "${NO_SPLIT}" && SKIP_NEXT=true
    fi
}

########################
# sub command install
########################
func_subcmd_install_usage() {
    printf "\nUsage: %s install [options] [package...]\n" "$NAME"
    printf "\nOptions:\n"
    printf "  -a, --add          Add and install packages.\n"
    printf "      --all          Install all packages.\n"
    printf "  -c, --command      Specifies the command.\n"
    printf "  -i, --interactive  Prompt once before installation.\n"
    printf "  -j, --json         Specifies the path of JSON file.\n"
    printf "  -n, --name         Specifies the name.\n"
    printf "  -h, --help         Show this help and exit.\n"
    printf "\n"
    exit 0
}

func_subcmd_install() {
    # Select name
    if [ -z "$O_NAME" ]; then
        O_NAME="$(jq -e -M -r 'keys[]' "$JSON_FILE" | fzf --select-1 --no-sort)"
    fi
    if [ -z "$O_NAME" ]; then exit 0; fi

    # Checking it name is there or not
    if [ "$(jq -e -M --arg name "$O_NAME" 'any(keys[]; . == $name)' "$JSON_FILE")" == 'false' ]; then
        func_output_error "Name ‘$O_NAME‘ not found"
    fi

    # Add command and package
    if "${O_ADD}"; then
        if [ -n "$O_COMMAND" ] || [[ $ARGC -gt 0 ]]; then
            func_subcmd_add
        fi
    fi

    # Select command
    if [ -z "$O_COMMAND" ]; then
        O_COMMAND="$(jq -e -M -r --arg name "$O_NAME" '.[$name].cmds[]' "$JSON_FILE" | fzf --select-1 --no-sort)"
    fi
    if [ -z "$O_COMMAND" ]; then exit 0; fi

    # Select packages
    local packages
    if "${O_ALL}"; then
        packages="$(jq -e -M -r --arg name "$O_NAME" '.[$name].pkgs[]' "$JSON_FILE")"
    else
        packages="$(jq -e -M -r --arg name "$O_NAME" '.[$name].pkgs[]' "$JSON_FILE" | fzf --multi --no-sort)"
    fi
    if [ -z "$packages" ]; then exit 0; fi

    # If do not assign initial value, $pkgs is occuor 'unbound variable' error.
    local pkgs=''
    # Change line break to space
    local v
    while read -r v; do pkgs="$pkgs $v"; done <<<"$packages"

    if "${O_INTERACTIVE}"; then
        local input
        # Beginning of variable $pkgs is blank space.
        echo "${O_COMMAND}${pkgs}"
        read -r -p "OK to run it? (y/N): " input
        case "$input" in
        y | Y | yes | Yes) ;;
        *) exit 0 ;;
        esac
    fi

    # Look up
    if ! type "${O_COMMAND%% *}" >/dev/null 2>&1; then
        func_output_error "command ${O_COMMAND%% *} not found"
    fi

    # Beginning of variable $pkgs is blank space.
    eval "${O_COMMAND}${pkgs}"
}

func_subcmd_install_set_value() {
    if [[ "$OPTION" =~ ^(-[^-]*a|--add$) ]]; then O_ADD=true; fi
    if [[ "$OPTION" =~ ^--all$ ]]; then O_ALL=true; fi
    if [[ "$OPTION" =~ ^(-[^-]*i|--interactive$) ]]; then O_INTERACTIVE=true; fi
    if [[ "$OPTION" =~ ^(-[^-]*c|--command$) ]]; then
        func_verify_required_option_error
        O_COMMAND="$VALUE"
        "${NO_SPLIT}" && SKIP_NEXT=true
    fi
    if [[ "$OPTION" =~ ^(-[^-]*j|--json$) ]]; then
        func_verify_required_option_error
        JSON_FILE="$VALUE"
        "${NO_SPLIT}" && SKIP_NEXT=true
    fi
    if [[ "$OPTION" =~ ^(-[^-]*n|--name$) ]]; then
        func_verify_required_option_error
        O_NAME="$VALUE"
        "${NO_SPLIT}" && SKIP_NEXT=true
    fi
}

# Check file is empty or not
func_check_file_empty() {
    if ! test -s "$JSON_FILE" >/dev/null 2>&1; then
        echo '{}' >"$JSON_FILE"
    fi
}

func_subcmd_parse_arguments() {
    local -i ARGC=0
    local -a ARGV=()

    local output_usage

    # common option variables
    local O_COMMAND=""
    local O_NAME=""

    case "$SUBCMD" in
    add)
        output_usage=func_subcmd_add_usage

        readonly PATTERN_SHORT="cjn"
        readonly PATTERN_LONG="command|json|name"
        ;;
    edit)
        output_usage=func_subcmd_edit_usage

        O_COMMAND="${EDITOR:-vi}"
        readonly PATTERN_SHORT="cj"
        readonly PATTERN_LONG="command|json"
        ;;
    install)
        output_usage=func_subcmd_install_usage

        local O_ALL=false
        local O_ADD=false
        local O_INTERACTIVE=false

        readonly PATTERN_SHORT="acijn"
        readonly PATTERN_LONG="add|all|command|interactive|json|name"
        ;;

    esac

    while (($# > 0)); do
        case "$1" in
        -h | --help) $output_usage ;;
        -*)
            local NO_SPLIT=true
            local SKIP_NEXT=false
            local OPTION="$1"
            local VALUE=""
            if [ -v 2 ]; then VALUE="$2"; fi
            func_split_by_equals "$OPTION"
            func_verify_option "$OPTION"

            case "$SUBCMD" in
            add) func_subcmd_add_set_value ;;
            edit) func_subcmd_edit_set_value ;;
            install) func_subcmd_install_set_value ;;
            esac

            if "${SKIP_NEXT}"; then shift; fi
            shift
            ;;
        *)
            ((++ARGC))
            ARGV+=("$1")
            shift
            ;;
        esac
    done

    readonly JSON_FILE
    if [ -z "$JSON_FILE" ]; then
        func_output_error "JSON file path not set"
    fi

    [ ! -d "$(dirname "$JSON_FILE")" ] && mkdir -p "$(dirname "$JSON_FILE")"
    [ ! -f "$JSON_FILE" ] && echo '{}' >"$JSON_FILE"

    case "$SUBCMD" in
    add)
        if [[ $ARGC -eq 0 ]] && [ -z "$O_COMMAND" ]; then
            func_subcmd_add_usage
        fi
        func_check_file_empty
        func_subcmd_add
        ;;
    edit)
        func_check_file_empty
        func_subcmd_edit
        ;;
    install)
        func_check_file_empty
        func_subcmd_install
        ;;
    esac
    exit $?
}

func_output_version() {
    echo "$NAME: $VERSION"
    exit 0
}

func_output_usage() {
    printf "\nUsage: %s command [options] [package...]\n" "$NAME"
    printf "\nCommands:\n"
    printf "  add      Add package and command\n"
    printf "  edit     Edit JSON file.\n"
    printf "  install  Install packages.\n"
    printf "  help     Show this help and exit.\n"
    printf "  version  Output version and exit.\n"
    printf "\n"
    exit 0
}

if [[ $# -eq 0 ]]; then func_output_usage; fi
if ! type fzf >/dev/null 2>&1; then
    func_output_error "fzf command not installed"
fi
if ! type jq >/dev/null 2>&1; then
    func_output_error "jq command not installed"
fi

readonly SUBCMD="$1" && shift
case "$SUBCMD" in
add | edit | install)
    func_subcmd_parse_arguments "$@"
    ;;
-v | --version | version)
    func_output_version
    ;;
*)
    func_output_usage
    ;;
esac
