cd $(dirname $(realpath $0))

source ./global-variables.sh
source ./user-variables.sh

info() {
    printf "$*\n"
}

wait_to_continue() {
    info "Press any key to continue"
    read -n 1
    info "\n\n\n"
}

SCRIPT_STAGE=${1:-pre_install}
export SCRIPT_DIR=$(pwd)

OLD_PWD=${PWD}
for instruction in `ls`; do
    cd instructions/${SCRIPT_STAGE}
    echo "executing $(realpath $instruction)"
    bash ./$instruction || wait_to_continue
    echo "finished  $(realpath $instruction)"
    cd ${OLD_PWD}
done
cd $OLD_PWD
exit 0
