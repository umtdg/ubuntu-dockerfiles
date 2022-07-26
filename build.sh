#!/bin/bash

build() {
    folder="$1"
    dev="$2"

    tag="umtdg/${folder}:latest"
    dockerfile="${folder}/Dockerfile"
    [[ "${dev}" == "yes" ]] && dockerfile="${dockerfile}.dev"

    [[ -d "${folder}" ]] && echo "Found folder ${folder}" || { echo "Could not found ${folder}"; exit 1; }
    [[ -f "${dockerfile}" ]] && echo "Found Dockerfile ${dockerfile}" || { echo "Could not found Dockerfile ${dockerfile}"; exit 1; }

    echo "Building ${tag}"
    docker build -t "${tag}" -f "${dockerfile}" "${folder}"

    echo "Pushing ${tag}"
    docker push "${tag}"
}

for distro in $(find . -type d -regextype posix-extended -regex '.*[0-9]{2}\.04' -exec basename {} \;)
do
    build "${distro}" "no"
    build "${distro}" "yes"
done
