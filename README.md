# Android Photo Backup

Mac 上用 ADB 備份 Pixel 7 Pro 照片與影片的小工具。備份腳本只拉新檔案，已存在且大小相同的檔案會跳過；日期修復腳本則會把備份後的檔案建立日期與修改日期還原成 EXIF/影片中記錄的拍攝時間。

## 功能

- 從 Pixel 7 Pro 備份 `/sdcard/DCIM/Camera` 與 `/sdcard/Pictures`
- 備份到 `~/Pictures/Pixel7Pro-Backup`
- 跳過已備份且大小一致的檔案
- 偵測沒有連線、未授權或同時連接多台 Android 裝置的狀況
- 使用 `exiftool` 修正照片與影片的 Finder 日期排序
- 支援日期修復 dry-run 預覽模式

## 需求

- macOS
- Android 手機已開啟 USB 偵錯
- ADB:

```sh
brew install android-platform-tools
```

- ExifTool，只有執行日期修復時需要:

```sh
brew install exiftool
```

## 使用方式

先用 USB 連接手機，並在手機上的 USB 偵錯授權彈窗按允許。

備份照片與影片:

```sh
./backup_pixel.sh
```

修復備份檔案的建立日期與修改日期。建議先預覽:

```sh
./fix_dates_pixel.sh --dry-run
```

確認預覽結果沒問題後再實際修改:

```sh
./fix_dates_pixel.sh
```

## 預設路徑

備份目的地:

```text
~/Pictures/Pixel7Pro-Backup
```

手機來源資料夾:

```text
/sdcard/DCIM/Camera
/sdcard/Pictures
```

如果要改備份位置或來源資料夾，可以編輯 `backup_pixel.sh` 裡的 `DEST` 和 `PHONE_DIRS`。如果改了備份位置，也要同步修改 `fix_dates_pixel.sh` 裡的 `TARGET`。

## 腳本說明

`backup_pixel.sh`

備份手機照片與影片到 Mac。檔案已存在時會比較手機與本機檔案大小，大小相同就跳過，大小不同會重新拉取。

`fix_dates_pixel.sh`

遞迴處理備份目錄中的照片與影片，將檔案日期改回拍攝時間。照片優先使用 `DateTimeOriginal`；影片使用 `CreationDate`，並在需要時 fallback 到 `CreateDate`。

## 常見問題

找不到手機時，請確認:

- USB 線有接好
- 手機已開啟 USB 偵錯
- 手機上的授權彈窗已按允許
- 同一時間只連接一台 Android 裝置

找不到 `adb` 或 `exiftool` 時，請依照需求章節安裝對應工具。
