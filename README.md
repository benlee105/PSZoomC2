## What is this?
A C2 listener that's in PowerShell, Bash and C# (for compiling into EXE).

The C2 listener is controlled through commands sent via Zoom Workplace chat.

## Where's the code?
**See [Releases](https://github.com/benlee105/PSZoomC2/releases)**  

## What are the pre-requisites required?
1) A Zoom account,
2) Create a Zoom app on Zoom's website (its super easy!),
3) [Zoom Workplace](https://zoom.us/download) installed on a device to send commands to the listener.  
    
## How do I setup everything?
See the Wiki link below for step by step instructions on setup.  
  
**[Workflow Wiki](https://github.com/benlee105/PSZoomC2/wiki/Workflow)**

## How do I use the C2?
Commands are sent to C2 listener via Zoom Workplace app using the syntax:  
  
`command: <shell command>`  

See [**Usage Wiki**](https://github.com/benlee105/PSZoomC2/wiki/Usage) for step by step instructions on usage.

## I need shellcode instead of PowerShell, Bash or C# EXE?
Download the C# version, compile into EXE, then use https://github.com/TheWover/donut to convert to shellcode.

## I need a shellcode loader?
TBD
