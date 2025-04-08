Write-Output ""
Write-Output "::::: FindCreds: Windows Passwords Searcher :::::"
Write-Output "by Lof1 ;)"
Write-Output ""
Write-Output ""

# Define file types to search
$extensions = @("*.txt", "*.vba", "*.py", "*.ini", "*.cfg", "*.config", "*.xml", "*.ps1", "*.php", "*.aspx", "*.asp")

# Define common password-related keywords (Regex)
$keywords = @(
    '(?i)\<pass.+\<\/pass\>',
    '(?i)\<password.+\<\/password\>',
    '(?i)\<passwd.+\<\/passwd\>',
    '(?i)\<password\>\n\s+\<value\>.+\<\/value\>',
    "(?i)passwd\'?\s?\=\s?\'?[^\'\;\)\s\(\{\}]{5,50}",
    '(?i)passwd\"?\s?\=\s?\"?[^\"\;\)\s\(\{\}]{5,50}',
    "(?i)password\'?\s?\=\s?\'?[^\'\;\)\s\(\{\}]{5,50}",
    '(?i)password\"?\s?\=\s?\"?[^\"\;\)\s\(\{\}]{5,50}',
    "(?i)passwd\'?\s?\:\s?\'?[^\'\;\)\s\(\{\}]{5,50}",
    '(?i)passwd\"?\s?\:\s?\"?[^\"\;\)\s\(\{\}]{5,50}',
    "(?i)password\'?\s?\:\s?\'?[^\'\;\)\s\(\{\}]{5,50}",
    '(?i)password\"?\s?\:\s?\"?[^\"\;\)\s\(\{\}]{5,50}',
    '(?i)passwd\"?\>\"?[^\"\s\;\)\<\(\{\}]{5,50}',
    "(?i)passwd\'?\>\'?[^\'\s\;\)\<\(\{\}]{5,50}",
    '(?i)password\"?\>\"?[^\"\s\;\)\<\(\{\}]{5,50}',
    "(?i)password\'?\>\'?[^\'\s\;\)\<\(\{\}]{5,50}",
    '(?i)textmode\s?\=\s?\"?passw',
    "(?i)textmode\s?\=\s?\'?passw"
)

# Set the root folder to search
$searchPath = "C:\"  # Change as needed

# Define paths to exclude
$excludePaths = @(
    "C:\Windows\SystemApps\",
    "C:\Windows\System32\",
    "C:\Windows\SysWOW64\",
    "C:\Windows\WinSxS\",
    "C:\Windows\Microsoft.NET\"
)

# Output file
$outputFile = "FindCreds_Results.txt"
if (Test-Path $outputFile) { Remove-Item $outputFile }

# Get all matching files
$files = Get-ChildItem -Path $searchPath -Recurse -Force -Include $extensions -ErrorAction SilentlyContinue -File |
    Where-Object {
        $filePath = $_.FullName.ToLower()
        $isExcluded = $false
        foreach ($exclude in $excludePaths) {
            if ($filePath.StartsWith($exclude.ToLower())) {
                $isExcluded = $true
                break
            }
        }
        return -not $isExcluded
    }

# Search for password-related keywords
foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -ErrorAction Stop
        foreach ($line in $content) {
            foreach ($keyword in $keywords) {
                if ($line -match $keyword) {
                    $result = "`n[+] Possible password found in: $($file.FullName)`n    >> $line"
                    $result | Tee-Object -FilePath $outputFile -Append
                    break  # Stop checking more keywords for this line
                }
            }
        }
    } catch {
        # Skip files that can't be read
        continue
    }
}

# Define the file names to search that possibly contains passwords
$fileNames = @("plum.sqlite","unattend.xml")

# Search recursively
$results = Get-ChildItem -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue -File |
    Where-Object { $fileNames -contains $_.Name.ToLower() }

# Display and log results
foreach ($file in $results) {
    $path = $file.FullName
    Write-Host "[+] Found Interesting file: $path"
    $path | Out-File -FilePath $outputFile -Append
}

# Look for folders that contains scripts with passwords
$excludes = @("C:\Windows\WinSxS", "C:\Windows\SystemApps")

Get-ChildItem -Path $searchPath -Directory -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -ieq "scripts" -and
    ($excludes -notcontains ($_ | Resolve-Path).Path.Substring(0, $excludes[0].Length))
} |
ForEach-Object { Write-Host "Script Folder Found: " $_.FullName }

Get-ChildItem -Path $searchPath -Directory -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -ieq "script" -and
    ($excludes -notcontains ($_ | Resolve-Path).Path.Substring(0, $excludes[0].Length))
} |
ForEach-Object { Write-Host "Script Folder Found: " $_.FullName }

Write-Host "`n[+] Scan complete. Results saved to $outputFile"
