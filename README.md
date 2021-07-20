# ShadowSteal
Pure Nim implementation for exploiting the SeriousSAM Local Privilege Escalation (LPE).

## Summary
Due to some oversight by Microsoft, regular users have read permissions over the contents of the System32\config\ folder in recent Windows builds. Among other things, this means that a low level user has read access to the SAM, System, and Security files in System32\config.

![1.png](img/1.png)

Ooof. So what can we do with this?

Some very observant researchers noticed that if a Windows host has been using a specific system restore configuration, "Shadow Volume Copy", then the host stores backup copies of these files that are accessible via the Win32 device namespace for these copies.

![2.png](img/2.png)

![3.png](img/3.png)

The SAM is normally locked during the host's operation, so accessing the SAM in System32\config\ is out of the question. But these shadow volume copies are fair game for any user on the host due to this misconfiguration.

ShadowStealer is a binary written in Nim to automate the enumeration and exfiltration of the SAM, System, and Security files from these shadow copies. It iterates through the possible locations of the shadow copies and, when it has found a target, it extracts the files to a zipped directory (think Bloodhound output).

![3.png](img/4.png)

It's nothing earth shattering and the code is hacky, but it works and it was a fun build!