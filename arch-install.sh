info() {
    printf "$*\n"
}

wait_to_continue() {
    info "Press any key to continue"
    read -n 1
    info "\n\n\n"
}

STAGE=${1:-pre_install}

cd $(dirname $(realpath $0))

OLD_PWD=${PWD}
cd instructions/${STAGE}
for instruction in `ls`; do
    bash ./$instruction || wait_to_continue
done
cd $OLD_PWD
exit 0
