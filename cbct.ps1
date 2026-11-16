param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateSet("C", "C++")]
    [string]$Language
)


# Environment Check
Write-Host "`n========== Environment Check ==========" -ForegroundColor Cyan

$EnvironmentValid = $true

# Check MSYS2_HOME
if ([string]::IsNullOrWhiteSpace($env:MSYS2_HOME)) {
    Write-Host "MSYS2_HOME is not configured." -ForegroundColor Red
    $EnvironmentValid = $false
}
else {
    $UcrtBin = Join-Path $env:MSYS2_HOME "ucrt64\bin"

    if (-not (Test-Path -LiteralPath $UcrtBin -PathType Container)) {
        Write-Host "UCRT64 directory not found: $UcrtBin" -ForegroundColor Red
        $EnvironmentValid = $false
    }
    else {
        $env:PATH = "$UcrtBin;$env:PATH"
        Write-Host "MSYS2 UCRT64: OK" -ForegroundColor Green

        # Check MSYS2 tools
        $RequiredTools = @(
            "gdb",
            "cmake",
            "ninja"
        )

        if ($Language -eq "C") {
            $RequiredTools += "gcc"
        }
        elseif ($Language -eq "C++") {
            $RequiredTools += "g++"
        }

        foreach ($Tool in $RequiredTools) {
            $ToolPath = Join-Path $UcrtBin "$Tool.exe"

            if (-not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
                Write-Host "${Tool}: NOT FOUND ($ToolPath)" -ForegroundColor Red
                $EnvironmentValid = $false
            }
            else {
                Write-Host "${Tool}: OK ($ToolPath)" -ForegroundColor Green
            }
        }
    }
}

# Check VS Code CLI
$CodeCommand = Get-Command code -ErrorAction SilentlyContinue

if ($null -eq $CodeCommand) {
    Write-Host "code: NOT FOUND" -ForegroundColor Red
    $EnvironmentValid = $false
}
else {
    Write-Host "code: OK ($($CodeCommand.Source))" -ForegroundColor Green
}

# Final check
if (-not $EnvironmentValid) {
    Write-Host "`nEnvironment check failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nEnvironment check passed." -ForegroundColor Green

#Build Project Folder
$ProjectPath = Join-Path (Get-Location) $Name

if (Test-Path -LiteralPath $ProjectPath){
    Write-Host "Project '$Name' already exists." -ForegroundColor Yellow
    exit 1
}

$Directories = @(
    "src",
    "include",
    "build",
    ".vscode"
)

try {
    # Project generation
    New-Item -ItemType Directory -Path $ProjectPath | Out-Null

    foreach ($directory in $Directories) {
        New-Item -ItemType Directory `
            -Path (Join-Path $ProjectPath $directory) | Out-Null
    }
}
catch {
    Write-Host "Project generation failed: $($_.Exception.Message)" -ForegroundColor Red

    if (Test-Path -LiteralPath $ProjectPath) {
        Remove-Item -LiteralPath $ProjectPath -Recurse -Force
    }

    exit 1
}

if($Language -eq "C")
{
    $Extension = ".c"
    $CMakeLanguage = "C"
    $StandardSetting = 'set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)'
    $MainSource = @'
#include <stdio.h>

int main(void)
{
    printf("Hello, World\n");

    return 0;
}
'@
$ReadMeLanguage = "C"
$ReadMeCompiler = "GCC"
$ReadMeLanguageStandard = "C17"
$ReadMeStandardLabel = "C Standard"
}elseif($Language -eq "C++")
{
    $Extension = ".cpp"
    $CMakeLanguage = "CXX"
    $StandardSetting = 'set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)'
    $MainSource = @'
#include <iostream>
using namespace std;

int main()
{
    cout << "Hello, World!\n";
    
    return 0;
}
'@
$ReadMeLanguage = "C++"
$ReadMeCompiler = "G++"
$ReadMeLanguageStandard = "C++23"
$ReadMeStandardLabel = "C++ Standard"
}

[System.IO.File]::WriteAllText(
    (Join-Path $ProjectPath "src\main$Extension"),
    $MainSource,
    [System.Text.UTF8Encoding]::new($true)
)

$CMakeLists = @"
cmake_minimum_required(VERSION 3.20)

project($Name LANGUAGES $CMakeLanguage)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

$StandardSetting

file(GLOB_RECURSE PROJECT_SOURCES CONFIGURE_DEPENDS
    "`${CMAKE_CURRENT_SOURCE_DIR}/src/*$Extension"
)

add_executable($Name `${PROJECT_SOURCES})

target_include_directories($Name PRIVATE
    "`${CMAKE_CURRENT_SOURCE_DIR}/include"
)

if(MSVC)
    target_compile_options($Name PRIVATE
        /W4
        $<$<CONFIG:Debug>:/Zi>
        $<$<CONFIG:Release>:/O2>
    )
else()
    target_compile_options($Name PRIVATE
        -Wall
        -Wextra
    )
endif()

set_target_properties($Name PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "`${CMAKE_BINARY_DIR}/bin"
)
"@

[System.IO.File]::WriteAllText(
    (Join-Path $ProjectPath "CMakeLists.txt"),
    $CMakeLists,
    [System.Text.UTF8Encoding]::new($true)
)

$RunScript = @'
param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug",

    [switch]$Quiet,

    [switch]$BuildOnly
)

$TotalTimer = [System.Diagnostics.Stopwatch]::StartNew()
$exitCode = 0

$BuildDir = Join-Path $PSScriptRoot "build\$Config"
$Target = "__PROJECT_NAME__"

#Timer Function
function Invoke-Timer {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]$Action,

        [switch]$SuppressStdout
    )

    Write-Host "`n========== $Name ==========" -ForegroundColor Cyan

    $Timer = [System.Diagnostics.Stopwatch]::StartNew()

    $global:LASTEXITCODE = 0

    try{
        if ($SuppressStdout) {
            & $Action 1>$null
        }
        else {
            & $Action *>&1 | Out-Host
        }

        $Code = $global:LASTEXITCODE
    }
    catch{
        Write-Host "[$Name] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $Code = 1
    }
    finally{
        $Timer.Stop()
        Write-Host "$Name time: $($Timer.Elapsed.TotalSeconds.ToString('F3')) s"
    }

    return $Code
}

# Main Process
do{
    # Configure
    $exitCode = Invoke-Timer -Name "Configure" -Action {
        cmake -S $PSScriptRoot -B $BuildDir -G Ninja `
            "-DCMAKE_BUILD_TYPE=$Config"
    } -SuppressStdout:$Quiet

    if ($exitCode -ne 0) {
        Write-Host "CMake Configure failed with exit code: $exitCode" -ForegroundColor Red
        break
    }

    # Build
    $exitCode = Invoke-Timer -Name "Build" -Action {
        cmake --build $BuildDir --target $Target
    } -SuppressStdout:$Quiet

    if ($exitCode -ne 0) {
        Write-Host "CMake Build failed with exit code: $exitCode" -ForegroundColor Red
        break
    }

    # Build Only
    if ($BuildOnly) {
        Write-Host "Build completed. Execution skipped." -ForegroundColor Green
        break
    }

    # Execute
    $ExecutableName = $Target

    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )) {
        $ExecutableName += ".exe"
    }

    $Executable = Join-Path $BuildDir "bin\$ExecutableName"

    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
        Write-Host "Executable not found: $Executable" -ForegroundColor Red
        $exitCode = 1
        break
    }

    Write-Host "`n========== Execute ==========" -ForegroundColor Cyan

    $ExecuteTimer = [System.Diagnostics.Stopwatch]::StartNew()

    $global:LASTEXITCODE = 0

    try{
        & $Executable
        $exitCode = $global:LASTEXITCODE
    }
    catch {
        Write-Host "[$Target] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $exitCode = 1
    }
    finally{
        $ExecuteTimer.Stop()
        Write-Host "Execute time: $($ExecuteTimer.Elapsed.TotalSeconds.ToString('F3')) s"
    }

    if ($exitCode -ne 0) {
        Write-Host "Program exit code: $exitCode" -ForegroundColor Red
        break 
    }

    Write-Host "Program exit code: $exitCode" -ForegroundColor Green
}while($false)



# Final Summary
$TotalTimer.Stop()

Write-Host "----------------------------------------"
Write-Host ("Total time: {0:F6} s" -f $TotalTimer.Elapsed.TotalSeconds)

exit $exitCode
'@

$RunScript = $RunScript.Replace("__PROJECT_NAME__", $Name)

$RunScriptPath = Join-Path $ProjectPath "run.ps1"

[System.IO.File]::WriteAllText(
    $RunScriptPath,
    $RunScript,
    [System.Text.UTF8Encoding]::new($true)
)

$GitIgnore = @'
build/
'@

[System.IO.File]::WriteAllText(
    (Join-Path $ProjectPath ".gitignore"),
    $GitIgnore,
    [System.Text.UTF8Encoding]::new($false)
)

$Settings = @'
{
    "terminal.integrated.stickyScroll.enabled": false,
    "terminal.integrated.env.windows": {
        "PATH": "${env:MSYS2_HOME}/ucrt64/bin;${env:PATH}"
    },
    "C_Cpp.default.intelliSenseMode": "windows-gcc-x64",
    "C_Cpp.default.cStandard": "c17",
    "C_Cpp.default.cppStandard": "c++23",
    "editor.quickSuggestions": {
        "other": "on",
        "comments": "off",
        "strings": "on"
    },
    "editor.suggestOnTriggerCharacters": true,
    "editor.acceptSuggestionOnCommitCharacter": true,
    "editor.tabCompletion": "on",
    "editor.parameterHints.enabled": true,
    "editor.hover.enabled": "on",

    "C_Cpp.default.compileCommands": "${workspaceFolder}/build/Debug/compile_commands.json",

    "C_Cpp.intelliSenseEngine": "default",
    "C_Cpp.autocomplete": "default",
    "C_Cpp.errorSquiggles": "enabled",
    "C_Cpp.enhancedColorization": "enabled",
	
	"C_Cpp.default.includePath": [
		"${workspaceFolder}/include",
		"${workspaceFolder}/src"
	],
	
	"terminal.integrated.defaultProfile.windows": "PowerShell",
	
	"terminal.integrated.profiles.windows": {
	  "PowerShell": {
		"source": "PowerShell",
		"args": [
                 "-NoExit", 
                 "-Command", 
                 "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); chcp 65001"
        ]
	  }
	}
}
'@

[System.IO.File]::WriteAllText(
    (Join-Path $ProjectPath ".vscode\settings.json"),
    $Settings,
    [System.Text.UTF8Encoding]::new($true)
)

$Tasks = @'

{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "CBCT: Build",
            "type": "process",
            "command": "powershell.exe",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${workspaceFolder}/run.ps1",
                "-Config",
                "Debug",
                "-BuildOnly"
            ],
            "options": {
                "cwd": "${workspaceFolder}"
            },
            "problemMatcher": [],
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },
        {
            "label": "CBCT: Run",
            "type": "process",
            "command": "powershell.exe",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${workspaceFolder}/run.ps1",
                "-Config",
                "Debug"
            ],
            "options": {
                "cwd": "${workspaceFolder}"
            },
            "problemMatcher": []
        },
        {
            "label": "CBCT: Build (Release)",
            "type": "process",
            "command": "powershell.exe",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${workspaceFolder}/run.ps1",
                "-Config",
                "Release",
                "-BuildOnly"
            ],
            "options": {
                "cwd": "${workspaceFolder}"
            },
            "problemMatcher": []
        },
        {
            "label": "CBCT: Run (Release)",
            "type": "process",
            "command": "powershell.exe",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${workspaceFolder}/run.ps1",
                "-Config",
                "Release"
            ],
            "options": {
                "cwd": "${workspaceFolder}"
            },
            "problemMatcher": []
        }
    ]
}

'@

Set-Content `
	-LiteralPath (Join-Path $ProjectPath ".vscode\tasks.json") `
	-Value $Tasks -Encoding UTF8

$Launch = @'

{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "CBCT: Debug",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/Debug/bin/__PROJECT_NAME__.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "${env:MSYS2_HOME}/ucrt64/bin/gdb.exe",
            "preLaunchTask": "CBCT: Build"
        }
    ]
}

'@

$Launch = $Launch.Replace("__PROJECT_NAME__", $Name)

Set-Content `
	-LiteralPath (Join-Path $ProjectPath ".vscode\launch.json") `
	-Value $Launch -Encoding UTF8

if ($Language -eq "C") {
    $CompilerExecutable = "gcc.exe"
}
elseif ($Language -eq "C++") {
    $CompilerExecutable = "g++.exe"
}

$Properties = @'

{
    "configurations": [
        {
            "name": "CBCT-GCC",

            "compilerPath": "${env:MSYS2_HOME}/ucrt64/bin/__COMPILER__",

            "intelliSenseMode": "windows-gcc-x64",

            "includePath": [
                "${workspaceFolder}/**"
            ],

            "defines": [],

            "cStandard": "c17",

            "cppStandard": "c++23",

            "compileCommands": "${workspaceFolder}/build/Debug/compile_commands.json"
        }
    ],

    "version": 4
}

'@

$Properties = $Properties.Replace(
    "__COMPILER__",
    $CompilerExecutable
)

Set-Content `
	-LiteralPath (Join-Path $ProjectPath ".vscode\c_cpp_properties.json") `
	-Value $Properties -Encoding UTF8

$Ticks = '`' * 3

$Readme = @"

# $Name

## Overview

A $ReadMeLanguage project built with $ReadMeCompiler, CMake and Ninja.

## Prerequisites

### Build Environment

- Operating System: Windows 10 / 11
- Shell: Windows PowerShell 5.1+
- Toolchain: MSYS2 UCRT64
- Compiler: ${ReadMeCompiler}
- Build System: CMake 3.20+
- Build Generator: Ninja

Make sure the MSYS2 UCRT64 bin directory is available in PATH.

### Development and Debugging

- IDE: Visual Studio Code
- Extension: Microsoft C/C++ (ms-vscode.cpptools)
- Debugger: GDB

## Development Environment

- Language: $ReadMeLanguage
- Compiler: $ReadMeCompiler
- Build System: CMake
- Build Generator: Ninja
- ${ReadMeStandardLabel}: $ReadMeLanguageStandard

## Project Structure

$($Ticks)text
$Name/
├── CMakeLists.txt
├── README.md
├── run.ps1
├── src/
│   └── main$Extension
├── include/
├── build/
│   ├── Debug/
│   └── Release/
└── .vscode/
    ├── c_cpp_properties.json
    ├── settings.json
    ├── tasks.json
    └── launch.json
$($Ticks)

## Build and Run

Default configuration: Debug

### Debug

Build and execute:

$($Ticks)powershell
.\run.ps1 -Config Debug
$($Ticks)

Build only:

$($Ticks)powershell
.\run.ps1 -Config Debug -BuildOnly
$($Ticks)

### Release

Build and execute:

$($Ticks)powershell
.\run.ps1 -Config Release
$($Ticks)

Build only:

$($Ticks)powershell
.\run.ps1 -Config Release -BuildOnly
$($Ticks)

## Visual Studio Code

The project includes the following VS Code tasks:

| Task | Description |
|---|---|
| CBCT: Build | Build Debug |
| CBCT: Run | Build and execute Debug |
| CBCT: Build (Release) | Build Release |
| CBCT: Run (Release) | Build and execute Release |

### Debugging

1. Open the project folder in Visual Studio Code.
2. Open a source file.
3. Set a breakpoint.
4. Press F5 to start debugging with GDB.

The Debug configuration automatically builds the project before launching the debugger.

"@

Set-Content `
	-LiteralPath (Join-Path $ProjectPath "README.md") `
	-Value $Readme -Encoding UTF8
		
#Open Visual Studio Code
code $ProjectPath

Write-Host "Project '$Name' created successfully at: $ProjectPath" -ForegroundColor Green
