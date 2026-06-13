---
name: pixel-photo-backup
description: Back up Pixel or Android phone photos and videos to a Mac with ADB, then restore Finder file creation/modification dates from EXIF or video metadata. Use when the user asks to back up Pixel photos, copy Android camera media to macOS, sync only new phone media, fix backed-up photo dates, repair Finder date sorting, run an EXIF date dry-run, or troubleshoot this Pixel photo backup workflow.
---

# Pixel Photo Backup

## Overview

Use the bundled shell scripts for the actual backup and date repair work. Treat this skill as a guarded workflow: verify the environment, run the right script, interpret failures, and avoid rewriting the scripts unless the user asks to change behavior.

Bundled scripts:

- `scripts/backup_pixel.sh` backs up `/sdcard/DCIM/Camera` and `/sdcard/Pictures` to `~/Pictures/Pixel7Pro-Backup`.
- `scripts/fix_dates_pixel.sh` restores file creation and modification dates in `~/Pictures/Pixel7Pro-Backup` from media metadata.

## Workflow

1. Determine whether the user wants backup, date repair, both, or troubleshooting.
2. Before backup, ensure `adb` is available and the user has connected exactly one authorized Android device.
3. Before date repair, ensure `exiftool` is available and the backup directory exists.
4. Prefer a dry run before destructive date repair:

```sh
./scripts/fix_dates_pixel.sh --dry-run
```

5. Run the requested script from this skill directory, or from the repository root if the script has been copied there.
6. Summarize counts, failures, missing dependencies, and the backup path for the user.

## Back Up Media

Run:

```sh
./scripts/backup_pixel.sh
```

The script already:

- Checks for `adb`
- Detects authorized connected devices
- Rejects zero devices and multiple devices
- Creates the local backup directory
- Pulls only missing files or files whose size differs
- Preserves the phone folder layout under the backup directory

If `adb` is missing, tell the user to install it:

```sh
brew install android-platform-tools
```

If no device is found, ask the user to check USB connection, USB debugging, and the phone authorization prompt.

If multiple devices are found, ask the user to disconnect all but the target phone, or update the script to accept a specific serial if they want multi-device support.

## Fix Media Dates

Always prefer a preview first unless the user explicitly asks to apply changes immediately:

```sh
./scripts/fix_dates_pixel.sh --dry-run
```

Then apply:

```sh
./scripts/fix_dates_pixel.sh
```

The script restores:

- Photos: `FileModifyDate` and `FileCreateDate` from `DateTimeOriginal`
- Videos: `FileModifyDate` and `FileCreateDate` from `CreationDate`, falling back to `CreateDate`

If `exiftool` is missing, tell the user to install it:

```sh
brew install exiftool
```

If the backup directory is missing, run the backup workflow first or update `TARGET` in `scripts/fix_dates_pixel.sh` to match the user's backup location.

## Configuration

Default local backup directory:

```text
~/Pictures/Pixel7Pro-Backup
```

Default phone source directories:

```text
/sdcard/DCIM/Camera
/sdcard/Pictures
```

To change backup location or phone folders, edit `DEST` and `PHONE_DIRS` in `scripts/backup_pixel.sh`. If changing the backup location, also edit `TARGET` in `scripts/fix_dates_pixel.sh`.

Keep the root-level scripts and bundled skill scripts in sync when this repository includes both copies.
