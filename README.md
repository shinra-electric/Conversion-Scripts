# Conversion Scripts
Scripts for converting various file types suitable for emulation on macOS

## CHD
The CHD file format ([Compressed Hunks of Data](https://en.wikipedia.org/wiki/MAME#ROM_data)) was originally created by the MAME team to handle various disc formats used by arcade machines. But due to its versatility and lossless compression, it has become popular with many emulators for consoles that used disc media storage.<br> 

A few of the emulators that support CHD files include: 

- [Duckstation](https://www.duckstation.org) (PS1)
- [PCSX2](https://pcsx2.net) (PS2)
- [PPSSPP](https://www.ppsspp.org) (PSP)
- [Flycast](https://github.com/flyinghead/flycast) (Dreamcast)

It is especially useful for PlayStation 1 games, as the ISO format is incompatible with many games that have multiple tracks. 
> [!NOTE]
> Currently the CHD conversion may lose track data for games that have [more than two audio tracks](https://github.com/mamedev/mame/issues/10308).<br>
> This should be fixed in future chdman updates<br>
> Until it is fixed the best format for PS1 games is BIN/CUE