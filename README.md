# CBCT
## C/C++ Build and Compile Tools

**Version: 1.0.0**

CBCT 是一套以 PowerShell、CMake、Ninja 與 MSYS2 UCRT64 為基礎的 C/C++ 專案生成工具。

透過 `cbct.ps1`，使用者可以快速建立具有標準目錄結構、建置腳本及 Visual Studio Code 開發設定的 C/C++ 專案。

CBCT 整合以下工具：

- GCC / G++
- GDB
- CMake
- Ninja
- Visual Studio Code
- Microsoft C/C++ Extension

---

# 1. Features

- 自動建立 C / C++ 專案目錄。
- 支援 C17 與 C++23。
- 自動生成 `CMakeLists.txt`。
- 使用 CMake 與 Ninja 管理專案建置。
- 支援 Debug 與 Release 組態。
- 提供統一的專案建置與執行腳本。
- 支援建置與執行分離。
- 提供建置計時資訊。
- 自動生成 VS Code 開發設定。
- 整合 GCC / G++ IntelliSense。
- 整合 GDB 除錯環境。
- 自動生成 README.md。
- 使用 `.gitignore` 排除建置產物。

# 2. System Requirements

## 2.1 Operating System

- Windows 10
- Windows 11

## 2.2 Required Software

| Software | Requirement | Purpose |
|---|---|---|
| Windows PowerShell | 5.1 or later | 執行 PowerShell 腳本 |
| MSYS2 | UCRT64 environment | 開發工具鏈 |
| GCC | 支援 C17 | C compiler |
| G++ | 支援 C++23 | C++ compiler |
| GDB | MSYS2 UCRT64 | Debugger |
| CMake | 3.20 or later | Build system |
| Ninja | Installed | Build generator |
| Visual Studio Code | Installed | Development environment |
| Microsoft C/C++ Extension | Installed | IntelliSense and debugging |

**注意：** C++23 的實際支援程度取決於 G++ 版本。建議使用較新的 GCC 版本。

# 3. Installation

## 3.1 Install MSYS2

前往 MSYS2 官方網站：

https://www.msys2.org/

下載並安裝 MSYS2。

安裝完成後，開啟 **MSYS2 UCRT64** 終端機。

更新套件資料庫及已安裝套件：

```bash
pacman -Syu
```

如果更新過程要求關閉終端機，請依照提示重新開啟 UCRT64 終端機，再繼續更新。

## 3.2 Install Required Packages

在 MSYS2 UCRT64 終端機執行：

```bash
pacman -S --needed \
    mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-gdb \
    mingw-w64-ucrt-x86_64-cmake \
    mingw-w64-ucrt-x86_64-ninja
```

這些套件提供：

- GCC / G++
- GDB
- CMake
- Ninja

## 3.3 Configure MSYS2_HOME

CBCT 使用環境變數 `MSYS2_HOME` 定位 MSYS2 安裝目錄。

例如，假設 MSYS2 安裝在：

```text
C:\msys64
```

則應設定：

```text
MSYS2_HOME=C:\msys64
```

設定方式：

1. 開啟 Windows「編輯系統環境變數」。
2. 進入「環境變數」。
3. 在使用者變數中新增 `MSYS2_HOME`。
4. 將變數值設定為 MSYS2 安裝根目錄。
5. 儲存設定並重新開啟 PowerShell。

確認設定：

```powershell
$env:MSYS2_HOME
```

應顯示：

```text
C:\msys64
```

CBCT 會透過此變數定位：

```text
%MSYS2_HOME%\ucrt64\bin
```

## 3.4 Configure PATH

建議將以下路徑加入 Windows 使用者 PATH：

```text
%MSYS2_HOME%\ucrt64\bin
```

這可以讓 PowerShell、VS Code 及其他開發工具找到 MSYS2 UCRT64 的執行檔。

CBCT 執行時也會將 UCRT64 的 `bin` 目錄加入目前 PowerShell 程序的 PATH。

## 3.5 Install Visual Studio Code

前往官方網站下載：

https://code.visualstudio.com/

安裝 Visual Studio Code。

確認可以在 PowerShell 中執行：

```powershell
code --version
```

如果系統找不到 `code` 指令，請確認 VS Code 的 CLI 已加入 PATH。

## 3.6 Install Microsoft C/C++ Extension

在 VS Code Extensions 中搜尋：

```text
C/C++
```

安裝 Microsoft 提供的：

**C/C++ — ms-vscode.cpptools**

此擴充套件提供：

- IntelliSense
- 程式碼補全
- 錯誤提示
- GDB 除錯整合

# 4. CBCT Installation

CBCT 不需要額外安裝程序。

將 `cbct.ps1` 放在預計存放 C/C++ 專案的工作目錄即可。

例如：

```text
vs_code_projects/
│
├── cbct.ps1
│
├── test_c/
│   └── ...
│
└── test_cpp/
    └── ...
```

**建議將 `cbct.ps1` 直接放在工作目錄，不需要額外建立 `CBCT/` 或 `projects/` 資料夾。**

如此一來，只要在該目錄開啟 PowerShell，就能直接使用 `.\cbct.ps1` 建立專案，無須輸入較長的腳本路徑。

# 5. Environment Check

CBCT 在建立專案前會自動檢查開發環境。

檢查項目如下：

| Component | Check |
|---|---|
| MSYS2_HOME | 確認環境變數是否存在 |
| UCRT64 | 確認目錄是否存在 |
| GDB | 確認執行檔是否存在 |
| CMake | 確認執行檔是否存在 |
| Ninja | 確認執行檔是否存在 |
| GCC / G++ | 依照專案語言檢查 |
| VS Code CLI | 確認 `code` 指令是否存在 |

如果環境檢查失敗，CBCT 會顯示錯誤訊息並停止建立專案。

# 6. Create a Project

## 6.1 Command Syntax

基本指令：

```powershell
.\cbct.ps1 -Name <ProjectName> -Language <Language>
```

參數說明：

| Parameter | Description |
|---|---|
| `-Name` | 專案名稱 |
| `-Language` | 專案語言：`C` 或 `C++` |

### Project Name Rules

專案名稱必須符合以下規則：

- 只能使用英文字母、數字及底線。
- 必須以英文字母或底線開頭。
- 不可包含空白或其他特殊字元。

例如：

```text
audio_spectrum
test_c
test_cpp
my_project_01
```

以下名稱不符合規則：

```text
123_project
my-project
my project
```

## 6.2 Create a C Project

假設目前工作目錄為：

```text
C:\Users\User\vs_code_projects
```

且 `cbct.ps1` 位於此目錄：

```text
C:\Users\User\vs_code_projects\cbct.ps1
```

直接執行：

```powershell
.\cbct.ps1 -Name audio_spectrum -Language C
```

## 6.3 Create a C++ Project

同樣在目前工作目錄執行：

```powershell
.\cbct.ps1 -Name test_cpp -Language C++
```

## 6.4 Project Generation Location

**重要：專案會建立在 PowerShell 的目前工作目錄（Current Working Directory），而不是 `cbct.ps1` 所在的目錄。**

CBCT 使用 PowerShell 的 `Get-Location` 取得目前工作目錄，並以該目錄作為專案建立位置。

例如，目前 PowerShell 位於：

```powershell
PS C:\Users\User\vs_code_projects>
```

執行：

```powershell
.\cbct.ps1 -Name test_c -Language C
```

產生的專案位置為：

```text
C:\Users\User\vs_code_projects\test_c
```

如果希望將專案建立在其他位置，可以先使用 `cd` 切換工作目錄，再執行 CBCT。

例如：

```powershell
cd C:\Users\User\Documents
```

此時建立的專案就會位於：

```text
C:\Users\User\Documents\test_c
```

如果指定的專案目錄已經存在，CBCT 會停止建立，以避免覆蓋既有資料。

# 7. Generated Project Structure

CBCT 會自動產生以下目錄與檔案：

```text
ProjectName/
│
├── CMakeLists.txt
├── README.md
├── run.ps1
├── .gitignore
│
├── src/
│   └── main.c / main.cpp
│
├── include/
│
├── build/
│
└── .vscode/
    ├── c_cpp_properties.json
    ├── settings.json
    ├── tasks.json
    └── launch.json
```

## 7.1 Directory Description

| Directory / File | Description |
|---|---|
| `src/` | 存放原始碼 |
| `include/` | 存放標頭檔 |
| `build/` | 存放建置產物 |
| `.vscode/` | VS Code 專案設定 |
| `CMakeLists.txt` | CMake 建置設定 |
| `run.ps1` | 專案建置與執行腳本 |
| `README.md` | 專案說明文件 |
| `.gitignore` | Git 忽略規則 |

第一次建置後，`build/` 會產生對應的組態目錄：

```text
build/
├── Debug/
│   └── bin/
│
└── Release/
    └── bin/
```

每個組態都有獨立的建置資料及執行檔。

# 8. Build and Run

CBCT 產生的專案包含 `run.ps1`，用來管理 Configure、Build 與 Execute 流程。

## 8.1 Command Syntax

```powershell
.\run.ps1 [-Config <Debug|Release>] [-Quiet] [-BuildOnly]
```

參數說明：

| Parameter | Description | Default |
|---|---|---|
| `-Config` | 指定建置組態 | Debug |
| `-Quiet` | 隱藏 CMake 的一般標準輸出 | Disabled |
| `-BuildOnly` | 只建置，不執行程式 | Disabled |

## 8.2 Debug Configuration

建置並執行 Debug：

```powershell
.\run.ps1
```

或明確指定：

```powershell
.\run.ps1 -Config Debug
```

只建置，不執行：

```powershell
.\run.ps1 -Config Debug -BuildOnly
```

## 8.3 Release Configuration

建置並執行 Release：

```powershell
.\run.ps1 -Config Release
```

只建置：

```powershell
.\run.ps1 -Config Release -BuildOnly
```

## 8.4 Quiet Mode

使用 `-Quiet` 可以減少 CMake Configure 和 Build 的一般標準輸出。

例如：

```powershell
.\run.ps1 -Config Debug -Quiet
```

Quiet 模式仍會顯示主要階段、計時資訊及錯誤訊息，不代表完全靜默執行。

## 8.5 Build Process

`run.ps1` 的執行流程：

1. 初始化總計時器。
2. 執行 CMake Configure。
3. 執行 CMake Build。
4. 判斷是否使用 `-BuildOnly`。
5. 確認執行檔存在。
6. 執行程式。
7. 顯示程式結束代碼。
8. 顯示總執行時間。

如果 Configure 或 Build 失敗，腳本會停止後續流程，並回傳非零結束代碼。

# 9. Visual Studio Code

CBCT 會自動建立 VS Code 所需設定。

## 9.1 Open Project

進入專案目錄：

```powershell
cd <ProjectDirectory>
```

開啟 VS Code：

```powershell
code .
```

也可以在 CBCT 生成專案時，由工具自動開啟該專案。

## 9.2 IntelliSense

CBCT 會生成：

```text
.vscode/c_cpp_properties.json
```

設定內容包含：

- Compiler Path
- IntelliSense Mode
- Include Path
- C Standard
- C++ Standard
- compile_commands.json

其中 Compiler Path 會依照專案語言選擇：

| Language | Compiler |
|---|---|
| C | gcc.exe |
| C++ | g++.exe |

`compile_commands.json` 由 CMake 自動產生，提供實際編譯參數給 IntelliSense。

第一次建置前，該檔案尚未產生，因此建議先執行一次 Debug Build。

## 9.3 VS Code Tasks

CBCT 會建立四個 Tasks：

| Task | Function |
|---|---|
| CBCT: Build | 建置 Debug |
| CBCT: Run | 建置並執行 Debug |
| CBCT: Build (Release) | 建置 Release |
| CBCT: Run (Release) | 建置並執行 Release |

使用方式：

1. 開啟 VS Code。
2. 按下 `Ctrl + Shift + P`。
3. 搜尋 `Tasks: Run Task`。
4. 選擇需要執行的 Task。

`CBCT: Build` 也是預設 Build Task，可以透過：

```text
Ctrl + Shift + B
```

執行。

## 9.4 GDB Debugging

CBCT 會自動建立：

```text
.vscode/launch.json
```

設定 GDB 除錯環境。

除錯方式：

1. 在 VS Code 開啟 C / C++ 原始碼。
2. 在程式碼左側設定 Breakpoint。
3. 按下 `F5`。
4. VS Code 會先執行 `CBCT: Build`。
5. 建置成功後啟動 GDB。
6. 開始除錯。

Debug 執行檔位於：

```text
build/Debug/bin/
```

**注意：** F5 使用的是 Debug 組態，不會自動切換到 Release。

# 10. Git Version Control

CBCT 產生的專案包含：

```text
.gitignore
```

預設忽略：

```gitignore
build/
```

因此建置產物不會被 Git 追蹤。

如果希望使用 Git 管理專案，可以在專案目錄執行：

```powershell
git init
```

加入檔案：

```powershell
git add .
```

建立第一次 Commit：

```powershell
git commit -m "Initial commit"
```

建議將 CBCT 工具本身與使用 CBCT 建立的專案分別管理。

例如，工作目錄可以採用以下結構：

```text
vs_code_projects/
│
├── cbct.ps1
│
├── test_c/
│   ├── ...
│   └── .git/
│
└── test_cpp/
    ├── ...
    └── .git/
```

每個生成的專案都可以在自己的目錄內初始化 Git Repository，彼此獨立管理。

# 11. Troubleshooting

## 11.1 MSYS2_HOME is not configured

錯誤訊息：

```text
MSYS2_HOME is not configured.
```

原因：

系統找不到 `MSYS2_HOME` 環境變數。

解決方式：

確認 Windows 環境變數設定：

```text
MSYS2_HOME=C:\msys64
```

請依照實際安裝路徑調整。

重新開啟 PowerShell 後再執行 CBCT。

## 11.2 UCRT64 directory not found

錯誤訊息：

```text
UCRT64 directory not found
```

原因：

CBCT 無法在 `MSYS2_HOME` 指定的位置找到：

```text
ucrt64\bin
```

請確認 MSYS2 是否正確安裝，以及環境變數是否指向安裝根目錄。

## 11.3 Required Tool Not Found

例如：

```text
gcc: NOT FOUND
```

原因：

必要工具尚未安裝，或 MSYS2 UCRT64 安裝不完整。

請重新開啟 MSYS2 UCRT64 終端機，確認對應套件已安裝。

## 11.4 code: NOT FOUND

原因：

PowerShell 找不到 VS Code CLI。

請確認 VS Code 已安裝，且 `code` 指令已加入 PATH。

可以透過以下指令確認：

```powershell
Get-Command code
```

## 11.5 Project Already Exists

錯誤訊息：

```text
Project 'test_c' already exists.
```

原因：

目前工作目錄下已經存在相同名稱的資料夾。

請改用其他專案名稱，或切換至不同的目標父目錄。

CBCT 不會自動覆蓋既有專案。

## 11.6 CMake Configure Failed

請確認：

- CMake 已正確安裝。
- Ninja 已正確安裝。
- GCC / G++ 可以正常執行。
- UCRT64 `bin` 目錄已加入 PATH。

可以使用以下指令檢查：

```powershell
cmake --version
ninja --version
gcc --version
g++ --version
```

## 11.7 IntelliSense Not Working

請確認：

1. 已安裝 Microsoft C/C++ Extension。
2. 已完成至少一次 Debug Build。
3. `build/Debug/compile_commands.json` 已產生。
4. `MSYS2_HOME` 設定正確。
5. `c_cpp_properties.json` 的 compilerPath 指向正確編譯器。

必要時重新載入 VS Code 視窗。

## 11.8 GDB Debugging Failed

請確認：

- GDB 已安裝。
- `MSYS2_HOME` 設定正確。
- `launch.json` 的 `miDebuggerPath` 指向正確的 GDB。
- Debug 建置已成功。
- Debug 執行檔確實存在。

# 12. Project Configuration

CBCT v1.0.0 使用以下主要設定：

| Item | Configuration |
|---|---|
| Script Language | PowerShell |
| Shell | Windows PowerShell 5.1+ |
| Toolchain | MSYS2 UCRT64 |
| C Compiler | GCC |
| C++ Compiler | G++ |
| C Standard | C17 |
| C++ Standard | C++23 |
| Build System | CMake |
| Build Generator | Ninja |
| Debugger | GDB |
| IDE | Visual Studio Code |
| IntelliSense | Microsoft C/C++ Extension |
| Build Configurations | Debug / Release |

# 13. Version History

## v1.0.0

Initial release.

- 支援 C 與 C++ 專案生成。
- 支援 C17 與 C++23。
- 整合 MSYS2 UCRT64。
- 整合 GCC / G++、GDB、CMake 與 Ninja。
- 自動生成專案目錄及設定檔。
- 支援 Debug / Release。
- 提供建置、執行與計時功能。
- 整合 VS Code Tasks。
- 整合 IntelliSense。
- 整合 GDB 除錯。
- 自動生成 README.md。
- 提供 Git 忽略規則。

---

# 14. License

CBCT is licensed under the MIT License.

See the [LICENSE](LICENSE) file for the full license text.