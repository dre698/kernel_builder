#!/bin/bash
#
# apply ReSukiSU

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash -

git add .
git commit -am "drivers: ReSukiSU"

KSU_GIT_VER=$(cd KernelSU && git rev-list --count HEAD)
RSK_VER=$((30000 + KSU_GIT_VER + 700))

echo "${RSK_VER}" > "${maindir}/.ksu_ver"

patchesdir="$outside/ksu/patches/$(echo "$kernel_ver" | cut -d. -f1,2)"
if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/*.patch; do
    git am "$patch_file"
  done
  echo 'CONFIG_KSU_EXTRAS=y' >> "${defconfig_file}"
else
  echo "patching ReSukiSU failed, no patches for kernel ${kernel_ver}"
  exit 1
fi

sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}\"/" "${defconfig_file}"

echo "$(grep 'CONFIG_LOCALVERSION=' "${defconfig_file}")"

echo -e "\nincludes ReSukiSU, ver ${RSK_VER}" >> banner_append
