#!/bin/bash

declare -A versions=(
    [16.04]="yes"
    [18.04]="yes"
    [20.04]="yes"
    [22.04]="yes"
)

build() {
    ver=$1
    dev=$2

    tag="umtdg/ubuntu:$ver"
    dockerfile="$ver/Dockerfile"
    if [ "$dev" == "yes" ]; then
        tag="$tag-dev"
        dockerfile="$dockerfile.dev"
    fi

    [[ -d "$ver" ]] || { echo "Could not found $ver"; exit 1; }
    [[ -f "$dockerfile" ]] || { echo "Could not found $dockerfile"; exit 1; }

    echo -e "Building $tag\n"
    docker buildx build --file $dockerfile --tag $tag $ver
}

build_all() {
    for key in "${!versions[@]}"; do
        build $key no
        echo

        build $key yes
        echo
    done
}

push() {
    tag="umtdg/ubuntu:$1"
    [[ "$2" == "yes" ]] && tag="$tag-dev"

    echo -e "Pushing $tag\n"
    docker push $tag
}

push_all() {
    for key in "${!versions[@]}"; do
        push $key no
        echo

        push $key yes
        echo
    done
}

version=""
do_dev="no"
do_push="no"
do_push_only="no"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dev|--developer) do_dev="yes"; shift; ;;
        -v|--ver|--versions) version="$2"; shift 2; ;;
        -p|--push) do_push="yes"; shift; ;;
        -P|--push-only) do_push_only="yes"; shift; ;;
        *) shift; ;;
    esac
done

if [ -z "$version" ]; then
    if [ "$do_push_only" == "yes" ]; then
        push_all
    else
        build_all
        [[ "$do_push" == "yes" ]] && push_all
    fi
elif [ "${versions[$version]}" == "yes" ]; then
    if [ "$do_push_only" == "yes" ]; then
        push $version $do_dev
    else
        build $version $do_dev
        [[ "$do_push" == "yes" ]] && push $version $do_dev
    fi
else
    echo "Unknown version: $version"
fi

