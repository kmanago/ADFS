$adfsServer = "", "", ""
#$trusts=Get-AdfsRelyingPartyTrust
$90days = ((Get-Date).Date).AddDays(90);
$filedate=(get-date).ToString('yyyy-MM-dd');
$adfsServer = ", "", ""
$check=@();

foreach($adfsServers in $adfsServer){

    $trusts = Invoke-Command -ComputerName $adfsServers -ScriptBlock{
        Get-ADFSRelyingPartyTrust | select Name, EncryptionCertificate, RequestSigningCertificate, Enabled
    }
    foreach ($trust in $trusts){ 
       if($trust.enabled -eq "True"){
            $ec = $trust.encryptioncertificate;
            $rc = $trust.RequestSigningCertificate;

            if(($ec -and ($ec.notafter.date -lt $90days)) -or ($rc -and ($rc.notafter.Date -lt $90days))){
               $hash = [ordered] @{
                    Name = $trust.Name
                    EncryptCertExp = $ec.notafter;
                    RequestSigningCertExp = $rc.notafter;
                    #ADFSCertExp = '';   
                }
                $obj = New-Object psobject -Property $hash;
                $check +=$obj;
            }#if statement    
       }
    }#foreach trust
}#foreach adfsserver

<#foreach($adfsServers in $adfsServer){
$adfscerts= Invoke-Command -ComputerName $adfsServers -ScriptBlock{(Get-AdfsCertificate).certificatetype}

     foreach($adfscert in $adfscerts){
        $certexp=Invoke-Command -ComputerName $adfsServers -ScriptBlock{(Get-AdfsCertificate -CertificateType $adfscert).certificate.notafter}
        Write-Host $adfscert
        Write-Host $certexp
        if($certexp -and ($certexp.notafter -lt $90days)){
           $hash = [ordered] @{
                Name = $adfscert
                 EncryptCertExp = '';
                RequestSigningCertExp = '';
                ADFSCertExp = $certexp;     
            }
            $obj = New-Object psobject -Property $hash;
            $check +=$obj;
        }
     }#endofforeach
}
#>

$Header = @"
<style>
TABLE {table-layout: fixed; width: 600px;border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {width:25%;border-width: 1px; padding: 8px;border-style: solid; border-color: black;}
</style>
"@

$filename = ""+$filedate+".html"; #path
$check | ConvertTo-Html -Property Name,EncryptCertExp,RequestSigningCertExp -Head $Header | Out-File $filename;
$certBody= Get-Content $filename -Raw


#creates and sends out the email about certs
$subject="ADFS Relying Party Certificates Expiring" + $ts; #mail subject
$server = ""; #mail server
$mailTo = ""; #receiver
$mailFrom = ""; #sender

if($check){
    $body = "The following application(s) that communicate with ADFS have certificates that have already expired and/or expiring the next upcoming 90 days. 
    Contact the application owners to receive new metadata and/or the new certs to apply.
    ";
    Start-Sleep -Seconds 1
    Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -SmtpServer $server -Body $body$certBody -BodyAsHtml; #command to send email
} #if $notFound is an empty file, send this email with no attachment
