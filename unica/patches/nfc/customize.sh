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
