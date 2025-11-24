# SonarCloud Setup Guide

## Error: "Project not found"

This error means the project `nichticktok_reclaim` doesn't exist in SonarCloud yet.

## Solution: Create the Project in SonarCloud

### Option 1: Automatic Creation (Recommended)

The workflow will automatically create the project on first run if:
1. Your SONAR_TOKEN has permission to create projects
2. The organization `nichticktok` exists and you have access

### Option 2: Manual Creation

1. Go to https://sonarcloud.io
2. Log in with your GitHub account
3. Click on your organization: `nichticktok`
4. Click "Create Project" or "Add Project"
5. Select "Manually" or "From GitHub"
6. If selecting from GitHub:
   - Choose your repository: `reclaim`
   - SonarCloud will auto-generate the project key
7. If creating manually:
   - Project Key: `nichticktok_reclaim`
   - Project Name: `reclaim`
   - Organization: `nichticktok`

### Option 3: Import from GitHub (Easiest)

1. Go to https://sonarcloud.io
2. Click "Analyze a project" → "From GitHub"
3. Select your organization: `nichticktok`
4. Select your repository: `reclaim`
5. SonarCloud will automatically:
   - Create the project
   - Set up the project key
   - Configure the analysis

## Verify Your Setup

After creating the project, verify:
- ✅ Project key matches: `nichticktok_reclaim`
- ✅ Organization matches: `nichticktok`
- ✅ SONAR_TOKEN has access to the project
- ✅ Token is in **Actions** secrets (not Environments)

## Check Token Permissions

1. Go to https://sonarcloud.io → My Account → Security
2. Find your token
3. Ensure it has "Execute Analysis" permission
4. If needed, regenerate the token with proper permissions

## After Setup

Once the project is created, your next workflow run should succeed!

