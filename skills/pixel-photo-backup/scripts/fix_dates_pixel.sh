#!/bin/bash

set -euo pipefail

# ============================================================
# fix_dates_pixel.sh
# 把 Pixel7Pro-Backup 裡的照片/影片「建立日期」和「修改日期」
# 還原成 EXIF 裡的真實拍攝時間（修正備份時日期被蓋掉的問題）
#
# 用法：./fix_dates_pixel.sh
#       ./fix_dates_pixel.sh --dry-run   ← 只預覽不修改
# ============================================================

# ── 設定區（與 backup_pixel.sh 保持一致）─────────────────────
TARGET="$HOME/Pictures/Pixel7Pro-Backup"
# ─────────────────────────────────────────────────────────────

# 顏色輸出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
elif [ -n "${1:-}" ]; then
  echo -e "${RED}❌ 不認識的參數：$1${NC}"
  echo "   用法：$0 [--dry-run]"
  exit 1
fi

echo ""
echo "📅 Pixel7Pro 備份 → 修復拍攝日期工具"
echo "======================================="
if $DRY_RUN; then
  echo -e "${YELLOW}⚠️  DRY-RUN 模式：只預覽，不實際修改${NC}"
  echo ""
fi

# ── 1. 確認 exiftool 有裝 ────────────────────────────────────
if ! command -v exiftool &> /dev/null; then
  echo -e "${RED}❌ 找不到 exiftool，請先執行：${NC}"
  echo "   brew install exiftool"
  exit 1
fi

# ── 2. 確認備份目錄存在 ───────────────────────────────────────
if [ ! -d "$TARGET" ]; then
  echo -e "${RED}❌ 找不到備份目錄：$TARGET${NC}"
  exit 1
fi

echo -e "📁 目標目錄：${CYAN}$TARGET${NC}"
echo ""

# ── 共用 exiftool 參數 ────────────────────────────────────────
COMMON_OPTS=(-r -overwrite_original -progress)
DRY_RUN_OPTS=(-r)

# ── 3. 處理照片（JPG / HEIC / PNG / DNG …）──────────────────
# 來源欄位：DateTimeOriginal（快門按下的時間，最準確）
echo -e "${CYAN}── 步驟 1/2：照片（JPG / HEIC / DNG / PNG）──${NC}"

if $DRY_RUN; then
  if exiftool "${DRY_RUN_OPTS[@]}" \
    -ext jpg -ext jpeg -ext heic -ext dng -ext png \
    -if '$DateTimeOriginal' \
    -p '$Directory/$FileName  $DateTimeOriginal' \
    "$TARGET"; then
    PHOTO_STATUS=0
  else
    PHOTO_STATUS=$?
  fi
else
  if exiftool "${COMMON_OPTS[@]}" \
    -ext jpg -ext jpeg -ext heic -ext dng -ext png \
    "-FileModifyDate<DateTimeOriginal" \
    "-FileCreateDate<DateTimeOriginal" \
    "$TARGET"; then
    PHOTO_STATUS=0
  else
    PHOTO_STATUS=$?
  fi
fi

echo ""

# ── 4. 處理影片（MP4 / MOV）──────────────────────────────────
# Pixel 錄的 MP4 優先用 CreationDate（含時區），沒有時 fallback 到 CreateDate
echo -e "${CYAN}── 步驟 2/2：影片（MP4 / MOV）──${NC}"

if $DRY_RUN; then
  if exiftool "${DRY_RUN_OPTS[@]}" \
    -ext mp4 -ext mov \
    -if '$CreationDate or $CreateDate' \
    -p '$Directory/$FileName  ${CreationDate;$_ ||= $CreateDate}' \
    "$TARGET"; then
    VIDEO_STATUS=0
  else
    VIDEO_STATUS=$?
  fi
else
  if exiftool "${COMMON_OPTS[@]}" \
    -ext mp4 -ext mov \
    "-FileModifyDate<CreateDate" \
    "-FileCreateDate<CreateDate" \
    "-FileModifyDate<CreationDate" \
    "-FileCreateDate<CreationDate" \
    "$TARGET"; then
    VIDEO_STATUS=0
  else
    VIDEO_STATUS=$?
  fi
fi

echo ""
echo "======================================="

# ── 5. 結果 ──────────────────────────────────────────────────
if [ $PHOTO_STATUS -eq 0 ] && [ $VIDEO_STATUS -eq 0 ]; then
  if $DRY_RUN; then
    echo -e "${YELLOW}👆 以上為預覽結果，實際未修改任何檔案${NC}"
    echo    "   確認無誤後，去掉 --dry-run 再跑一次即可"
  else
    echo -e "${GREEN}🎉 完成！所有檔案的日期已還原為拍攝時間${NC}"
    echo    "   現在在 Finder 用「建立日期」排序就是拍照順序了"
  fi
  exit 0
else
  echo -e "${RED}❌ exiftool 回報錯誤（可能是權限問題、檔案損毀或參數錯誤），請檢查上方輸出${NC}"
  exit 1
fi
