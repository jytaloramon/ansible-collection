#!/usr/bin/env bash


show_help(){
cat >&2 << EOF
Description:
    Scans all running containers and executes the specified script in containers where it is present.

Usage:
    $(basename $0) <script> [args]
    $(basename $0) --help
EOF
}

print_info(){
    echo "$(date +"[%Y-%m-%d %H:%M:%S %z]") [INFO] $@"
}

print_error(){
    echo "$(date +"[%Y-%m-%d %H:%M:%S %z]") [ERROR] $@" >&2
}

check_required_utils(){
    type docker &> /dev/null 
    
    if [[ "$?" -ne 0 ]]; then
        print_error "Docker not found."
        exit 1
    fi
}

get_containers_running(){
   local running="$(docker container ls --format='{{.Names}}' 2> /dev/null | tr '\n' ' ' )"

   read -ra containers_running <<< $running
}

_main(){
    if [[ "$#" -eq 0 || "$#" -eq 1 && "$1" == '--help' ]]; then
        show_help
        exit 0
    fi

    check_required_utils

    declare -a containers_running
    get_containers_running

    for ct in ${containers_running[@]}; do
        docker container exec $ct /bin/sh -c "test -x $1" &> /dev/null

        if [[ "$?" -eq 0 ]]; then
            docker container exec $ct /bin/sh -c "test -x $1 && $@" &> /dev/null
        
            [[ "$?" -eq 0 ]] \
                && print_info "Successful execution of \"$@\" in \"$ct\"" \
                || print_error "It was not possible to execute \"$@\" in the container \"$ct\"."
        fi
    done
}

_main "$@"

