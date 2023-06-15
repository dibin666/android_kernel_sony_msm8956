#!/bin/bash

# 添加 Anykernel3
rm -rf AnyKernel3
git clone --depth=1 https://github.com/dibin666/AnyKernel3 -b kugo

# 更新 KernelSU
read -p "是否更新 KernelSU？(y/n): " choice
if [ "$choice" = "y" ]; then
  rm -rf KernelSU
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
fi

# AnyKernel3 路径
ANYKERNEL3_DIR=$PWD/AnyKernel3/
# 编译完成后内核名字
FINAL_KERNEL_ZIP=perf_kugo_A13_dibin.zip
# 内核工作目录
export KERNEL_DIR=$(pwd)
# 内核 defconfig 文件
export KERNEL_DEFCONFIG=loire_kugo_defconfig
# 编译临时目录，避免污染根目录
export OUT=out
# clang 和 gcc 绝对路径
export CLANG_PATH=/mnt/disk/tool/clang
export PATH=${CLANG_PATH}/bin:${PATH}
export CLANG_TRIPLE=${CLANG_PATH}/bin/aarch64-linux-gnu-
export 

export DEF_ARGS="O=${OUT} \
				ARCH=arm64 \
                                CC=clang \
                                CROSS_COMPILE=${CLANG_PATH}/bin/aarch64-linux-gnu- \
                                CROSS_COMPILE_ARM32=${CLANG_PATH}/bin/arm-linux-gnueabi- \
				LD=ld.lld "

export BUILD_ARGS="-j$(nproc --all) ${DEF_ARGS}"

# 开始编译内核
make ${DEF_ARGS} ${KERNEL_DEFCONFIG}
make ${BUILD_ARGS}

# 验证 Image.gz-dtb
ls $PWD/out/arch/arm64/boot/Image.gz-dtb

# 进入 AnyKernel3 目录
ls $ANYKERNEL3_DIR

# 清理 AnyKernel3 目录
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

# 复制编译出的文件到 AnyKernel3 目录
if [[ -f out/arch/arm64/boot/Image.gz-dtb ]]; then
  cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
elif [[ -f out/arch/arm64/boot/Image-dtb ]]; then
  cp out/arch/arm64/boot/Image-dtb AnyKernel3/Image-dtb
elif [[ -f out/arch/arm64/boot/Image.gz ]]; then
  cp out/arch/arm64/boot/Image.gz AnyKernel3/Image.gz
elif [[ -f out/arch/arm64/boot/Image ]]; then
  cp out/arch/arm64/boot/Image AnyKernel3/Image
fi

if [ -f out/arch/arm64/boot/dtbo.img ]; then
  cp out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
fi

# 打包内核为可刷入 Zip 文件
cd $ANYKERNEL3_DIR/
zip -r $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP

# 复制打包好的 Zip 文件到指定的目录
cp $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP /mnt/disk/kernelout && cd ..

# 清理目录
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf out/
