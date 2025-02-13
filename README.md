## Requirements
* Windows 10
> Insider Preview editions of Windows are not supported
* 60 GB Hard Drive
* 2 GB RAM

## Recommended
* Windows 10 22H2
* 80+ GB Hard Drive
* 4+ GB RAM
* 2 network adapters
  
In Windows versions 1909 and higher, Tamper Protection was added.
**Tamper Protection must be disabled first, otherwise Group Policy settings are ignored.**

1. Open Windows Security (type `Windows Security` in the search box)
1. Virus & threat protection > Virus & threat protection settings > Manage settings
1. Switch `Tamper Protection` to `Off` 
> It is not necessary to change any other setting (`Real Time Protection`, etc.)

> **Important!** Tamper Protection must be disabled before changing Group Policy settings.

To permanently disable Real Time Protection:

1. Make sure you disabled Tamper Protection
1. Open Local Group Policy Editor (type `gpedit` in the search box)
1. Computer Configuration > Administrative Templates > Windows Components > Microsoft Defender Antivirus > Real-time Protection
1. Enable `Turn off real-time protection`
1. **Reboot**
> Make sure to **reboot** before making the next change

To permanently disable Microsoft Defender:

1. Make sure you rebooted your machine
1. Open Local Group Policy Editor (type `gpedit` in the search box)
1. Computer Configuration > Administrative Templates > Windows Components > Microsoft Defender Antivirus
1. Enable `Turn off Microsoft Defender Antivirus`
1. **Reboot**

  [1]: https://stackoverflow.com/questions/62174426/how-to-permanently-disable-windows-defender-real-time-protection-with-gpo

## Installation 
1. Complete the pre-install procedures by disabling Defender
1. Download and extract the zip of the Commando-VM repo
1. Run PowerShell as Administrator
1. `Set-ExecutionPolicy Unrestricted -force`
1. `cd ~/Downloads/commando-vm`
1. `Get-ChildItem .\ -Recurse | Unblock-File`
1. `.\install.ps1` for a GUI install or `.\install.ps1 -cli` for command-line

## Troubleshooting
See the ![troubleshooting documentation](https://github.com/mandiant/commando-vm/blob/main/Docs/Troubleshooting.md) for more information.

## Credits

- Jake Barteaux         @day1player
- Blaine Stancill       @MalwareMechanic
- Nhan Huynh            @htnhan
- Drew Farber           @0xFarbs
- Alex Tselevich        @nos3curity
- George Litvinov       @geo-lit
- Dennis Tran           @Menn1s
- Joseph Clay           @skollr34p3r
- Ana Martinez Gomez    @anamma_06
- Moritz Raabe
- Derrick Tran          @dumosuku
- Mandiant Red Team
- Mandiant FLARE

## By Comando VM all credits OG post https://github.com/mandiant/commando-vm
