#!/bin/bash

docker="docker"
if ! id -nG $USER | grep -qw docker; then
    docker="sudo $docker"
fi

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
    tag_ulak="registry.ulakhaberlesme.com.tr/cinar/epc/ubuntu:$ver"

    dockerfile="$ver/Dockerfile"
    if [ "$dev" == "yes" ]; then
        tag="$tag-dev"
        tag_ulak="$tag_ulak-dev"
        dockerfile="$dockerfile.dev"
    fi

    if $docker images --format '{{.Repository}}:{{.Tag}}' | grep -Pq "^${tag}\$" && [ "$do_ulak" == "yes" ]; then
        echo -e "Image $tag already exists. Tagging '$tag' -> '$tag_ulak'\n"
        $docker image tag "$tag" "$tag_ulak"
        return
    fi

    [[ -d "$ver" ]] || { echo "Could not found $ver"; exit 1; }
    [[ -f "$dockerfile" ]] || { echo "Could not found $dockerfile"; exit 1; }

    echo -e "Building $tag\n"
    $docker buildx build --file $dockerfile --tag $tag $ver

    [[ "$do_ulak" == 'yes' ]] && $docker tag $tag $tag_ulak
}

build_all() {
    for key in "${!versions[@]}"; do
        build $key $do_dev
        echo
    done
}

push() {
    tag="umtdg/ubuntu:$1"
    [[ "$do_ulak" == "yes" ]] && tag="registry.ulakhaberlesme.com.tr/cinar/epc/ubuntu:$1"

    [[ "$2" == "yes" ]] && tag="$tag-dev"

    echo -e "Pushing $tag\n"
    $docker push $tag
}

push_all() {
    for key in "${!versions[@]}"; do
        push $key $do_dev
        echo
    done
}

function usage() {
    echo "Usage:"
    echo "  $0 [OPTIONS...]"
    echo ""
    echo "Options:"
    echo "  -d | --dev          Build/push developer versions"
    echo "  -v | --ver          Ubuntu version. One of 16.04, 18.04, 20.04, 22.04"
    echo "  -p | --push         Push built images"
    echo "  -P | --push-only    Push images without building first"
    echo "  -u | --ulak         Push images to Ulak's repos"
    echo "  -h | --help         Show this help"
}

version=""
do_dev="no"
do_push="no"
do_push_only="no"
do_ulak="no"

args="$(getopt -o dpPuv:h, -l dev,push,push-only,ulak,ver:,help --name "$0" -- "$@")"
eval set -- "$args"

while true; do
    case "$1" in
        -d|--dev|--developer) do_dev="yes"; shift; ;;
        -v|--ver|--version) version="$2"; shift 2; ;;
        -p|--push) do_push="yes"; shift; ;;
        -P|--push-only) do_push_only="yes"; shift; ;;
        -u|--ulak) do_ulak="yes"; shift; ;;
        -h|--help) usage; exit 0; ;;
        --) shift; break; ;;
        *) echo "Unknown option $1"; exit 1; ;;
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

