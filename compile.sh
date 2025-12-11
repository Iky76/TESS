#!/bin/bash
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image.gz-dtb
kernel_name="HYPER_KERNEL-v3.3_MIDO"
zip_name="$kernel_name-$(date +"%d%m%Y-%H%M").zip"
TC_DIR=$HOME/tc/
CLANG_DIR=$TC_DIR/clang-r450784d

export CONFIG_FILE="mido_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=Prjct
export KBUILD_BUILD_USER=Rizj
export PATH="$CLANG_DIR/bin:$PATH"

# Colors
NC='\033[0m'
RED='\033[0;31m'
LGR='\033[1;32m'

# Clone toolchain if missing
if ! [ -d "$TC_DIR" ]; then
    echo "Toolchain not found! Cloning to $TC_DIR..."
    if ! git clone -q --depth=1 --single-branch \
        https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 \
        -b android12-release "$TC_DIR"; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

make_defconfig() {
    START=$(date +"%s")
    echo -e ${LGR}"########### Generating Defconfig ############"${NC}
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}

compile() {
    cd ${kernel_dir}
    echo -e ${LGR}"######### Compiling kernel #########"${NC}
    make -j$(nproc --all) \
        O=out \
        ARCH=${ARCH} \
        CC="ccache clang" \
        CLANG_TRIPLE="aarch64-linux-gnu-" \
        CROSS_COMPILE="aarch64-linux-gnu-" \
        CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
        LLVM=1 \
        LLVM_IAS=1
}

completion() {
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image.gz-dtb

    if [[ -f ${COMPILED_IMAGE} ]]; then
        echo -e ${LGR}"Kernel compiled successfully!"${NC}

        # Upload langsung Image.gz-dtb (tanpa AnyKernel)
        echo -e ${LGR}"Mengupload Image.gz-dtb..."${NC}
        curl --upload-file $ZIMAGE https://free.keep.sh
        echo

        END=$(date +"%s")
        DIFF=$(($END - $START))

        echo -e ${LGR}"############################################"
        echo -e ${LGR}"############# OkThisIsEpic!  ##############"
        echo -e ${LGR}"############################################"${NC}
        exit 0
    else
        echo -e ${RED}"############################################"
        echo -e ${RED}"##         This Is Not Epic :'(           ##"
        echo -e ${RED}"############################################"${NC}
        exit 1
    fi
}

make_defconfig
compile
completion

cd ${kernel_dir}
