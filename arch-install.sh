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
cd instructions/${SCRIPT_STAGE}
for instruction in `ls`; do
    echo "$executing $(realpath $instruction)"
    bash ./$instruction || wait_to_continue
done
cd $OLD_PWD
exit 0
