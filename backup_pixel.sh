#!/bin/bash

# ============================================================
# backup_pixel.sh
# 把 Pixel 7 Pro 照片備份到 Mac，只拉新檔案、跳過已備份的
# 用法：./backup_pixel.sh
# ============================================================

# ── 設定區（可自行修改）─────────────────────────────────────
DEST="$HOME/Pictures/Pixel7Pro-Backup"   # Mac 上的備份根目錄

# 要備份的手機資料夾清單
PHONE_DIRS=(
  "/sdcard/DCIM/Camera"
  "/sdcard/Pictures"
)
# ─────────────────────────────────────────────────────────────

# 顏色輸出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "📱 Pixel 7 Pro → Mac 備份工具"
echo "================================"

# ── 1. 確認 adb 有裝 ─────────────────────────────────────────
if ! command -v adb &> /dev/null; then
  echo -e "${RED}❌ 找不到 adb，請先執行：brew install android-platform-tools${NC}"
  exit 1
fi

# ── 2. 確認手機有連上 ─────────────────────────────────────────
echo "🔍 偵測手機連線..."
ADB_DEVICES=$(adb devices | grep -v "List of devices" | grep "device$")

if [ -z "$ADB_DEVICES" ]; then
  echo -e "${RED}❌ 找不到手機，請確認：${NC}"
  echo "   1. USB 線有接好"
  echo "   2. 手機已開啟 USB 偵錯（開發人員選項）"
  echo "   3. 手機上的授權彈窗已按「允許」"
  exit 1
fi

echo -e "${GREEN}✅ 手機已連線${NC}"
echo ""

# ── 3. 建立備份目錄 ───────────────────────────────────────────
mkdir -p "$DEST"

# ── 4. 開始備份每個資料夾 ─────────────────────────────────────
TOTAL_NEW=0
TOTAL_SKIP=0
TOTAL_FAIL=0

for PHONE_DIR in "${PHONE_DIRS[@]}"; do
  # 把手機路徑轉成 Mac 上的子目錄名稱
  # 例如 /sdcard/DCIM/Camera → DCIM/Camera
  REL_PATH="${PHONE_DIR#/sdcard/}"
  LOCAL_DIR="$DEST/$REL_PATH"
  mkdir -p "$LOCAL_DIR"

  echo "📂 備份：$PHONE_DIR"
  echo "   → $LOCAL_DIR"

  # 取得手機上的檔案清單
  FILE_LIST=$(adb shell find "$PHONE_DIR" -type f 2>/dev/null)

  if [ -z "$FILE_LIST" ]; then
    echo -e "   ${YELLOW}⚠️  資料夾是空的或不存在，跳過${NC}"
    echo ""
    continue
  fi

  NEW=0
  SKIP=0
  FAIL=0

  while IFS= read -r PHONE_FILE; do
    # 轉換成 Mac 上的對應路徑
    REL_FILE="${PHONE_FILE#/sdcard/}"
    LOCAL_FILE="$DEST/$REL_FILE"

    # 建立子目錄（如果需要）
    mkdir -p "$(dirname "$LOCAL_FILE")"

    # ── 核心邏輯：只拉 Mac 上不存在的檔案 ──
    if [ -f "$LOCAL_FILE" ]; then
      # 已存在：比對檔案大小，大小一樣就跳過
      PHONE_SIZE=$(adb shell stat -c%s "$PHONE_FILE" 2>/dev/null | tr -d '\r')
      LOCAL_SIZE=$(stat -f%z "$LOCAL_FILE" 2>/dev/null)

      if [ "$PHONE_SIZE" = "$LOCAL_SIZE" ]; then
        SKIP=$((SKIP + 1))
        continue
      else
        # 大小不同（可能傳輸不完整），重新拉
        echo -e "   ${YELLOW}⚠️  重新拉取（大小不一致）：$(basename "$PHONE_FILE")${NC}"
      fi
    fi

    # 拉取檔案
    adb pull "$PHONE_FILE" "$LOCAL_FILE" &>/dev/null
    if [ $? -eq 0 ]; then
      NEW=$((NEW + 1))
    else
      echo -e "   ${RED}❌ 失敗：$(basename "$PHONE_FILE")${NC}"
      FAIL=$((FAIL + 1))
    fi

  done <<< "$FILE_LIST"

  echo -e "   ${GREEN}✅ 新增：$NEW 個  跳過（已備份）：$SKIP 個${NC}"
  if [ $FAIL -gt 0 ]; then
    echo -e "   ${RED}❌ 失敗：$FAIL 個${NC}"
  fi
  echo ""

  TOTAL_NEW=$((TOTAL_NEW + NEW))
  TOTAL_SKIP=$((TOTAL_SKIP + SKIP))
  TOTAL_FAIL=$((TOTAL_FAIL + FAIL))
done

# ── 5. 總結 ───────────────────────────────────────────────────
echo "================================"
echo "📊 備份結果"
echo -e "   ${GREEN}新增：$TOTAL_NEW 個檔案${NC}"
echo    "   跳過（已備份）：$TOTAL_SKIP 個檔案"
if [ $TOTAL_FAIL -gt 0 ]; then
  echo -e "   ${RED}失敗：$TOTAL_FAIL 個檔案${NC}"
fi
echo ""
echo "📁 備份位置：$DEST"
echo ""

if [ $TOTAL_FAIL -eq 0 ]; then
  echo -e "${GREEN}🎉 備份完成！${NC}"
else
  echo -e "${YELLOW}⚠️  備份完成，但有 $TOTAL_FAIL 個檔案失敗，建議再跑一次${NC}"
fi
echo ""
