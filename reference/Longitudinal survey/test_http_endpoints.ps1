#!/usr/bin/env powershell
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "="*70
Write-Host "TESTING FLASK ENDPOINTS VIA HTTP"
Write-Host "="*70

# Test 1: Get sections
Write-Host "`n[TEST 1] GET /api/sections"
Write-Host "-"*70
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/sections" -UseBasicParsing
    $sections = $response.Content | ConvertFrom-Json
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Sections found: $($sections.Count)"
    if ($sections.Count -gt 0) {
        $section_id = $sections[0].section_id
        Write-Host "First section: $($sections[0] | ConvertTo-Json)"
    }
} catch {
    Write-Host "✗ Error: $_"
    exit 1
}

# Test 2: Get questions tree
Write-Host "`n[TEST 2] GET /api/questions/tree/$section_id"
Write-Host "-"*70
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/questions/tree/$section_id" -UseBasicParsing
    $tree = $response.Content | ConvertFrom-Json
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Root questions found: $($tree.Count)"
} catch {
    Write-Host "✗ Error: $_"
}

# Test 3: Add a question
Write-Host "`n[TEST 3] POST /api/questions - Add MCQ"
Write-Host "-"*70
try {
    $payload = @{
        section_id = $section_id
        question_text = "HTTP Test - Which color?"
        question_type = "mcq"
        options = @("Red", "Blue", "Green")
        parent_id = $null
        trigger_value = $null
    } | ConvertTo-Json
    
    Write-Host "Payload: $payload"
    
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/questions" `
        -Method POST `
        -ContentType "application/json" `
        -Body $payload `
        -UseBasicParsing
    
    $result = $response.Content | ConvertFrom-Json
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($result | ConvertTo-Json)"
    
    if ($result.success) {
        Write-Host "✓ Question added with ID: $($result.question_id)"
    } else {
        Write-Host "✗ Error: $($result.error)"
    }
} catch {
    Write-Host "✗ Error: $_"
}

Write-Host "`n" + "="*70
Write-Host "TESTS COMPLETE"
Write-Host "="*70
