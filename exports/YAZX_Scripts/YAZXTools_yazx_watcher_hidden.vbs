Dim WshShell, FSO, batPath
Set FSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

batPath = "C:\YAZXTools\yazx_watcher.bat"

If FSO.FileExists(batPath) Then
  WshShell.Run "cmd.exe /c """ & batPath & """", 0, False
Else
  ' الملف مفقود — نكتب سبب الفشل بدل ما نفشل بصمت
  Dim f
  Set f = FSO.CreateTextFile("C:\YAZXTools\watcher_error.txt", True)
  f.WriteLine "لقيتني: yazx_watcher.bat مو موجود في: " & batPath
  f.WriteLine "تأكد إنك حاطه بنفس المسار بالضبط."
  f.Close
End If
