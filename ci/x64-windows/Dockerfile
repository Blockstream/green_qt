# escape=`

# Use the latest Windows Server Core 2022 image.
FROM mcr.microsoft.com/windows/servercore:ltsc2022
# FROM mcr.microsoft.com/windows/servercore:ltsc2025

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

RUN `
    # Download the Build Tools bootstrapper.
    curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    `
    # Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --add Microsoft.VisualStudio.Workload.VCTools `
        --add Microsoft.VisualStudio.Component.VC.CMake.Project `
        --add Microsoft.VisualStudio.Component.VC.ATL `
        --add Microsoft.VisualStudio.Component.VC.MFC `
        --add Microsoft.VisualStudio.Component.CMake `
        --add Microsoft.VisualStudio.Component.Ninja `
        --includeRecommended `
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
    `
    # Cleanup
    && del /q vs_buildtools.exe

RUN curl -o install.ps1 https://community.chocolatey.org/install.ps1 && `
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 && `
    del install.ps1

RUN choco install git -y
RUN choco install 7zip -y
RUN choco install protoc -y

ENV RUSTUP_HOME=C:\rustup
ENV CARGO_HOME=C:\cargo
RUN curl -SL --output rustup-init.exe https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe && `
    rustup-init.exe -y --default-toolchain 1.88.0 --profile minimal --default-host x86_64-pc-windows-msvc && `
    \cargo\bin\rustup toolchain install 1.85.0-x86_64-pc-windows-msvc && `
    del rustup-init.exe

RUN curl -SL --output qt-online-installer-windows-x64-online.exe https://download.qt.io/official_releases/online_installers/qt-online-installer-windows-x64-online.exe

ARG QT_INSTALLER_JWT_TOKEN
ENV QT_INSTALLER_JWT_TOKEN=${QT_INSTALLER_JWT_TOKEN}
RUN qt-online-installer-windows-x64-online.exe `
    --root c:\\qt `
    --accept-licenses --default-answer --confirm-command --accept-obligations `
    install `
        qt.qt6.6112.win64_msvc2022_64 `
        qt.qt6.6112.addons.qt5compat `
        qt.qt6.6112.addons.qtconnectivity `
        qt.qt6.6112.addons.qtmultimedia `
        qt.qt6.6112.addons.qtserialport `
        qt.qt6.6112.addons.qtpositioning `
        extensions.qtwebengine.6112.win64_msvc2022_64 `
        qt.qt6.6112.addons.qtwebview `
        qt.qt6.6112.addons.qtwebchannel

ENV PREFIX=C:\deps

COPY countly.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && countly.bat"

COPY kdsingleapplication.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && kdsingleapplication.bat"

COPY zxing.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && zxing.bat"

COPY patches\ C:\patches
COPY sentry.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && sentry.bat"

COPY hidapi.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && hidapi.bat"

COPY leveldb.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && leveldb.bat"

COPY lwk.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && lwk.bat"

COPY glsdk.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && glsdk.bat"

COPY depends\ C:\depends
