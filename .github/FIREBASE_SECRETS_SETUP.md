# Firebase Secrets Setup Guide

## Error: Permission denied for Secret Manager

Your Firebase Functions require secrets from Google Cloud Secret Manager, but the service account doesn't have access.

## Required Secrets

Your functions need these secrets:
- `MJ_API_KEY` - Mailjet API key
- `MJ_API_SECRET` - Mailjet API secret  
- `MJ_SENDER` - Mailjet sender email

## Solution: Grant Permissions to Service Account

### Step 1: Find Your Service Account Email

1. Go to Google Cloud Console: https://console.cloud.google.com
2. Select project: `reclaim-f1b3f`
3. Go to: IAM & Admin → Service Accounts
4. Find the service account used by Firebase (usually `firebase-adminsdk-xxxxx@reclaim-f1b3f.iam.gserviceaccount.com`)
5. Or check: Firebase Console → Project Settings → Service Accounts

### Step 2: Grant Secret Manager Permissions

**Option A: Via Google Cloud Console (Easiest)**

1. Go to: https://console.cloud.google.com/iam-admin/iam?project=reclaim-f1b3f
2. Find your Firebase service account
3. Click the pencil icon (Edit)
4. Click "ADD ANOTHER ROLE"
5. Add role: **Secret Manager Secret Accessor**
6. Click "SAVE"

**Option B: Via gcloud CLI**

```bash
# Replace SERVICE_ACCOUNT_EMAIL with your actual service account email
gcloud projects add-iam-policy-binding reclaim-f1b3f \
  --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
  --role="roles/secretmanager.secretAccessor"
```

### Step 3: Create Secrets (If They Don't Exist)

If the secrets don't exist yet, create them:

**Via Google Cloud Console:**

1. Go to: https://console.cloud.google.com/security/secret-manager?project=reclaim-f1b3f
2. Click "CREATE SECRET"
3. Create each secret:
   - Name: `MJ_API_KEY`, Value: (your Mailjet API key)
   - Name: `MJ_API_SECRET`, Value: (your Mailjet API secret)
   - Name: `MJ_SENDER`, Value: (your Mailjet sender email)

**Via gcloud CLI:**

```bash
# Create secrets
echo -n "your-api-key" | gcloud secrets create MJ_API_KEY \
  --project=reclaim-f1b3f \
  --data-file=-

echo -n "your-api-secret" | gcloud secrets create MJ_API_SECRET \
  --project=reclaim-f1b3f \
  --data-file=-

echo -n "your-sender@email.com" | gcloud secrets create MJ_SENDER \
  --project=reclaim-f1b3f \
  --data-file=-
```

## Alternative: Use GitHub Secrets Instead

If you prefer to manage secrets in GitHub instead of Google Cloud:

1. Add secrets to GitHub: Repository → Settings → Secrets → Actions
2. Update the workflow to pass secrets as environment variables
3. Update functions code to read from environment variables instead of Secret Manager

## Verify Setup

After granting permissions, your next deployment should succeed!

