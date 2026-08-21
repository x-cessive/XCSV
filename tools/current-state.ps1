<#
    current-state.ps1 - derive live freshness from recorded observations.

    registry/current-state.json is an observation log, not a live-status cache.
    This helper deliberately keeps CURRENT out of the stored schema: CURRENT is
    derived only when a consumer has a live source identity to compare against
    the recorded observed_identity.
#>

function Get-XcsvDerivedFreshness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateSet(
            'VERIFIED_AT_OBSERVATION',
            'NOT_REVERIFIED',
            'STALE_AT_OBSERVATION',
            'UNKNOWN_AT_OBSERVATION'
        )][string] $ObservationResult,

        [AllowNull()][string] $ObservedIdentity,
        [AllowNull()][string] $LiveIdentity,
        [bool] $LiveComparisonAvailable
    )

    if ($ObservationResult -eq 'NOT_REVERIFIED') {
        return 'NOT_REVERIFIED'
    }

    if (-not $LiveComparisonAvailable) {
        return 'UNKNOWN'
    }

    if ($ObservationResult -eq 'UNKNOWN_AT_OBSERVATION') {
        return 'UNKNOWN'
    }

    if ($ObservationResult -eq 'STALE_AT_OBSERVATION') {
        return 'STALE'
    }

    if ([string]::IsNullOrWhiteSpace($ObservedIdentity) -or [string]::IsNullOrWhiteSpace($LiveIdentity)) {
        return 'UNKNOWN'
    }

    if ($ObservedIdentity -eq $LiveIdentity) {
        return 'CURRENT'
    }

    return 'STALE'
}

function Get-XcsvCurrentStateReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] $State,
        [hashtable] $LiveIdentities = @{}
    )

    $rows = @()
    foreach ($prop in $State.sources.PSObject.Properties) {
        $sourceId = $prop.Name
        $source = $prop.Value
        $hasLive = $LiveIdentities.ContainsKey($sourceId)
        $live = if ($hasLive) { [string]$LiveIdentities[$sourceId] } else { $null }
        $derived = Get-XcsvDerivedFreshness `
            -ObservationResult $source.observation_result `
            -ObservedIdentity $source.observed_identity `
            -LiveIdentity $live `
            -LiveComparisonAvailable:$hasLive

        $rows += [pscustomobject]@{
            SourceId = $sourceId
            ObservationResult = $source.observation_result
            ObservedIdentity = $source.observed_identity
            LiveIdentity = $live
            LiveComparisonAvailable = $hasLive
            DerivedFreshness = $derived
            ObservedAt = $source.observed_at
        }
    }
    return $rows
}

