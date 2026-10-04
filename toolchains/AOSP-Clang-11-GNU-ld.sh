#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

clang="${outside}/aosp_clang11"
gcc64="${outside}/aosp_gcc64_49"
gcc="${outside}/aosp_gcc_49"

case $1 in
  "setup" )
    # Clone compiler
    if [ ! -d $clang ]; then
    git clone --depth=1 https://github.com/TeraaBytee/google-clang $clang
    fi
    if [ ! -d $gcc64 ]; then
    git clone --depth=1 https://github.com/TeraaBytee/aarch64-linux-android-4.9 $gcc64
    fi
    if [ ! -d $gcc ]; then
    git clone --depth=1 https://github.com/TeraaBytee/arm-linux-androideabi-4.9 $gcc
    fi
  ;;

  "build" )
    export PATH="$clang/bin:$gcc64/bin:$gcc/bin:/usr/bin:${PATH}"

    # --- source fixups for the stock Xiaomi dandelion 4.9 tree (idempotent) ---
    # 1) Xiaomi's repo ignores *.i, so the FocalTech FT8006S firmware headers
    #    are missing. Empty placeholders let the driver compile (no built-in fw).
    fwdir="drivers/input/touchscreen/mediatek/ft8006s_spi/include/firmware"
    if [ -d "drivers/input/touchscreen/mediatek/ft8006s_spi" ]; then
      mkdir -p "$fwdir"
      for f in fw_helitai_v0e.i fw_sample.i; do
        [ -e "$fwdir/$f" ] || : > "$fwdir/$f"
      done
    fi
    # 2) clang 11 is stricter than the clang 9 used by Xiaomi, and many vendor
    #    Makefiles add a plain -Werror. Drop only the plain flag (-Werror=xxx stays).
    find . -type f \( -name Makefile -o -name 'Makefile.*' -o -name Kbuild -o -name '*.mk' \) \
      ! -path './scripts/*' ! -path './out/*' -print0 \
      | xargs -0 sed -i -E 's/(^|[[:space:]])-Werror([[:space:]]|$)/\1\2/g; s/(^|[[:space:]])-Werror([[:space:]]|$)/\1\2/g'
    make -j$NJOBS O=out CC=clang LD=ld.lld ARCH=arm64 SUBARCH=arm64 $2
    make -j$NJOBS O=out \
      CROSS_COMPILE="aarch64-linux-android-" \
      CROSS_COMPILE_ARM32="arm-linux-androideabi-" \
      CROSS_COMPILE_COMPAT="arm-linux-androideabi-" \
      CLANG_TRIPLE="aarch64-linux-gnu-" \
      LD_LIBRARY_PATH="$clang/lib64:$LD_LIBRABRY_PATH" \
      CC=clang \
      CFLAGS_KERNEL="-Wno-error" \
      2>&1 | tee "${CUR_TOOLCHAIN}-${TIME}.log"
    sh ${outside}/ver_toolchain.sh clang aarch64-linux-android-ld > ${CUR_TOOLCHAIN}.info
  ;;
esac
