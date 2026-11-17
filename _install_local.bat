@echo off
title HomeStyle AI - Local Model Install
cd /d "%~dp0"
set "PY=%~dp0.venv\Scripts\python.exe"
set "LOG=%~dp0install_local.log"

echo [%date% %time%] START torch cu126 > "%LOG%"
"%PY%" -m pip install --disable-pip-version-check --no-input torch --index-url https://download.pytorch.org/whl/cu126 >> "%LOG%" 2>&1
echo [%date% %time%] TORCH_RC=%ERRORLEVEL% >> "%LOG%"

echo [%date% %time%] START diffusers stack >> "%LOG%"
"%PY%" -m pip install --disable-pip-version-check --no-input diffusers transformers accelerate safetensors pillow >> "%LOG%" 2>&1
echo [%date% %time%] STACK_RC=%ERRORLEVEL% >> "%LOG%"

echo [%date% %time%] VERIFY >> "%LOG%"
"%PY%" -c "import torch,diffusers,transformers;print('torch',torch.__version__,'cuda',torch.cuda.is_available());print('diffusers',diffusers.__version__)" >> "%LOG%" 2>&1
echo [%date% %time%] DONE >> "%LOG%"
