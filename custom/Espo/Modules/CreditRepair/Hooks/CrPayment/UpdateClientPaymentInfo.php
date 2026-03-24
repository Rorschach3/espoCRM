<?php

namespace Espo\Modules\CreditRepair\Hooks\CrPayment;

use Espo\ORM\Entity;
use Espo\ORM\EntityManager;

class UpdateClientPaymentInfo
{
    public static int $order = 10;

    public function __construct(private EntityManager $entityManager) {}

    public function afterSave(Entity $entity, array $options): void
    {
        $clientId = $entity->get('crClientId');

        if (!$clientId) {
            return;
        }

        $client = $this->entityManager->getEntityById('CrClient', $clientId);

        if (!$client) {
            return;
        }

        $paymentDate = $entity->get('paymentDate');
        $status      = $entity->get('status');

        if ($status === 'Completed' && $paymentDate) {
            $existingDate = $client->get('lastPaymentDate');

            if (!$existingDate || $paymentDate > $existingDate) {
                $client->set('lastPaymentDate', $paymentDate);
            }
        }

        $totalPaid = $this->calculateTotalPaid($clientId);
        $client->set('totalPaid', $totalPaid);

        $this->entityManager->saveEntity($client, ['skipHooks' => true]);
    }

    private function calculateTotalPaid(string $clientId): float
    {
        $collection = $this->entityManager
            ->getRDBRepository('CrPayment')
            ->where([
                'crClientId' => $clientId,
                'status'     => 'Completed',
            ])
            ->find();

        $total = 0.0;

        foreach ($collection as $payment) {
            $total += (float) ($payment->get('amount') ?? 0.0);
        }

        return $total;
    }
}
