# QtScripts

Collection of scripts to download and build Qt.

## downloadAndRebuildQt5.sh

Shell script to be used to download and build Qt5 on Windows. It can e.g. with bash shell which comes with [Git for Windows](https://git-scm.com/download/win).

### Syntax
```
downloadAndRebuildQt5.sh [-d][-D <base_dir>][-V <vs_version>][-T <vs_type>]
                         [-p <platforms>] -v <qt_version>

Options:
   -d:             Delete Qt downloads and build directories before downloading
                   and building them.
   -D <base_dir>   Existing base directory where to build Qt libs
                   e.g. C:\Temp\libs or C:/Temp/libs,
                   or /c/Temp/libs.
                   Default is the current directory.
   -V <vs_version> The Visual Studio version, 2017 or 2019.
                   If not set the script looks for an installed VS version
                   2019 or 2017, in this order.
   -T <vs_type>    The Visual Studio type, Enterprise, Professional or
                   Community. If not set the script looks for an installed VS
                   type Enterprise, Professional or Community, in this order.
   -p <platforms>  The platforms to be build, Win32, x64 or Win32_x64.
                   If not set x64 is build. Win32_x64 builds for both
                   Win32 and x64 platforms.
   -v <qt_version> The Qt version to be build. Syntax: 5.<minor>.<patch>
```
