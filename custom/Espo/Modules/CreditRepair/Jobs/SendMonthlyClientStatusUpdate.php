<?php

namespace Espo\Modules\CreditRepair\Jobs;

use Espo\Core\Job\JobDataLess;
use Espo\ORM\EntityManager;
use Espo\Core\Mail\EmailSender;
use Espo\Core\Utils\Config;

/**
 * Sends monthly status update emails to all active Credit Repair clients.
 * Schedule: 0 8 1 * * (first day of every month at 08:00)
 */
class SendMonthlyClientStatusUpdate implements JobDataLess
{
    public function __construct(
        private EntityManager $entityManager,
        private EmailSender   $emailSender,
        private Config        $config,
    ) {}

    public function run(): void
    {
        $clients = $this->entityManager
            ->getRDBRepository('CrClient')
            ->where(['status' => 'Active'])
            ->find();

        foreach ($clients as $client) {
            $emailAddress = $client->get('emailAddress');

            if (!$emailAddress) {
                continue;
            }

            $this->sendStatusEmail($client, $emailAddress);

            $client->set('monthlyStatusSent', true);
            $client->set('lastStatusUpdateDate', date('Y-m-d'));
            $this->entityManager->saveEntity($client, ['silent' => true]);
        }
    }

    private function sendStatusEmail(object $client, string $emailAddress): void
    {
        $clientName       = $client->get('name') ?? 'Valued Client';
        $status           = $client->get('status') ?? 'Active';
        $equifax          = $client->get('creditScoreEquifax');
        $experian         = $client->get('creditScoreExperian');
        $transUnion       = $client->get('creditScoreTransUnion');
        $outstanding      = $client->get('outstandingBalance') ?? 0;
        $currency         = $client->get('outstandingBalanceCurrency')
                         ?? $client->get('totalBalanceCurrency')
                         ?? 'USD';
        $nextPayment      = $client->get('nextPaymentDueDate');
        $expectedComplete = $client->get('expectedCompletionDate');

        $scoreLines = [];
        if ($equifax)   { $scoreLines[] = "  • Equifax:     {$equifax}"; }
        if ($experian)  { $scoreLines[] = "  • Experian:    {$experian}"; }
        if ($transUnion){ $scoreLines[] = "  • TransUnion:  {$transUnion}"; }
        $scoresText = $scoreLines
            ? "Current Credit Scores:\n" . implode("\n", $scoreLines)
            : '';

        $outstandingFormatted = number_format((float) $outstanding, 2);
        $nextPaymentText = $nextPayment ? "Next Payment Due: {$nextPayment}" : '';
        $expectedText    = $expectedComplete ? "Expected Completion: {$expectedComplete}" : '';

        $month = date('F Y');

        $body = <<<TEXT
Dear {$clientName},

Here is your Credit Repair Monthly Status Update for {$month}.

Program Status: {$status}
{$scoresText}

Account Balance:
  Outstanding Balance: {$currency} {$outstandingFormatted}
  {$nextPaymentText}

{$expectedText}

We are actively working on your credit repair case. Your dispute letters are
being tracked and we will notify you of any updates from the credit bureaus.

If you have questions, please log in to your client portal or reply to this email.

Thank you for trusting us with your credit repair journey.

Best regards,
Your Credit Repair Team
TEXT;

        $email = $this->entityManager->getNewEntity('Email');
        $email->set([
            'to'      => $emailAddress,
            'subject' => "Your Credit Repair Monthly Update – {$month}",
            'body'    => $body,
            'isHtml'  => false,
        ]);

        try {
            $this->emailSender->send($email);
        } catch (\Throwable) {
            // Log silently; individual failures must not abort the job loop.
        }
    }
}
