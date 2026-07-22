# How to use EntraAppExpiry

Step-by-step guide covering both ways to use this module:

- **Interactive** — run it yourself, ad hoc, sign in with your own account
- **Unattended** — run it as a scheduled task on a server with no one logged in

---

## 1. Prerequisites

- Windows PowerShell 5.1+ or PowerShell 7+
- Permission to install PowerShell modules (`Install-Module` for the current user is enough for interactive use)
- An Entra ID (Azure AD) account or app registration with the **`Application.Read.All`** Graph permission
  - Interactive use: a delegated permission grant is enough (your own account, consented once)
  - Unattended use: an **application** permission, admin-consented (see Part 3)

## 2. Get the code

```powershell
git clone https://github.com/KeithDoolan-Git/EntraAppExpiry.git
cd EntraAppExpiry
```

(Once the module is published to the PowerShell Gallery, `Install-Module EntraAppExpiry` will work too — see the README for status.)

## 3. Install the Graph dependencies

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Applications -Scope CurrentUser
```

(If you install the module itself via `Install-Module EntraAppExpiry` later, these are pulled in automatically as declared dependencies.)

---

## Part 1 — Interactive use (run it yourself)

1. Import the module:

   ```powershell
   Import-Module .\EntraAppExpiry\EntraAppExpiry.psd1
   ```

2. Sign in:

   ```powershell
   Connect-AppExpiry
   ```

   This opens an interactive Microsoft sign-in prompt and requests `Application.Read.All`. The first time, an admin in your tenant may need to consent to that permission.

3. Check what's expiring:

   ```powershell
   Get-AppExpiry -ExpiringInDays 30
   ```

   This lists every client secret and certificate on any app registration in your tenant expiring in the next 30 days, with `DaysUntilExpiry` for each.

4. Export a report if you want a file to share:

   ```powershell
   Get-AppExpiry -ExpiringInDays 30 | Export-AppExpiryReport -Path .\expiry-report.html -Format Html
   ```

That's the whole interactive flow.

---

## Part 2 — Unattended use (scheduled, no one logged in)

This is for running the check automatically on a server (e.g. daily) via Windows Task Scheduler. Interactive sign-in won't work unattended, so this uses **app-only authentication with a certificate** instead of a password/secret (a cert is the recommended pattern — no secret to itself expire and leak).

### Part 3 — One-time setup: create the app registration

Do this once, in the Entra admin center (or Azure Portal → Microsoft Entra ID).

1. **App registrations → New registration.** Name it something like `EntraAppExpiry Reporter`. Single tenant is fine. Register it.
2. Note the **Application (client) ID** and **Directory (tenant) ID** shown on the app's Overview page — you'll need both.
3. **API permissions → Add a permission → Microsoft Graph → Application permissions** → search for and add `Application.Read.All`.
4. Click **Grant admin consent** for your tenant (requires admin rights). Unattended app-only permissions must be consented — there's no interactive prompt to fall back on.
5. On the **server** that will run the scheduled task, open an elevated PowerShell and create a self-signed certificate directly in the machine's certificate store (so the SYSTEM account running the task can read it):

   ```powershell
   $cert = New-SelfSignedCertificate `
       -Subject "CN=EntraAppExpiry" `
       -CertStoreLocation "Cert:\LocalMachine\My" `
       -KeyExportPolicy Exportable `
       -KeySpec Signature `
       -KeyLength 2048 `
       -NotAfter (Get-Date).AddYears(2)

   Export-Certificate -Cert $cert -FilePath "C:\EntraAppExpiry\EntraAppExpiry.cer"
   $cert.Thumbprint
   ```

   Note the thumbprint it prints — you'll need it below. The `.cer` file is the **public** key only; it's safe to move around (e.g. copy it off the server to upload in the next step).

6. Back in the app registration: **Certificates & secrets → Certificates → Upload certificate**, and upload the `.cer` file from step 5.

   > This certificate has its own 2-year expiry (set above) — worth adding to whatever you already use to track *this* kind of thing. Yes, really.

You now have three values: **Tenant ID**, **Client ID**, **Certificate thumbprint**.

### Part 4 — Test the runner script manually

Before scheduling anything, run it once by hand on the server to confirm it works:

```powershell
cd C:\path\to\EntraAppExpiry\scripts
.\Invoke-AppExpiryCheck.ps1 `
    -TenantId '<tenant-id>' `
    -ClientId '<client-id>' `
    -CertificateThumbprint '<thumbprint>' `
    -ExpiringInDays 30
```

By default this writes a timestamped report (`AppExpiryReport_<date>_<time>.csv`) into a `Reports` folder next to the script. Pass `-OutputFolder` to send it somewhere else, and `-Format Html` for an HTML report instead of CSV. If nothing is expiring in the window, no file is written — you'll just see a message saying so.

### Part 5 — Register the scheduled task

Once the manual run works, register it to run automatically (also from an elevated PowerShell session on the server):

```powershell
.\Register-AppExpiryScheduledTask.ps1 `
    -TenantId '<tenant-id>' `
    -ClientId '<client-id>' `
    -CertificateThumbprint '<thumbprint>' `
    -OutputFolder 'C:\EntraAppExpiry\Reports' `
    -ExpiringInDays 30 `
    -At '07:00'
```

This creates a Task Scheduler task named **"EntraAppExpiry - Daily Credential Check"** that runs daily at the time you specify, as SYSTEM, calling `Invoke-AppExpiryCheck.ps1` with the arguments you gave it.

### Part 6 — Verify it

- Open **Task Scheduler** (`taskschd.msc`) → find the task under the Task Scheduler Library → check **History** after its first scheduled run (or right-click → **Run** to trigger it immediately).
- Check the output folder for a new report file.
- If it didn't run as expected, see Troubleshooting below.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Not connected to Microsoft Graph` | `Connect-AppExpiry` wasn't called first, or it failed silently — check for errors above it |
| Task Scheduler task shows "Last Run Result" as a failure, cert-related error | Certificate isn't in `LocalMachine\My` (SYSTEM can't read certs from a user's `CurrentUser` store) |
| `Import-Module EntraAppExpiry` fails when run by the scheduled task | The Graph modules were installed with `-Scope CurrentUser` under your own profile, which SYSTEM can't see — reinstall with `-Scope AllUsers`, or install for the account the task actually runs as |
| `Get-AppExpiry` runs but returns nothing unexpectedly | Check `-ExpiringInDays` — it excludes already-expired credentials by default; add `-IncludeExpired` to confirm data is there at all |
| App-only auth fails with a permissions error | `Application.Read.All` wasn't granted as an **application** permission, or admin consent wasn't completed |
