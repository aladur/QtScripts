| Qt5 build on VS2019 and VS2022 | Qt6 build on VS2019 and VS2022 |
|--------------------------------|--------------------------------|
| [![github actions](https://github.com/aladur/QtScripts/actions/workflows/build-qt5.yml/badge.svg?branch=main)](https://github.com/aladur/QtScripts/actions/workflows/build-qt5.yml) | [![github actions](https://github.com/aladur/QtScripts/actions/workflows/build-qt6.yml/badge.svg?branch=main)](https://github.com/aladur/QtScripts/actions/workflows/build-qt6.yml) |

# QtScripts

Collection of scripts to download and build Qt.

## downloadAndRebuildQt.sh

Shell script to be used to download and build Qt5.x.y or Qt6.x.y on Windows. It is executable with bash shell which comes with [Git for Windows](https://git-scm.com/download/win).

### Syntax
```
downloadAndRebuildQt.sh [-d][-D <base_dir>][-V <vs_version>][-T <vs_type>]
                        [-p <platforms>][-s] -v <qt_version>

Options:
   -d:             Delete Qt downloads and build directories before downloading
                   and building them.
   -D <base_dir>   Existing base directory where to build Qt libs
                   e.g. C:\\Temp\\libs or C:/Temp/libs,
                   or /c/Temp/libs.
                   Default is the current directory.
   -V <vs_version> The Visual Studio version, 2017 or 2019.
                   If not set the script looks for an installed VS version
                   For Qt5: 2022, 2019 or 2017, in this order.
                   For Qt6: 2022 or 2019, in this order.
   -T <vs_type>    The Visual Studio type, Enterprise, Professional or
                   Community. If not set the script looks for an installed VS
                   type Enterprise, Professional or Community, in this order.
   -p <platforms>  For Qt5 the platforms to be build, Win32, x64 or Win32_x64.
                   If not set x64 is build. Win32_x64 builds for both
                   Win32 and x64 platforms. Qt6 only supports x64.
   -s              Suppress progress bar when downloading files.
   -v <qt_version> The Qt version to be build. Syntax: <major>.<minor>.<patch>
                   Supported major version is 5 or 6.
   -m <mirror>     Use mirror site base url for download. It should contain
                   an 'archive' folder. Default is the Qt download site:
                   https://download.qt.io.
```
Look at [https://download.qt.io/archive/qt/](https://download.qt.io/archive/qt/) for available versions.
Look at [https://download.qt.io/static/mirrorlist/](https://download.qt.io/static/mirrorlist/) for available download mirrors.
