# Claude Code 一键安装启动脚本 (Windows PowerShell)
# 支持: Windows 10/11

param(
    [switch]$NoInstall,
    [string]$ConfigDir = "$env:USERPROFILE\.claude-dev",
    [string]$CacheDir = "$env:USERPROFILE\.cache\claude-dev",
    [switch]$Help
)

# ===== 配置 =====
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# 显示帮助
function Show-Help {
    Write-Host @"
用法: .\run.ps1 [选项]

选项:
  -Help             显示帮助
  -NoInstall        跳过 Bun 安装
  -ConfigDir <path> 自定义配置目录
  -CacheDir <path>  自定义缓存目录

示例:
  .\run.ps1                         # 默认启动
  .\run.ps1 -ConfigDir D:\claude-dev  # 自定义配置目录

"@
}

# 检测是否已安装 Bun
function Test-Bun {
    try {
        $null = Get-Command bun -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# 安装 Bun
function Install-Bun {
    Write-Info "正在安装 Bun..."
    
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Warn "建议以管理员身份运行 PowerShell 以获得最佳体验"
    }
    
    # 使用官方安装脚本
    Invoke-RestMethod -Uri "https://bun.sh/install.ps1" | Invoke-Expression
    
    # 刷新环境变量
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")
    
    Write-Info "Bun 安装完成"
}

# 验证 Bun
function Verify-Bun {
    if (-not (Test-Bun)) {
        Install-Bun
    }
    
    $bunVersion = bun --version
    Write-Info "Bun 版本: $bunVersion"
}

# 安装项目依赖
function Install-Deps {
    Write-Info "正在安装项目依赖..."
    
    if (-not (Test-Path "package.json")) {
        Write-Error "package.json 不存在，请确保在项目根目录运行"
        exit 1
    }
    
    bun install
    Write-Info "依赖安装完成"
}

# 创建配置目录
function Setup-Config {
    Write-Info "配置隔离目录: $ConfigDir"
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
}

# 启动 Claude Code
function Start-Claude {
    Write-Info "正在启动 Claude Code..."
    Write-Info "配置文件: $ConfigDir"
    Write-Info "缓存目录: $CacheDir"
    
    # 设置环境变量
    $env:CLAUDE_CONFIG_DIR = $ConfigDir
    $env:CLAUDE_CACHE_DIR = $CacheDir
    
    # 传递所有参数给主程序
    bun run src/main.tsx @args
}

# ===== 主流程 =====
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Claude Code 一键启动脚本" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Info "检测操作系统: Windows"
    
    # 步骤 1: 验证/安装 Bun
    if (-not $NoInstall) {
        Verify-Bun
    } else {
        Write-Info "跳过 Bun 安装"
    }
    
    # 步骤 2: 安装依赖
    Install-Deps
    
    # 步骤 3: 配置隔离
    Setup-Config
    
    # 步骤 4: 启动
    Start-Claude @args
}

# ===== 入口 =====
Main