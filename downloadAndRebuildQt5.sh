#!/usr/bin/sh
#
# Copyright (c) 2021 Wolfgang Schwotzer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Download and rebuild Qt 5.x.y libraries.
#
# Syntax:
#    downloadAndRebuildQt5.sh [-d][-D <base_dir>][-V <vs_version][-T <vs_type>][-p <platforms>] -v <qt_version>
# Options:
#   -d:             Delete Qt downloads and build directories before downloading
#                   and building them.
#   -D <base_dir>   Existing base directory where to build Qt libs
#                   e.g. C:\\Temp\\libs or C:/Temp/libs,
#                   or /c/Temp/libs.
#                   Default is the current directory.
#   -V <vs_version> The Visual Studio version, 2017 or 2019.
#                   If not set the script looks for an installed VS version
#                   2019 or 2017, in this order.
#   -T <vs_type>    The Visual Studio type, Enterprise, Professional or
#                   Community. If not set the script looks for an installed VS
#                   type Enterprise, Professional or Community, in this order.
#   -p <platforms>  The platforms to be build, Win32, x64 or Win32_x64.
#                   If not set x64 is build. Win32_x64 builds for both
#                   Win32 and x64 platforms.
#   -v qt_version   Specify Qt version to be build.
#                   Syntax: <major>.<minor>.<patch>
#
# Prerequisites to build Qt on Windows see:
#    https://doc.qt.io/qt-5/windows-requirements.html
# Detailed instructions how to build Qt from Source see:
#    https://doc.qt.io/qt-5/windows-building.html
#
# Minumum requirements to sucessfully execute this script:
# - A recent ActivePerl installation from https://www.activestate.com/activeperl
# - Python 3.x from https://www.python.org/downloads/
# - CMake >= 3.15 from https://cmake.org/download/
# - jom.exe (nmake replacement) from https://wiki.qt.io/Jom

# Supported platforms:
splatforms="Win32 x64 Win32_x64"
# Appropriate Visual Studio versions and types:
vsversions="2019 2017"
vstypes="Enterprise Professional Community"

# DO NOT CHANGE ANYTHING BEYOND THIS LINE
#========================================

function usage() {
    echo "Syntax:"
    echo "   downloadAndRebuildQt5.sh [-d][-D <base_dir>][-V <vs_version][-T <vs_type>][-p <platforms>] -v <qt_version>"
    echo "Options:"
    echo "   -d:             Delete Qt downloads and build directories before downloading"
    echo "                   and building them."
    echo "   -D <base_dir>   Existing base directory where to build Qt libs"
    echo "                   e.g. C:\\\\Temp\\\\libs or C:/Temp/libs,"
    echo "                   or /c/Temp/libs."
    echo "                   Default is the current directory."
    echo "   -V <vs_version> The Visual Studio version, 2017 or 2019."
    echo "                   If not set the script looks for an installed VS version"
    echo "                   2019 or 2017, in this order."
    echo "   -T <vs_type>    The Visual Studio type, Enterprise, Professional or"
    echo "                   Community. If not set the script looks for an installed VS"
    echo "                   type Enterprise, Professional or Community, in this order."
    echo "   -p <platforms>  The platforms to be build, Win32, x64 or Win32_x64."
    echo "                   If not set x64 is build. Win32_x64 builds for both"
    echo "                   Win32 and x64 platforms."
    echo "   -v <qt_version> The Qt version to be build. Syntax: 5.<minor>.<patch>"
    echo ""
    echo "All config combinations Win32/x64 and Debug/Release are build."
    echo "The created directory hierarchy is:"
    echo "    <base_dir>"
    echo "         +--Qt"
    echo "            +--Qt5.x.y"
    echo "                  +--Win32"
    echo "                       +--..."
    echo "                  +--x64"
    echo "                       +--..."
}

qtversion=
delete=
basedir=
vsversion=
vstype=
platforms=x64
while :
do
    case "$1" in
        -d) delete=yes;;
        --) shift; break;;
        -h)
            echo "Download and rebuild Qt 5.x.y libraries."
            echo ""
            usage; exit 0;;
        -v)
            if [ -n "$2" ]; then
                qtversion=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi;;
        -D)
            if [ -n "$2" ]; then
                basedir=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi;;
        -V)
            if [ -n "$2" ]; then
                vsversion=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi;;
        -T)
            if [ -n "$2" ]; then
                vstype=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi;;
        -p)
            if [ -n "$2" ]; then
                platforms=$2
                shift
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi;;
        *) break;;
    esac
    shift
done

check_value() {
    if [ "x$1" == "x" ]; then
        return 0; # no value is valid
    fi
    for value in $2
    do
        if [ "$value" == "$1" ]; then
            return 0
        fi
    done
    return 1
}
if [ "x$qtversion" == "x" ]; then
    echo "Error: Qt version has to be specified with -v 5.<minor>.<patch>." >&2
    usage
    exit 1
fi
match=`echo $qtversion | sed -n "s/^\([5]\+\.[0-9]\+\.[0-9]\+\)$/\1/p"`
if [ "x$match" == "x" ]; then
    echo "Error: Qt version '$qtversion' has invalid syntax. Must be 5.<minor>.<patch>" >&2
    usage
    exit 1
fi

if [ ! "x$basedir" == "x" ] && [ ! -d $basedir ]; then
    echo "*** Error: Base directory \"$basedir\" does not exist."
    usage
    exit 1
fi
# Look for an appropriate Visual Studio installation to set all needed variables:
check_value "$vsversion" "$vsversions"
if [ $? -ne 0 ]; then
    echo "*** Error: Visual Studio version \"$vsversion\" is not supported."
    usage
    exit 1
fi

check_value "$vstype" "$vstypes"
if [ $? -ne 0 ]; then
    echo "*** Error: Visual Studio type \"$vstype\" is not supported."
    usage
    exit 1
fi

check_value "$platforms" "$splatforms"
if [ $? -ne 0 ]; then
    echo "*** Error: platforms type \"$platforms\" is not supported."
    usage
    exit 1
fi
if [ $platforms == "Win32_x64" ]; then
    platforms="Win32 x64"
fi

if [ "x$vstype" == "x" ]; then
    if [ "x$vsversion" == "x" ]; then
        # No vstype or vsversion specified, look for it.
        for vsversion in $vsversions
        do
            for vstype in $vstypes
            do
                msvcscript="C:\Program Files (x86)\Microsoft Visual Studio\\$vsversion\\$vstype\VC\Auxiliary\Build\vcvarsall.bat"
                if [ -f "$msvcscript" ]; then
                    break
                fi
            done
            if [ -f "$msvcscript" ]; then
                break
            fi
        done
    else
        # vsversion specified, look for vstype.
        for vstype in $vstypes
        do
            msvcscript="C:\Program Files (x86)\Microsoft Visual Studio\\$vsversion\\$vstype\VC\Auxiliary\Build\vcvarsall.bat"
            if [ -f "$msvcscript" ]; then
                break
            fi
        done
    fi
else
    if [ "x$vsversion" == "x" ]; then
        # vstype specified, look for vsversion.
        for vsversion in $vsversions
        do
            msvcscript="C:\Program Files (x86)\Microsoft Visual Studio\\$vsversion\\$vstype\VC\Auxiliary\Build\vcvarsall.bat"
            if [ -f "$msvcscript" ]; then
                break
            fi
        done
    else
        # both vstype and vsversion specified.
        msvcscript="C:\Program Files (x86)\Microsoft Visual Studio\\$vsversion\\$vstype\VC\Auxiliary\Build\vcvarsall.bat"
    fi
fi

if [ ! -f "$msvcscript" ]; then
    echo "*** Error: No appropriate Visual Studio Installation found."
    usage
    exit 1
fi

qtversion=$match
qtmamiversion=`echo $qtversion | sed -e "s/\([0-9]\+\.[0-9]\+\).*/\1/"`

# Create the url from which to download a specific version (Supported: Qt5.minor.patch)
qturl=`echo "https://download.qt.io/archive/qt/${qtmamiversion}/${qtversion}/submodules/qtbase-everywhere-src-${qtversion}.zip"`

MSBUILDDISABLENODEREUSE=1
export MSBUILDDISABLENODEREUSE

builddir="build${qtversion}"
tgtdir="Qt${qtversion}"

# Convert an absolute path with Windows syntax into a path
# with MINGW syntax.
as_mingw_path() {
    drive=`echo $1 | sed "s/^\([a-zA-Z]\):\(.*\)/\1/"`
    path=`echo $1 | sed "s/^\([a-zA-Z]\):\(.*\)/\2/"`
    expr='s:\\:/:g'
    path=`echo $path | sed $expr`
    echo /$drive$path
}

# Convert an absolute path with MINGW syntax into a path
# with Windows syntax.
as_windows_path() {
    path=`echo $1 | sed "s/^.//"`
    expr='s:/:\\:g'
    path=`echo $path | sed $expr`
    drive=`echo $path | sed "s:\(^.\).*:\U\1:"`
    path=`echo $path | sed "s/^.//"`
    echo $drive:$path
}

# Convert a MINGW path relative to the current directory
# into an absolute path with Windows syntax.
as_absolute_windows_path() {
    absdir=`pwd`
    absdir="$absdir/$1"
    absdir=$( as_windows_path $absdir )
    echo $absdir
}

# Convert a Windows path by doubling any backslash character.
as_doublebslash_windows_path() {
    path=`echo $1 | sed 's:\([\\]\):\1\1:g'`
    echo $path
}

# Create the Qt build batch script.
# $1: Batch script path setting all MSVC variables
# $2: Architecture (x86 or amd64)
# $3: Root path of the Qt source distribution (absolute Windows path)
# $4: Path Qt build directory (absolute Windows path)
# $5: Path of the generated batch script
create_qt_build_script() {
    echo CALL \"$1\" $2 >$5
    echo IF %ERRORLEVEL% neq 0 EXIT /b %ERRORLEVEL% >>$5
    echo SET _ROOT=$3 >>$5
    echo SET PATH=\%_ROOT\%\\bin\;\%PATH\% >>$5
    echo SET _ROOT= >>$5
    echo >>$5
    echo cd \"$4\" >>$5
    echo CALL \"$3\\configure.bat\" -redo >>$5
    echo IF %ERRORLEVEL% neq 0 EXIT /b %ERRORLEVEL% >>$5
    echo jom.exe >>$5
    echo IF %ERRORLEVEL% neq 0 EXIT /b %ERRORLEVEL% >>$5
    echo jom.exe install >>$5
    echo IF %ERRORLEVEL% neq 0 EXIT /b %ERRORLEVEL% >>$5
}

# Create the Qt build config file.
# $1: Platform (Win32 or x64)
# $2: The target directory where the build artefacts are copied
# $3: Path to the config file
create_config_file() {
    echo "-platform" > $3
    echo "win32-msvc2019" >> $3
    echo "-prefix" >> $3
    echo "$2" >>$3
    echo "-debug-and-release" >>$3
    echo "-feature-network" >>$3
    echo "-feature-sql" >>$3
    echo "-feature-concurrent" >>$3
    echo "-feature-dbus" >>$3
    echo "-feature-xml" >>$3
    echo "-no-feature-testlib" >>$3
    echo "-make" >>$3
    echo "examples" >>$3
    echo "-qt-zlib" >>$3
    echo "-qt-harfbuzz" >>$3
    echo "-opengl" >>$3
    echo "desktop" >>$3
    echo "-c++std" >>$3
    echo "c++11" >>$3
    echo "-mp" >>$3
    echo "-confirm-license" >>$3
    echo "-opensource" >>$3
}

check_curl_exists() {
    curlpath=`which curl 2>/dev/null`
    if [ "x$curlpath" = "x" ]; then
        echo "*** Error: curl not found."
        echo "  curl can be downloaded from"
        echo "  https://curl.haxx.se/download.html"
        echo "  The executable has to be copied into the git installation"
        echo "  mingw32/bin or mingw64/bin."
        exit 1
    fi
}

check_jom_exists() {
    jompath=`which jom 2>/dev/null`
    if [ "x$jompath" = "x" ]; then
        echo "*** Error: jom not found."
        echo "  jom can be downloaded from"
        echo "  https://wiki.qt.io/Jom"
        echo "  The executable has to be copied into PATH."
        exit 1
    fi
}

urls=`echo "$qturl"`
qtdir=Qt
if [ ! "x$basedir" == "x" ]; then
    cd $basedir
fi
if [ ! -d $qtdir ]; then
    mkdir $qtdir;
fi

# Option -d: delete previously downloaded packages and intermediate directories
if [ "$delete" = "yes" ]; then
    echo deleting all...
    for url in $urls
    do
        file=$(basename "$url")
        if [ -r $qtdir/$file ]; then
            echo deleting file $qtdir/$file...
            rm -f $qtdir/$file
        fi
        # evaluate directory name by cutting off the file extension (e.g. zip)
        filebase=`echo "$file" | sed -e "s/\(.\+\)\.\(zip\|tar.gz\)/\1/"`
        directory=$filebase
        if [ -d $qtdir/$directory ]; then
            echo deleting directory $qtdir/$directory...
            rm -rf $qtdir/$directory
        fi
    done
    if [ -d $qtdir/$builddir ]; then
        echo deleting directory $qtdir/$builddir...
        rm -rf $qtdir/$builddir
    fi
    if [ -d $qtdir/$tgtdir ]; then
        echo deleting directory $qtdir/$tgtdir...
        rm -rf $qtdir/$tgtdir
    fi
 fi

# Download files (Only if package not already downloaded or deleted before)
for url in $urls
do
    file=$(basename "$url")
    if [ ! -r $qtdir/$file ]; then
        check_curl_exists
        echo downloading $file...
        curl -# -L $url > "$qtdir/$file"
    fi
done
if [ ! "$?" == "0" ]; then
    echo "Error: Download failed. Aborted." >&2
    rm -f $qtdir/$file
    exit 1
fi

# Unpacking files
# Supported extensions: tar.gz or zip
qtsrcdir=
for url in $urls
do
    file=$(basename "$url")
    if [ -r $qtdir/$file ]; then
        extension=`echo "$file" | sed -e "s/.\+\(zip\|tar.gz\)/\1/"`
        filebase=`echo "$file" | sed -e "s/\(.\+\)\.\(zip\|tar.gz\)/\1/"`
        directory=$filebase
        if [ "$url" == "$qturl" ]; then
            qtsrcdir=$qtdir/$directory
        fi
        if [ ! -d $qtdir/$directory ]; then
            echo unpacking $file into $qtdir...
            case "$extension" in
                tar.gz) tar -C $qtdir xfz $qtdir/$file ;;
                zip) unzip -q $qtdir/$file -d $qtdir ;;
            esac
            if [ ! "$?" == "0" ]; then
                echo "Error: Unpacking file failed. Aborted." >&2
                exit 1
            fi
            # Wait for 2 seconds otherwise the mv could fail
            sleep 2
        fi
    fi
done

if [ ! -d $qtdir/$builddir ]; then
    mkdir $qtdir/$builddir;
fi

if [ ! -d $qtdir/$tgtdir ]; then
    mkdir $qtdir/$tgtdir;
fi

absqttgtdir=$( as_absolute_windows_path $qtdir/$tgtdir )

check_jom_exists

# Create batch script to build Qt libraries for
# all requested platforms and execute it.
for platform in $platforms
do
    directory="${builddir}/${platform}"
    if [ ! -d $qtdir/$directory ]; then
        mkdir $qtdir/$directory;
    fi
    arch=x86
    if [ "x$platform" = "xx64" ]; then
        arch=amd64;
    fi

    configoptpath=$qtdir/$directory/config.opt
    create_config_file $platform $absqttgtdir\\$platform $configoptpath
    absqtsrcdir=$( as_absolute_windows_path $qtsrcdir )
    absqtbuilddir=$( as_absolute_windows_path $qtdir/$directory )
    batchscript=$qtdir/$directory/build_qt.bat
    create_qt_build_script "$msvcscript" $arch "$absqtsrcdir" "$absqtbuilddir" $batchscript

    echo building $platform Qt $qtversion libraries...
    cmd < $batchscript
    if [ ! "$?" == "0" ]; then
        echo "Error: Building Qt libraries. Aborted." >&2
        exit 1
    fi
done

absqtdir=$( as_absolute_windows_path $qtdir )
echo ""
echo "Finished successfully."
echo "Qt libs build in $absqtdir."
