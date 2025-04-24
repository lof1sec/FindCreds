Write-Output ""
Write-Output "::::: FindCreds: Windows Password Searcher :::::"
Write-Output "by Lof1 ;)"
Write-Output ""
Write-Output ""

# Define file types to search
$extensions = @("*.txt", "*.vba", "*.py", "*.ini", "*.cfg", "*.config", "*.xml", "*.ps1", "*.php", "*.aspx", "*.asp")

# Define common password-related keywords (Regex)
$keywords = @(
    '(?i)\<pass.+\<\/pass\>',
    '(?i)\<passwo?r?d.+\<\/passwo?r?d\>',
    '(?i)\<passwo?r?d\>\n\s+\<value\>.+\<\/value\>',
    "(?i)passwo?r?d\'?\s?\=\s?\'?[^\'\;\)\s\(\{\}]{6,50}",
    '(?i)passwo?r?d\"?\s?\=\s?\"?[^\"\;\)\s\(\{\}]{6,50}',
    "(?i)passwo?r?d\'?\s?\:\s?\'?[^\'\;\)\s\(\{\}]{6,50}",
    '(?i)passwo?r?d\"?\s?\:\s?\"?[^\"\;\)\s\(\{\}]{6,50}',
    '(?i)passwo?r?d\"?\>\"?[^\"\s\;\)\<\(\{\}]{6,50}',
    "(?i)passwo?r?d\'?\>\'?[^\'\s\;\)\<\(\{\}]{6,50}",
    '(?i)textmode\s?\=\s?\"?passwo?r?d',
    "(?i)textmode\s?\=\s?\'?passwo?r?d",
    "(?i)\<add.+passwo?r?d.+value.+\/\>",
    "(?i)\<.{3,30}passwo?r?d.{1,30}value.+\/\w+\>"
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
        $lineNumber = 0
        foreach ($line in $content) {
            $lineNumber++
            foreach ($keyword in $keywords) {
                $matches = [regex]::Matches($line, $keyword)
                if ($matches.Count -gt 0) {
                    foreach ($match in $matches) {
                        $result = "`n[+] Possible password found in: $($file.FullName)`n    Line $lineNumber >> $($match.Value)"
                        $result | Tee-Object -FilePath $outputFile -Append
                    }
                    break  # Stop checking other keywords for this line (optional)
                }
            }
        }
    } catch {
        # Skip files that can't be read
        continue
    }
}
Write-Output ""
# Define the file names to search that possibly contain passwords
$fileNames = @("plum.sqlite","unattend.xml")

# Search recursively for those files
$results = Get-ChildItem -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue -File |
    Where-Object { $fileNames -contains $_.Name.ToLower() }

# Display and log results
foreach ($file in $results) {
    $path = $file.FullName
    Write-Host "[+] Found Interesting file: $path"
    $path | Out-File -FilePath $outputFile -Append
}

# Look for folders that contain "scripts" or "script"
$excludes = @("C:\Windows\WinSxS", "C:\Windows\SystemApps")
Write-Output ""
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
