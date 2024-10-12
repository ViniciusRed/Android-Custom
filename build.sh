#!/bin/bash

setup_environment() {
    export outdir="${ROM_DIR}/out/target/product/${device}"
    source build/envsetup.sh
    source "${my_dir}/config.sh"
}

setup_ccache() {
    if [[ "${ccache}" == "true" ]]; then
        if [[ -n "${ccache_size:+x}" ]]; then
            export USE_CCACHE=1
            ccache -M "${ccache_size}G"
        else
            log_error "Please set the ccache_size variable in your config."
            exit 1
        fi
    else
        unset USE_CCACHE
        unset CCACHE_DIR
        unset CCACHE_EXEC
    fi
}

prepare_build() {
    export buildtype="${buildtype:-userdebug}"
    
    if [[ -n "${rom_vendor_name:+x}" ]]; then
        lunch "${rom_vendor_name}_${device}-${buildtype}"
    else
        lunch "${device}-${buildtype}"
    fi

    case "${clean}" in
        "clean")
            m clean -j$(nproc --all)
            ;;
        "installclean")
            m installclean -j$(nproc --all)
            rm -rf out/target/product/"${device}"/obj/DTBO_OBJ
            ;;
        *)
            rm "${outdir}"/*$(date +%Y)*.zip*
            ;;
    esac
}

generate_incremental() {
    if [[ -e "${my_dir}"/*"${device}"*target_files*.zip ]]; then
        export old_target_files_exists=true
        export old_target_files_path=$(ls "${my_dir}"/*"${device}"*target_files*.zip | tail -n -1)
    else
        echo "Old target-files package not found, generating incremental package on next build"
    fi
    export new_target_files_path=$(ls "${outdir}"/obj/PACKAGING/target_files_intermediates/*target_files*.zip | tail -n -1)
    if [[ "${old_target_files_exists}" == "true" ]]; then
        ota_from_target_files -i "${old_target_files_path}" "${new_target_files_path}" "${outdir}"/incremental_ota_update.zip
        export incremental_zip_path=$(ls "${outdir}"/incremental_ota_update.zip | tail -n -1)
    fi
    cp "${new_target_files_path}" "${my_dir}"
}

upload_build() {
    local tag=$( echo "$(env TZ="${timezone}" date +%Y%m%d%H%M)-${zip_name}" | sed 's|.zip||')
    github-release "${release_repo}" "${tag}" "main" "${ROM} for ${device}

Date: $(env TZ="${timezone}" date)" "${finalzip_path}"

    if [[ "${generate_incremental}" == "true" && -e "${incremental_zip_path}" && "${old_target_files_exists}" == "true" ]]; then
        github-release "${release_repo}" "${tag}" "main" "${ROM} for ${device}

Date: $(env TZ="${timezone}" date)" "${incremental_zip_path}"
    fi

    if [[ "${upload_recovery}" == "true" && -e "${img_path}" ]]; then
        github-release "${release_repo}" "${tag}" "main" "${ROM} for ${device}

Date: $(env TZ="${timezone}" date)" "${img_path}"
    fi

    echo "Uploaded"
    echo "Download: [${tag}](https://github.com/${release_repo}/releases/tag/${tag})"
}

log_error() {
    echo "ERROR: $1" >&2
}

main() {
    BUILD_START=$(date +"%s")
    echo "Build started for ${device}"
    
    setup_environment
    setup_ccache
    prepare_build
    
    if ! m "${bacon}" -j$(nproc --all); then
        log_error "Build failed"
        exit 1
    fi
    
    build_successful="${?}"
    BUILD_END=$(date +"%s")
    BUILD_DURATION=$((BUILD_END - BUILD_START))

    if [[ "${generate_incremental}" == "true" ]]; then
        generate_incremental
    fi

    if [[ -e "${outdir}"/*$(date +%Y)*.zip ]]; then
        export finalzip_path=$(ls "${outdir}"/*$(date +%Y)*.zip | tail -n -1)
    else
        export finalzip_path=$(ls "${outdir}"/*"${device}"-ota-*.zip | tail -n -1)
    fi

    if [[ "${upload_recovery}" == "true" ]]; then
        if [[ ! -e "${outdir}"/recovery.img ]]; then
            cp "${outdir}"/boot.img "${outdir}"/recovery.img
        fi
        export img_path=$(ls "${outdir}"/recovery.img | tail -n -1)
    fi

    export zip_name=$(echo "${finalzip_path}" | sed "s|${outdir}/||")

    if [[ "${build_successful}" == "0" && -n "${finalzip_path}" ]]; then
        echo "Build completed successfully in $((BUILD_DURATION / 60)) minute(s) and $((BUILD_DURATION % 60)) seconds"
        echo "Uploading"
        upload_build
    else
        log_error "Build failed in $((BUILD_DURATION / 60)) minute(s) and $((BUILD_DURATION % 60)) seconds"
        exit 1
    fi
}

main