function Find-Subscription {
    [CmdletBinding()]
    param (
        [string] $ManagementGroupId,
        [string] $Usage,
        [string] $SubscriptionPoolManagementGroupId
    )
    
    Write-Information "Lookup existing subscription for usage $usage in management group $ManagementGroupId"

    [Array]$possibleSubscriptions = Get-AzManagementGroupEntity | Where-Object { $_.ParentNameChain -contains $ManagementGroupId -and $_.Type -eq "/subscriptions" }

    $found = $false

    foreach ($subscription in $possibleSubscriptions) {
        // TODO: to implement
    }

    if ($found) {
        Write-Information "Found subscription $subscription"
        return $subscription
    }
    else {
        Write-Information "No subscription found"
        $subscription = New-Subscription -ManagementGroupId $ManagementGroupId -Usage $Usage -SubscriptionPoolManagementGroupId $SubscriptionPoolManagementGroupId -environment "prd"
        return $null
    }
}

function New-Subscription {
    [CmdletBinding()]
    param (
        [string] $ManagementGroupId,
        [string] $Usage,
        [string] $SubscriptionPoolManagementGroupId,
        [ValidateSet("prd", "dev")]
        [string] $environment
    )

    Write-Information "Create subscription for usage $usage in management group $ManagementGroupId"

    [Array]$subscriptionInPool = Get-AzManagementGroupEntity | Where-Object { $_.ParentNameChain -contains $SubscriptionPoolManagementGroupId -and $_.Type -eq "/subscriptions" }

    $found = $false
    $subscriptionId = $null

    $tags = @{ "Lock" = "True"; "Usage" = $Usage; "Environment" = $environment }

    foreach ($subscription in $subscriptionInPool) {
        $currentTags = Get-AzTag -ResourceId $subscription.Id
        if ($null -eq $currentTags.Lock -or ("True" -eq $currentTags.Lock -and $Usage -eq $currentTags.Usage)) {
            $found = $true
            $subscriptionId = $subscription.name
            break;
        }
    }

    if ($false -eq $found) {
        Write-Error "No available subscription found in management group $SubscriptionPoolManagementGroupId"
    }
    else {
        Write-Information "Add tags to subsciption $subscriptionId"
        Update-AzTag -ResourceId "/subscriptions/$subscriptionId" -Tag $tags -Operation Merge | Out-Null

        
        $Subscription = Get-AzSubscription -SubscriptionId $subscriptionId

        $subscriptionName = "az-securecloud-$($usage.ToLower())-$environment"
        
        Write-Information "Rename subscription $subscriptionId to $subscriptionName"
        Rename-AzSubscription -Id $subscriptionId -SubscriptionName $subscriptionName | Out-Null

        Write-Information "Move subscription $subscriptionId to management group $ManagementGroupId"
        New-AzManagementGroupSubscription -GroupName $ManagementGroupId -SubscriptionId $subscriptionId  
    }
}