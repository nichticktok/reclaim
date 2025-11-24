# GitHub Actions Troubleshooting Guide

## Build Failures - Common Issues

### 1. SONAR_TOKEN Secret Location

**Problem:** SONAR_TOKEN is in the wrong location (Environments instead of Actions secrets)

**Solution:**
1. Go to: Repository → Settings → **Secrets and variables** → **Actions** (NOT Environments)
2. Click "New repository secret"
3. Name: `SONAR_TOKEN`
4. Value: Get from https://sonarcloud.io → My Account → Security → Generate Token
5. Click "Add secret"

**Note:** Secrets in "Environments" are only available when using environment-specific jobs. For regular jobs, use "Actions" secrets.

### 2. SonarQube Failing

**Current Fix:** SonarQube job now has `continue-on-error: true`, so it won't block builds.

**If you want SonarQube to work:**
- Ensure SONAR_TOKEN is in Actions secrets (see #1)
- Verify project key matches: `nichticktok_reclaim`
- Check organization name: `nichticktok`
- Ensure `sonar-project.properties` exists in root

### 3. Flutter Build Failures

**Common causes:**
- Missing dependencies: Run `flutter pub get` locally first
- Version conflicts: Check `pubspec.yaml` for compatible versions
- Missing files: Ensure all required files are committed

### 4. Firebase Deployment Failures

**Check:**
- `FIREBASE_SERVICE_ACCOUNT_RECLAIM` secret exists
- All mailer secrets are configured (MAILER_HOST, MAILER_PORT, etc.)
- Firebase project ID is correct: `reclaim-f1b3f`

### 5. Multiple Workflows Conflict

**Current workflows:**
- `build.yml` - SonarQube only (runs on main/master and PRs)
- `firebase-hosting-merge.yml` - SonarQube + Firebase deploy (runs on main pushes and PRs)
- `firebase-hosting-pull-request.yml` - PR previews only

**Recommendation:** You can disable `build.yml` if you're using `firebase-hosting-merge.yml` since it includes SonarQube.

## Quick Fix Checklist

- [ ] SONAR_TOKEN is in **Actions** secrets (not Environments)
- [ ] All Firebase secrets are configured
- [ ] `sonar-project.properties` exists in root
- [ ] Flutter dependencies are up to date
- [ ] No conflicting workflows

## Viewing Build Logs

1. Go to: Repository → Actions tab
2. Click on the failed workflow run
3. Click on the failed job
4. Expand the failed step to see error details

