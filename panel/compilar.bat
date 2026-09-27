@echo off
rem Compila el panel con el compilador C# que trae Windows (.NET Framework 4.x)
cd /d "%~dp0"
"%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /codepage:65001 /optimize+ /target:winexe /out:"..\Panel iPod.exe" /r:System.Windows.Forms.dll /r:System.Drawing.dll PanelIPod.cs
