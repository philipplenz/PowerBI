$myPassword = '<myPassword>'
$myUsername = '<myUsername>'

$password = ConvertTo-SecureString $myPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($myUsername, $password)

Login-PowerBIServiceAccount -Credential $credential

$Workspaces = Get-PowerBIWorkspace

$date = Get-Date -Format "ddMMyyyy"

$HistoryFile = 'C:\Users\phili\OneDrive\Blog\Refresh\history' + $date  + '.csv'
$RefreshFile = 'C:\Users\phili\OneDrive\Blog\Refresh\Refresh' + $date + '.csv'

foreach($workspace in $Workspaces)
{
    $DataSets = Get-PowerBIDataset -WorkspaceId $workspace.Id | where {$_.isRefreshable -eq $true}    
    foreach($dataset in $DataSets)
    {
        $RefreshURI = "groups/" + $workspace.Id + "/datasets/" + $dataset.id + "/refreshes"
        $ScheduleURI = "groups/" + $workspace.Id + "/datasets/" + $dataset.id + "/refreshSchedule"
       
        $Results = Invoke-PowerBIRestMethod -Url $RefreshURI -Method Get | ConvertFrom-Json

        #
        $RefreshURISchedule = "groups/" + $workspace.Id + "/datasets/" + $dataset.id + "/refreshSchedule"      
        $ResultsSchedule = Invoke-PowerBIRestMethod -Url $RefreshURISchedule -Method Get | ConvertFrom-Json

        # Only enabled datasets fro refreshing
        if($ResultsSchedule.enabled -eq $true) {

            foreach($content in $Results.value) {           
                $row = New-Object psobject
                $row | Add-Member -Name "Workspace" -Value $workspace.Name -MemberType NoteProperty 
                $row | Add-Member -Name "WorkspaceId" -Value $workspace.Id -MemberType NoteProperty    
                $row | Add-Member -Name "Dataset" -Value $Dataset.Name -MemberType NoteProperty   
                $row | Add-Member -Name "DatasetId" -Value $Dataset.Id -MemberType NoteProperty  
                $row | Add-Member -Name "refreshType" -Value $content.refreshType -MemberType NoteProperty 
                $row | Add-Member -Name "Status" -Value $content.status -MemberType NoteProperty
                $row | Add-Member -Name "StartTime" -Value $content.startTime -MemberType NoteProperty  
                $row | Add-Member -Name "EndTime" -Value $content.endTime -MemberType NoteProperty           
                $row | Export-Csv -Path $HistoryFile -Append -Delimiter ';' -NoTypeInformation  
            }
        }

        $refreshScheduleURI = "groups/" + $workspace.Id + "/datasets/" + $dataset.id + "/refreshSchedule"
       
        $Results = Invoke-PowerBIRestMethod -Url $refreshScheduleURI -Method Get | ConvertFrom-Json
        # Only enabled datasets fro refreshing
        if($Results.enabled -eq $true) {
            $days = $Results.days -join ','
            $time = $Results.times -join ','
            $row = New-Object psobject
            $row = New-Object psobject
            $row | Add-Member -Name "Workspace" -Value $workspace.Name -MemberType NoteProperty 
            $row | Add-Member -Name "WorkspaceId" -Value $workspace.Id -MemberType NoteProperty    
            $row | Add-Member -Name "Dataset" -Value $Dataset.Name -MemberType NoteProperty   
            $row | Add-Member -Name "DatasetId" -Value $Dataset.Id -MemberType NoteProperty    
            $row | Add-Member -Name "Days" -Value $days -MemberType NoteProperty 
            $row | Add-Member -Name "Time" -Value $time -MemberType NoteProperty         
            $row | Export-Csv -Path $RefreshFile -Append -Delimiter ';' -NoTypeInformation  
        }
    }
}