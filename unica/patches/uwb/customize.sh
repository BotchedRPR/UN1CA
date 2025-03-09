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
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ ! -d "$FW_DIR/${MODEL}_${REGION}/system/system/app/UwbUci" ]; then
    echo "Removing UWB blobs..."
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/app/UwbUci"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/app/UwbTest"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/app/UwbRROverlayMccMncRegulation"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/init/init.system.uwb.rc"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/com.samsung.android.uwb_extras.xml"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/etc/permissions/samsung.uwb.xml"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/framework/com.samsung.android.uwb_extras.jar"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/framework/samsung.uwb.jar"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libtflite_uwb_jni.so"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib/libuwb_uci_jni_rust.so"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libtflite_uwb_jni.so"
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/libuwb_uci_jni_rust.so"
else
    echo "Target has UWB. Ignoring."
fi
