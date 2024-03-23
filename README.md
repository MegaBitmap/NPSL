# Neutrino PowerShell Launcher

Neutrino PowerShell Launcher (NPSL) is a GUI for [Rick Gaiser's neutrino](https://github.com/rickgaiser/neutrino).  
Tested working on windows 10 and 11.  


## What does it do?

This is an installer and launcher for running [Rick Gaiser's neutrino](https://github.com/rickgaiser/neutrino) on a PlayStation 2 connected to a windows PC via Ethernet.  
Neutrino is a third-party application that functions as an optical disk emulator.  
This allows games to be played from a ISO file without any physical disk.  
The ISO files are stored on an exFAT storage volume or partition connected to the PC.  
The ps2 connects to the PC with the udpbd-server program.  
The udpbd-server streams the game data live while the game is running on the ps2.  
The benefit of this method is that the ps2 is capable of higher data throughput when using its Ethernet interface.  
Loading games via Ethernet is faster than using a disk or USB drive.  

Neutrino is a command line only application with no GUI.  
NPSL is a powershell script that functions as a GUI for neutrino.  
The NPSL `Setup.ps1` script will create a desktop shortcut for every ps2 ISO found in a selected exFAT volume.  

It is recommended to configure the ps2 to automatically launch [ps2link](https://github.com/ps2dev/ps2link) as that program is needed for the ps2 to receive data and commands from the PC.  
PS2Link is a 'bootloader' which, used together with an Ethernet driver and a TCP/IP stack, enables you to download and execute software on the PS2.  

## How do I use it?

### Network Configuration:

- When connecting a ps2 to a PC there are two network configurations.
1. There is a direct connection where a single Ethernet cable connects the ps2 and PC.  
On the PC, go into network connections or run `ncpa.cpl`.  
Right click the Ethernet adapter and select properties, then select IPv4 properties.  
Set the IP address to `192.168.0.47` and subnet mask to `255.255.0.0` everything else can be left blank.  
The ps2link IP address settings in `IPCONFIG.DAT` can be left at default values.  
The default `IPCONFIG.DAT` will set the ps2 IP address to `192.168.0.10`.  

2. The second configuration is where the ps2 and PC are connected to a router or Ethernet switch.  
The ps2 IP address settings for ps2link, `IPCONFIG.DAT`, need to be changed with a text editor.  
For the first IP address, the first three parts must match the default gateway of the router or switch.  
To find the default gateway, run this command:  

    ```
    cmd /k ipconfig
    ```

    Most likely it will be `192.168.0.?` or `192.168.1.?`  
The last part of the IP address, `?`, must be between `2` and `253`, and can not be the same as any other device on the network.  
Example: `192.168.1.62` or `192.168.0.27`  
I recommend to use the `ping` command to check for an unused IP address.  
If it says `Destination host unreachable.`, an unused IP address has successfully been found.  

    ```
    cmd /k ping 192.168.1.62
    ```

    The second IP address or subnet mask, is set to `255.255.0.0`  
The third IP address or default gateway, must match the default gateway of the router or switch.  
Most likely it will be `192.168.0.1` or `192.168.1.1`  
Make sure to save changes then replace the `IPCONFIG.DAT` in `mc0:/APPS/`  

### PS2 Setup:

1. Download the stable release of [ps2link](https://github.com/ps2dev/ps2link/releases/latest), extract and copy the files onto a MBR FAT32 flash drive.  

2. Edit `IPCONFIG.DAT` if needed. See network configuration above.

3. Plug the drive into the PS2 and use launchELF to copy the ps2link files from `mass:/` to `mc0:/APPS`

4. Power Off and unplug the flash drive.

5. If using FMCB open the configurator and in E1 launch keys change Auto to the `PS2LINK.ELF` file.  
- If using PS2BBL use the launchELF text editor to open `mc0:/PS2BBL/CONFIG.INI`.  
In the line with `LK_AUTO_E1 = mass:/APPS/OPNPS2LD.ELF`,  
change it to `LK_AUTO_E1 = mc?:/APPS/PS2LINK.ELF`  
Make sure to save before exiting.  

6. Now FMCB or PS2BBL should automatically launch ps2link.


### PC Setup:

1. Open Disk Management and select a drive to store PS2 game ISOs.  

2. Shrink or delete a partition so that there is enough unallocated space to store games.  
WARNING Please back up any important files before deleting a partition.  

3. Use Rufus to flash a Gparted live ISO onto a flash drive.  

4. Restart the PC and enter the BIOS.  
In boot options, select the flash drive with Gparted live and boot from it.  

5. Select the default options with the enter key to start Gparted.  

6. Select the unallocated space in the drive of choice and create a new exFAT partition.  
It is recommended to label it as PS2.  

7. Apply the changes, then restart back into windows.  

8. Navigate to `This PC` and an empty drive labeled PS2 should show up.  
Please note the drive letter for step 13.  

9. In the drive create a folder named `DVD` and copy all game ISOs into it.  
For games in a CUE+BIN format, create a folder named `CD` and copy the files into it.  

10. See network configuration above and verify your IP address settings.  

11. Turn on the ps2, run ps2link and wait for it to display `Ready`.  

12. Run the Setup script using this command:  
It will automatically download neutrino, ps2client, and udpbd-server.  

    ```
    powershell "irm https://raw.githubusercontent.com/MegaBitmap/NPSL/master/Setup.ps1 | iex"
    ```

    For offline installations, download this repository as a ZIP file.  
Extract the ZIP to a folder and then run `OfflineSetup.ps1` with PowerShell.  

13. A dialog box should show up, read and accept the license terms, then configure the settings.  
The most important setting is the ps2 IP address.  
After clicking on install, the setup program will install neutrino, ps2client, and udpbd-server.  
A shortcut for each game ISO will be created on the desktop.  

14. To play a game first turn on the PS2, run ps2link, then wait for it to display `Ready`.  
Double click the game shortcut on the desktop.  
udpbd-server should stay running when switching games.  
It is recommend to power off the PS2 before closing udpbd-server when finished playing.  


### Manually Edit a Shortcut:

- NPSL creates shortcuts with arguments that can contain more than 231 characters.  
The shortcut properties built into windows will display at max 231 characters.  
If you want to manually edit a shortcut without the character limit,  
use the `EditShortcut.ps1` script in this repository:  

    ```
    powershell "irm https://raw.githubusercontent.com/MegaBitmap/NPSL/master/EditShortcut.ps1 | iex"
    ```


## Credits:
NPSL uses third party programs for added functionality:

**Please read LICENSE-3RD-PARTY.txt for licensing information.**

- neutrino:  
Version: neutrino_v1.3.1  
<https://github.com/rickgaiser/neutrino>  

- udpbd-server:  
Version: Mar 8, 2023  
<https://github.com/israpps/udpbd-server>  

- ps2client:  
Version: ps2client-211df54b-windows-latest  
<https://github.com/ps2dev/ps2client>  

- ps2link:  
<https://github.com/ps2dev/ps2link>  

- ImageMagick:  
Version: ImageMagick-7.1.1-27-portable-Q16-x64  
<https://github.com/ImageMagick/ImageMagick>  

- bchunk:  
Version: bchunk-v1.2.3-WIN  
<https://github.com/MegaBitmap/bchunk>  

- ps2-covers:  
<https://github.com/xlenore/ps2-covers>  
