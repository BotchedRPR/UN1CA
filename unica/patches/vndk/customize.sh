SKIPUNZIP=1
local NO_APEX=false

if [[ "$SOURCE_VNDK_VERSION" != "$TARGET_VNDK_VERSION" ]]; then
    if $TARGET_HAS_SYSTEM_EXT; then
        SYS_EXT_DIR="$WORK_DIR/system_ext"
        PARTITION="system_ext"
    else
        SYS_EXT_DIR="$WORK_DIR/system/system/system_ext"
        PARTITION="system"
    fi

    [ ! -d "$SYS_EXT_DIR/apex" ] && NO_APEX=true
    $NO_APEX && mkdir -p "$SYS_EXT_DIR/apex"

    if [ ! -f "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex" ]; then
        rm -f "$SYS_EXT_DIR/apex/com.android.vndk.v$SOURCE_VNDK_VERSION.apex"
        if [ "$TARGET_VNDK_VERSION" -eq 30 ]; then
            cat "$SRC_DIR/unica/patches/vndk/30/com.android.vndk.v30.apex.00" \
                "$SRC_DIR/unica/patches/vndk/30/com.android.vndk.v30.apex.01" \
                "$SRC_DIR/unica/patches/vndk/30/com.android.vndk.v30.apex.02" > "$SYS_EXT_DIR/apex/com.android.vndk.v30.apex"
        else
            cp --preserve=all \
                "$SRC_DIR/unica/patches/vndk/$TARGET_VNDK_VERSION/com.android.vndk.v$TARGET_VNDK_VERSION.apex" "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex"
        fi
        if $NO_APEX; then
            if $TARGET_HAS_SYSTEM_EXT; then
                echo "system_ext/apex 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                echo "/system_ext/apex u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-$PARTITION"
                echo "system_ext/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                echo "/system_ext/apex/com\\.android\\.vndk\\.v$TARGET_VNDK_VERSION\\.apex u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-$PARTITION"
            else
                echo "system/system_ext/apex 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                echo "/system/system_ext/apex u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-$PARTITION"
                echo "system/system_ext/apex/com.android.vndk.v$TARGET_VNDK_VERSION.apex 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
                echo "/system/system_ext/apex/com\\.android\\.vndk\\.v$TARGET_VNDK_VERSION\\.apex u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-$PARTITION"
            fi
            sed -i '$d' "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "    <vendor-ndk>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "        <version>$TARGET_VNDK_VERSION</version>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "    </vendor-ndk>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
            echo "</manifest>" >> "$SYS_EXT_DIR/etc/vintf/manifest.xml"
        else
            sed -i "s/com\\\.android\\\.vndk\\\.v$SOURCE_VNDK_VERSION/com\\\.android\\\.vndk\\\.v$TARGET_VNDK_VERSION/g" \
                "$WORK_DIR/configs/file_context-$PARTITION"
            sed -i "s/com.android.vndk.v$SOURCE_VNDK_VERSION/com.android.vndk.v$TARGET_VNDK_VERSION/g" \
                "$WORK_DIR/configs/fs_config-$PARTITION"
            sed -i "s/version>$SOURCE_VNDK_VERSION/version>$TARGET_VNDK_VERSION/g" "$SYS_EXT_DIR/etc/vintf/manifest.xml"
        fi
    else
        echo "VNDK v$TARGET_VNDK_VERSION apex is already in place. Ignoring"
    fi
else
    echo "SOURCE_VNDK_VERSION and TARGET_VNDK_VERSION are the same. Ignoring"
fi
