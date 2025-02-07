$MyWallpaper="c:\temp\sw\wallpaper.jpg"
$code = @' 
using System.Runtime.InteropServices; 
namespace Win32{ 
    
     public class Wallpaper{ 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
         static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ; 
         
         public static void SetWallpaper(string thePath){ 
            SystemParametersInfo(20,0,thePath,3); 
         }
    }
 } 
'@

add-type $code 
[Win32.Wallpaper]::SetWallpaper($MyWallpaper)

xcopy c:\temp\sw\wallpaper.jpg c:\windows

reg add "HKCU\control panel\desktop" /v wallpaper /t REG_SZ /d "C:\windows\wallpaper.jpg" /f 
reg delete "HKCU\Software\Microsoft\Internet Explorer\Desktop\General" /v WallpaperStyle /f
reg add "HKCU\control panel\desktop" /v WallpaperStyle /t REG_SZ /d 2 /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters 

forfiles /P C:\temp /c "cmd /c del @path /q & rd @path /s /q"
forfiles /P C:\users\defaultuser0 /c "cmd /c del @path /q & rd @path /s /q"
shutdown /r /f /t 10