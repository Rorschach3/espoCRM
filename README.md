# Credit Repair CRM – EspoCRM Custom Module

A purpose-built EspoCRM extension for credit repair businesses.

## Features

| Feature | Description |
|---------|-------------|
| **Client Profiles** | Manage credit repair clients with personal info, credit scores, enrollment details |
| **Tradeline Tracking** | Track every tradeline per bureau with balance, status, and payment history |
| **Dispute Letters** | Organize, send and track dispute letters to Equifax, Experian, and TransUnion |
| **Billing & Payments** | Record payments, track total balance, amount paid, and outstanding balance |
| **Client Portal** | Portal-accessible views so clients can log in and see their own progress |
| **Monthly Status Emails** | Scheduled job sends automated monthly update emails to active clients |

---

## Entities

### `CrClient` – Credit Repair Client
Stores all client profile data for a credit repair engagement.

**Key fields:**
- Name, Email, Phone, Date of Birth, SSN (last 4), Address
- Credit Scores: Equifax, Experian, TransUnion
- Service Package (Basic / Standard / Premium)
- Enrollment Date, Expected Completion Date
- **Total Balance**, **Total Paid**, **Outstanding Balance** (auto-calculated)
- Last Payment Date, Next Payment Due Date
- Status: Active / Inactive / Completed / On Hold
- Monthly Status Sent flag

**Relationships:** Tradelines · Dispute Letters · Payments

---

### `CrTradeline` – Tradeline
Tracks individual credit accounts (tradelines) on a client's credit report.

**Key fields:**
- Creditor Name, Account Number, Account Type
- Bureau(s): Equifax / Experian / TransUnion (multi-select)
- Balance, Credit Limit
- Opened Date, Last Reported Date
- Dispute Status: Open / Closed / In Dispute / Removed / Verified
- Payment Status: Current / 30–120+ Days Late / Charged Off / Collection
- Remarks

**Relationships:** Client · Dispute Letters

---

### `CrDisputeLetter` – Dispute Letter
Manages the full lifecycle of credit dispute correspondence.

**Key fields:**
- Letter Type: Initial Dispute / Follow-Up / Debt Validation / Method of Verification / Goodwill Deletion / Pay for Delete / Cease and Desist / Identity Theft
- Bureau / Recipient: Equifax / Experian / TransUnion / All Bureaus / Creditor/CA
- Status: Draft → Sent → Responded → In Review → Resolved / Closed
- Sent Date, Response Deadline, Response Date
- Response Type: Deleted / Updated / Verified / No Response / Needs Investigation
- Letter Content (text)
- File Attachments

**Relationships:** Client · Tradeline

---

### `CrPayment` – Payment
Records payments received from clients.

**Key fields:**
- Payment Reference / Name
- Amount (currency)
- Payment Date, Payment Method
- Status: Pending / Completed / Failed / Refunded
- Transaction ID, Invoice Number
- Notes

**Relationships:** Client

---

## Client Portal

Clients can log in via the EspoCRM **Portal** to view:
- Their own client record (credit scores, billing summary)
- Their dispute letters and current statuses
- Their tradeline progress

### Portal Setup Steps

1. Log in to EspoCRM as Admin.
2. Go to **Administration → Portals → Create Portal**.
3. Name: `Client Portal`
4. In the **Roles** section, create a **Portal Role** with:
   - `CrClient`: Read (Own)
   - `CrTradeline`: Read (Own via Account)
   - `CrDisputeLetter`: Read (Own via Account)
   - `CrPayment`: Read (Own via Account)
5. Add the portal role to the portal.
6. Enable **Guest Login**: set the portal URL under **Custom ID** (e.g. `client-portal`).
7. Clients receive login credentials via their Portal User linked to `CrClient.portalUser`.

---

## Scheduled Job – Monthly Status Update

A scheduled job `SendMonthlyClientStatusUpdate` runs on the **1st of every month at 08:00** and:
1. Finds all **Active** `CrClient` records with an email address.
2. Sends a personalised plain-text email with:
   - Current credit scores (Equifax / Experian / TransUnion)
   - Outstanding balance and next payment due date
   - Expected programme completion date
3. Sets `monthlyStatusSent = true` and updates `lastStatusUpdateDate`.

**Activation:**
Go to **Administration → Scheduled Jobs** and ensure `Send Monthly Client Status Update` is **Active**.

---

## Installation

This module lives in the `custom/` directory of an EspoCRM installation.

```
custom/
└── Espo/
    └── Modules/
        └── CreditRepair/
```

After copying the files:
1. Go to **Administration → Rebuild** (or run `php command.php rebuild`).
2. The four new entities appear automatically in **Entity Manager** and the navigation.

---

## Module Information

| Property | Value |
|----------|-------|
| Module name | `CreditRepair` |
| Load order | `20` |
| EspoCRM version | 7.x – 9.x |
| Language | PHP 8.1+ |