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

RUN curl -SL --output qt-online-installer-windows-x64-online.exe https://download.qt.io/official_releases/online_installers/qt-online-installer-windows-x64-online.exe

ARG QT_INSTALLER_JWT_TOKEN
ENV QT_INSTALLER_JWT_TOKEN=${QT_INSTALLER_JWT_TOKEN}
RUN qt-online-installer-windows-x64-online.exe `
    --root c:\\qt --accept-licenses `
    --default-answer `
    --confirm-command `
    --accept-obligations `
    install qt6.8.3-msvc2022-full-dev

ENV PREFIX=C:\deps

COPY countly.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && countly.bat"

COPY kdsingleapplication.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && kdsingleapplication.bat"

COPY zxing.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && zxing.bat"

COPY hidapi.bat .
RUN cmd /S /C ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" x64 && hidapi.bat"

COPY depends\ C:\depends
