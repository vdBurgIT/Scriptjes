Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails SharedMailbox,UserMailbox | ForEach-Object {
    Set-Mailbox -Identity $_.PrimarySmtpAddress -MessageCopyForSentAsEnabled $true -MessageCopyForSendOnBehalfEnabled $true
}
