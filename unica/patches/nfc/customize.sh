SKIPUNZIP=1

# [
REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ] || [ -L "$FILE_PATH" ]; then
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
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ "$TARGET_ESE_CHIP_VENDOR" = "SLSI" ]; then
    echo "Replacing NFC blobs with SLSI"

    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libnfc_nxpsn_jni.so"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/priv-app/NfcNci/lib/arm64/libnfc_nxpsn_jni.so"

    cp -a --preserve=all "$SRC_DIR/unica/patches/nfc/system/"* "$WORK_DIR/system/system"

    {
        echo "/system/lib64/libnfc-sec\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libnfc_sec_jni\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libnfc-nci_flags\.so u:object_r:system_lib_file:s0"
        echo "/system/lib64/libstatslog_nfc\.so u:object_r:system_lib_file:s0"
        echo "/system/priv-app/NfcNci u:object_r:system_file:s0"
        echo "/system/priv-app/NfcNci/lib u:object_r:system_file:s0"
        echo "/system/priv-app/NfcNci/lib/arm64 u:object_r:system_file:s0"
        echo "/system/priv-app/NfcNci/lib/arm64/libnfc_sec_jni\.so u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
     
    {
        echo "system/lib64/libnfc-sec.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libnfc_sec_jni.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libnfc-nci_flags.so 0 0 644 capabilities=0x0"
        echo "system/lib64/libstatslog_nfc.so 0 0 644 capabilities=0x0"
        echo "system/priv-app/NfcNci 0 0 755 capabilities=0x0"
        echo "system/priv-app/NfcNci/lib 0 0 755 capabilities=0x0"
        echo "system/priv-app/NfcNci/lib/arm64 0 0 755 capabilities=0x0"
        echo "system/priv-app/NfcNci/lib/arm64/libnfc_sec_jni.so 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
else
    echo "NXP NFC found. Ignoring."
fi

if [[ "$SOURCE_ESE_CHIP_VENDOR" != "$TARGET_ESE_CHIP_VENDOR" ]] || \
    [[ "$SOURCE_ESE_COS_NAME" != "$TARGET_ESE_COS_NAME" ]]; then
    DECOMPILE "system/framework/framework.jar"
    DECOMPILE "system/framework/services.jar"

    FTP="
    system/framework/framework.jar/smali_classes5/com/android/server/SemService.smali
    system/framework/services.jar/smali/com/android/server/SystemConfig.smali
    system/framework/services.jar/smali_classes2/com/samsung/ucm/ucmservice/CredentialManagerService.smali
    "
    for f in $FTP; do
        sed -i "s/\"$SOURCE_ESE_CHIP_VENDOR\"/\"$TARGET_ESE_CHIP_VENDOR\"/g" "$APKTOOL_DIR/$f"
        sed -i "s/\"$SOURCE_ESE_COS_NAME\"/\"$TARGET_ESE_COS_NAME\"/g" "$APKTOOL_DIR/$f"
    done
fi
