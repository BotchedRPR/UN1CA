SKIPUNZIP=1

# [
REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

SET_PROP()
{
    local PROP="$1"
    local VALUE="$2"
    local FILE="$3"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        PROP="$(echo -n "$PROP" | sed 's/=//g')"
        if grep -Fq "$PROP" "$FILE"; then
            echo "Deleting \"$PROP\" prop in $FILE" | sed "s.$WORK_DIR..g"
            sed -i "/^$PROP/d" "$FILE"
        fi
    else
        if grep -Fq "$PROP" "$FILE"; then
            local LINES

            echo "Replacing \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            LINES="$(sed -n "/^${PROP}\b/=" "$FILE")"
            for l in $LINES; do
                sed -i "$l c${PROP}=${VALUE}" "$FILE"
            done
        else
            echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            if ! grep -q "Added by scripts" "$FILE"; then
                echo "# Added by scripts/internal/apply_modules.sh" >> "$FILE"
            fi
            echo "$PROP=$VALUE" >> "$FILE"
        fi
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

local ITEMS
local SYSTEM_PATH
local SYSTEM_EXT_PATH

if [ -f "$FW_DIR/${MODEL}_${REGION}/system/system/lib64/vendor.samsung_slsi.hardware.ExynosHWCServiceTW@1.0.so" ]; then
    echo "Exynos target device detected! Patching..."

    SYSTEM_PATH="$WORK_DIR/system/system"

    if $TARGET_HAS_SYSTEM_EXT; then
        SYSTEM_EXT_PATH="$WORK_DIR/system_ext"
    else
        SYSTEM_EXT_PATH="$SYSTEM_PATH/system_ext"
    fi

    # Delete all QCOM/QTI blobs
    ITEMS=$(find "$WORK_DIR" -name "*qti*")
    ITEMS+=$(find "$WORK_DIR" -name "*qcom*")
    ITEMS+=$(find "$WORK_DIR" -name "*qualcomm*")
    ITEMS+=$(find "$WORK_DIR" -name "*qcc*")
    for item in $ITEMS
    do
        REMOVE_FROM_WORK_DIR "$item"
    done

    # Delete some extra blobs
    # Qualcomm CNE
    ITEMS=$(find "$WORK_DIR" -name "*com.quicinc.cne*")
    for item in $ITEMS
    do
        REMOVE_FROM_WORK_DIR "$item"
    done

    # Instkh
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/etc/init/insthk_qsee.rc"

    # QSEECOM
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libqmi_cci_system.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libqmi_encdec_system.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libqms_ntnsatellite_sdk.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libQmsNtnProto.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libQSEEComAPI_system.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libqspm-mem-utils.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64/libQTEEConnector_system.so"

    # UIM Service
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/etc/permissions/UimService.xml"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/framework/uimservicelibrary.jar"

    # AudioSphere
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/permissions/audiosphere.xml"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/framework/audiosphere.jar"

    # QCOM Diagnostics
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/bin/sec_diag_uart_log"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/diag_callback_sample_system"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/diag_dci_sample_RF_ACT"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/diag_dci_sample_system"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/diag_mdlog_system"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/test_diag_system"

    # QCC
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/qccsyshal@1.2-service"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/app/QCC"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/app/QdcmFF"

    # MemHal
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/MemHalTest-system"

    # ActivityExtension
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/framework/ActivityExt.jar"

    # QMAP Bridge
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/framework/qmapbridge.jar"

    # DPM API
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/permissions/dpmapi.xml"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/dpm"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/framework/dpmapi.jar"

    # Data Channel LIB
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/permissions/datachannellib.xml"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/framework/datachannellib.jar"

    # PerfService
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/QPerformance.jar"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/QXPerformance.jar"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/UxPerformance.jar"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/boot-QPerformance.vdex"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/boot-UxPerformance.vdex"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/perfservice"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/init/perfservice.rc"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/seccomp_policy/perfservice.policy"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/perf"

    # QsGuard
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/qsguard"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/init/qsguard.rc"

    # QSPA
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/init/qspa_system.rc"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/qspa"

    # SXRAUXD
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/qxrsplitauxservice"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/init/sxrauxd_ext.rc"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/seccomp_policy/sxraux-arm.policy"

    # TCMD
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/tcmd"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/init/tcmd.rc"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/seccomp_policy/tcmd.policy"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/tcmclient.jar"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/tcmiface.jar"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/boot-tcmiface.vdex"

    # USBUDEV
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/usbudev"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/init/usbudev.rc"

    # qcrosvm
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/bin/qcrosvm"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/seccomp_policy/qcrosvm.policy"

    # QTI Telephony Extension
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/framework/telephony-ext.jar"

    # SBAuth
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/bin/sbauth"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/etc/init/sbauth.rc"

    # Cleanup empty folders
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/bin"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/etc/init"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/etc/vintf"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/framework"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/app"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/seccomp_policy"

    # Remove Product SEPolicy
    REMOVE_FROM_WORK_DIR "$WORK_DIR/product/etc/selinux"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/odm/etc/selinux/precompiled_sepolicy.product_sepolicy_and_mapping.sha256"

    # Remove ODM UEVENTD
    REMOVE_FROM_WORK_DIR "$WORK_DIR/odm/etc/ueventd.rc"

    # Remove misc remnants
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/etc/init/dhkprov.rc"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/bin/dhkprov"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/etc/init/diagsylincom.rc"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/bin/diagsylincom"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/lib64/blockchain_aidl_comm_client.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_PATH/lib64/payment_aidl_comm_client.so"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/lib64"
    REMOVE_FROM_WORK_DIR "$SYSTEM_EXT_PATH/etc/permissions/privapp-permissions-aptxals.xml"
    
    # Replace ODM Sepolicy
    cp -a --preserve=all "$SRC_DIR/unica/patches/exynosation/odm/etc/selinux/"* "$WORK_DIR/odm/etc/selinux"

    # Add System blobs
    cp -a --preserve=all "$SRC_DIR/unica/patches/exynosation/system/"* "$SYSTEM_PATH"
    cp -a --preserve=all "$SRC_DIR/unica/patches/exynosation/system_ext/"* "$SYSTEM_EXT_PATH"

    # Add TEEgris TUI APK
    echo "/system/app/TEEgrisTuiService/TEEgrisTuiService.apk" >> "$SYSTEM_PATH/etc/irremovable_list.txt"
    echo "/system/app/TEEgrisTuiService/TEEgrisTuiService.apk" >> "$SYSTEM_PATH/etc/apks_count_list.txt"

    if ! grep -q "ExynosHWCServiceTW" "$WORK_DIR/configs/file_context-system"; then
        {
            echo "/system/app/TEEgrisTuiService u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/TEEgrisTuiService\.apk u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/oat u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/oat/arm64 u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/lib u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/lib/arm64 u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/oat/arm64/TEEgrisTuiService\.odex u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/oat/arm64/TEEgrisTuiService\.vdex u:object_r:system_file:s0"
            echo "/system/app/TEEgrisTuiService/lib/arm64/libtui_service_jni\.so u:object_r:system_file:s0"
            echo "/system/bin/heatmap u:object_r:heatmap_default_exec:s0"
            echo "/system/etc/public\.libraries-edensdk\.samsung\.txt u:object_r:system_file:s0"
            echo "/system/etc/init/init\.gpscommon\.rc u:object_r:system_file:s0"
            echo "/system/etc/init/init\.network\.rc u:object_r:system_file:s0"
            echo "/system/etc/init/init\.rilchip\.slsi\.rc u:object_r:system_file:s0"
            echo "/system/etc/init/init\.sec-heatmap\.rc u:object_r:system_file:s0"
            echo "/system/etc/init/insthk_teegris\.rc u:object_r:system_file:s0"
            echo "/system/etc/permissions/com\.android\.nfc_extras\.xml u:object_r:system_file:s0"
            echo "/system/etc/sysconfig/preinstalled-packages-com\.samsung\.sec\.android\.teegris\.tui_service\.xml u:object_r:system_file:s0"
            echo "/system/framework/vendor\.samsung_slsi\.telephony\.hardware\.oemservice-V1-java\.jar u:object_r:system_file:s0"
            echo "/system/framework/com\.android\.nfc_extras\.jar u:object_r:system_file:s0"
            echo "/system/lib64/android\.hardware\.graphics\.composer3-V1-ndk\.so u:object_r:system_file:s0"
            echo "/system/lib64/android\.hardware\.graphics\.extension\.composer3-V1-ndk\.so u:object_r:system_file:s0"
            echo "/system/lib64/libeden_nn_on_system\.so u:object_r:system_file:s0"
            echo "/system/lib64/libeden_rt_stub\.edensdk\.samsung\.so u:object_r:system_file:s0"
            echo "/system/lib64/hidl_tlc_blockchain_comm_client\.so u:object_r:system_file:s0"
            echo "/system/lib64/hidl_tlc_payment_comm_client\.so u:object_r:system_file:s0"
            echo "/system/lib64/libtui_service_jni\.so u:object_r:system_file:s0"
            echo "/system/lib64/libtsmux\.so u:object_r:system_file:s0"
            echo "/system/lib64/librepeater\.so u:object_r:system_file:s0"
            echo "/system/lib64/vendor\.samsung_slsi\.hardware\.ExynosHWCServiceTW@1\.0\.so u:object_r:system_file:s0"
            echo "/system/lib64/vendor\.samsung_slsi\.hardware\.eden_runtime@1\.0\.so u:object_r:system_file:s0"
            echo "/system/lib64/vendor\.samsung\.hardware\.tlc\.blockchain@1\.0\.so u:object_r:system_file:s0"
            echo "/system/lib64/vendor\.samsung\.hardware\.tlc\.payment@1\.0\.so u:object_r:system_file:s0"

        } >> "$WORK_DIR/configs/file_context-system"
    fi
    if ! grep -q "ExynosHWCServiceTW" "$WORK_DIR/configs/fs_config-system"; then
        {
            echo "system/app/TEEgrisTuiService 0 0 755 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/TEEgrisTuiService.apk 0 0 644 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/oat 0 0 755 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/oat/arm64 0 0 755 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/lib 0 0 755 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/lib/arm64 0 0 755 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/oat/arm64/TEEgrisTuiService.odex 0 0 644 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/oat/arm64/TEEgrisTuiService.vdex 0 0 644 capabilities=0x0"
            echo "system/app/TEEgrisTuiService/lib/arm64/libtui_service_jni.so 0 0 644 capabilities=0x0"
            echo "system/bin/heatmap 0 0 755 capabilities=0x0"
            echo "system/etc/public.libraries-edensdk.samsung.txt 0 0 644 capabilities=0x0"
            echo "system/etc/init/init.gpscommon.rc 0 0 644 capabilities=0x0"
            echo "system/etc/init/init.network.rc 0 0 644 capabilities=0x0"
            echo "system/etc/init/init.rilchip.slsi.rc 0 0 644 capabilities=0x0"
            echo "system/etc/init/init.sec-heatmap.rc 0 0 644 capabilities=0x0"
            echo "system/etc/init/insthk_teegris.rc 0 0 644 capabilities=0x0"
            echo "system/etc/permissions/com.android.nfc_extras.xml 0 0 644 capabilities=0x0"
            echo "system/etc/sysconfig/preinstalled-packages-com.samsung.sec.android.teegris.tui_service.xml 0 0 644 capabilities=0x0"
            echo "system/framework/com.android.nfc_extras.jar 0 0 644 capabilities=0x0"
            echo "system/framework/vendor.samsung_slsi.telephony.hardware.oemservice-V1-java.jar 0 0 644 capabilities=0x0"
            echo "system/lib64/android.hardware.graphics.composer3-V1-ndk.so 0 0 644 capabilities=0x0"
            echo "system/lib64/android.hardware.graphics.extension.composer3-V1-ndk.so 0 0 644 capabilities=0x0"
            echo "system/lib64/libeden_nn_on_system.so 0 0 644 capabilities=0x0"
            echo "system/lib64/libeden_rt_stub.edensdk.samsung.so 0 0 644 capabilities=0x0"
            echo "system/lib64/hidl_tlc_blockchain_comm_client.so 0 0 644 capabilities=0x0"
            echo "system/lib64/hidl_tlc_payment_comm_client.so 0 0 644 capabilities=0x0"
            echo "system/lib64/libtui_service_jni.so 0 0 644 capabilities=0x0"
            echo "system/lib64/libtsmux.so 0 0 644 capabilities=0x0"
            echo "system/lib64/librepeater.so 0 0 644 capabilities=0x0"
            echo "system/lib64/vendor.samsung_slsi.hardware.ExynosHWCServiceTW@1.0.so 0 0 644 capabilities=0x0"
            echo "system/lib64/vendor.samsung_slsi.hardware.eden_runtime@1.0.so 0 0 644 capabilities=0x0"
            echo "system/lib64/vendor.samsung.hardware.tlc.blockchain@1.0.so 0 0 644 capabilities=0x0"
            echo "system/lib64/vendor.samsung.hardware.tlc.payment@1.0.so 0 0 644 capabilities=0x0"
        } >> "$WORK_DIR/configs/fs_config-system"
    fi

    # Remove A/B Partitions
    SET_PROP "ro.product.ab_ota_partitions" "" "$WORK_DIR/product/etc/build.prop"

    # Remove Qualcomm Props
    SET_PROP "rild.libpath" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ril.subscription.types" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "DEVICE_PROVISIONED" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "dalvik.vm.heapsize" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "dev.pm.dyn_samplingrate" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "qcom.hw.aac.encoder" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.vendor.cne.feature" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.enable-player" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.enable-http" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.enable-aac" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.enable-qcp" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.enable-fma2dp" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.enable-scan" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.stagefright.thumbnail.prefer_hw_codecs" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "mmp.enable.3g2" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "media.aac_51_output_enabled" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "vendor.mm.enable.qcom_parser" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.bluetooth.library_name" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.vendor.btstack.aac_frm_ctl.enabled" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.rmnet.data.enable" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.wda.enable" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.dl_mode" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.ul_mode" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.agg.dl_pkt" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.agg.dl_size" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.mux_count" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.iwlan_mux" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.data.df.dev_name" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "sys.qca1530" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.debug.coresight.config" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.vendor.radio.atfwd.start" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "qemu.hw.mainkeys" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "vendor.camera.aux.packagelist" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "persist.vendor.camera.privapp.list" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "debug.stagefright.ccodec" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.media.recorder-max-base-layer-fps" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.charger.enable_suspend" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "arm64.memtag.process.system_server" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.launcher.blur.appLaunch" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.bluetooth.finder.supported" "" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.vendor.qti.va_aosp.support" "" "$SYSTEM_PATH/build.prop"

    # Add Exynos Props
    SET_PROP "persist.demo.hdmirotationlock" "false" "$SYSTEM_PATH/build.prop"
    SET_PROP "dev.usbsetting.embedded" "on" "$SYSTEM_PATH/build.prop"
    SET_PROP "log.tag.EDEN" "INFO" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.debug_level" "0x494d" "$SYSTEM_PATH/build.prop"
    SET_PROP "ro.vendor.cscsupported" "1" "$SYSTEM_PATH/build.prop"
    SET_PROP "audio.offload.min.duration.secs" "30" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.asha.central.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.a2dp.source.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.avrcp.target.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.gatt.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.hfp.ag.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.hid.device.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.hid.host.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.map.server.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.opp.enabled" "false" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.pan.nap.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.pan.panu.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.profile.pbap.server.enabled" "true" "$SYSTEM_PATH/build.prop"
    SET_PROP "bluetooth.device.class_of_device" "90,2,12" "$SYSTEM_PATH/build.prop"

else
    echo "Target device is not an Exynos device. Ignoring"
fi
