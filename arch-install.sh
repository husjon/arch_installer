cd $(dirname $(realpath $0))

info() {
    printf "$*\n"
}

wait_to_continue() {
    info "Press any key to continue"
    read -n 1
    info "\n\n\n"
}

STAGE=${1:-pre_install}

export SCRIPT_DIR=$(pwd)

OLD_PWD=${PWD}
cd instructions/${STAGE}
for instruction in `ls`; do
    echo "$executing $(realpath $instruction)"
    bash ./$instruction || wait_to_continue
done
cd $OLD_PWD
exit 0
