# Script to remove API keys from Git history
# WARNING: This rewrites Git history. Make sure you have a backup!

Write-Host "Starting Git history cleanup to remove API keys..." -ForegroundColor Yellow
Write-Host "WARNING: This will rewrite your Git history!" -ForegroundColor Red
Write-Host ""

# The API keys to remove
$apiKey1 = "AIzaSyBJBVtw6tQ0rliQm2ayeWifCr5-RxQ5Jvw"
$apiKey2 = "AIzaSyDpBFwuBCEhE3HzVq-59B5Pi36adQ2kNVg"

# Check if git-filter-repo is available (preferred method)
$hasFilterRepo = git filter-repo --version 2>$null
if ($hasFilterRepo) {
    Write-Host "Using git-filter-repo (recommended)..." -ForegroundColor Green
    
    # Remove API keys from firebase_options.dart
    git filter-repo --path lib/firebase_options.dart --invert-paths --force
    git filter-repo --path-filter 'sed "s/$apiKey1/REMOVED_API_KEY_1/g; s/$apiKey2/REMOVED_API_KEY_2/g"' --force
    
    # Remove google-services.json from history
    git filter-repo --path android/app/google-services.json --invert-paths --force
} else {
    Write-Host "Using git filter-branch (fallback)..." -ForegroundColor Yellow
    
    # Remove API keys from all commits
    git filter-branch --force --index-filter `
        "git rm --cached --ignore-unmatch android/app/google-services.json" `
        --prune-empty --tag-name-filter cat -- --all
    
    # Replace API keys in firebase_options.dart with placeholders
    git filter-branch --force --tree-filter `
        "if [ -f lib/firebase_options.dart ]; then
            sed -i 's/$apiKey1/REMOVED_API_KEY_1/g' lib/firebase_options.dart
            sed -i 's/$apiKey2/REMOVED_API_KEY_2/g' lib/firebase_options.dart
        fi" `
        --prune-empty --tag-name-filter cat -- --all
}

Write-Host ""
Write-Host "Git history cleanup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify the changes: git log --all"
Write-Host "2. Force push to remote: git push --force --all"
Write-Host "3. Force push tags: git push --force --tags"
Write-Host "4. Rotate your API keys in Google Cloud Console"
Write-Host ""
Write-Host "IMPORTANT: Notify all collaborators to re-clone the repository!" -ForegroundColor Red

