<?php

namespace Espo\Modules\CreditRepair\Hooks\CrClient;

use Espo\ORM\Entity;

class CalculateBalance
{
    public static int $order = 9;

    public function beforeSave(Entity $entity, array $options): void
    {
        $totalBalance = (float) ($entity->get('totalBalance') ?? 0.0);
        $totalPaid    = (float) ($entity->get('totalPaid') ?? 0.0);

        $outstanding = max(0.0, $totalBalance - $totalPaid);

        $entity->set('outstandingBalance', $outstanding);

        $currency = $entity->get('totalBalanceCurrency') ?? 'USD';
        $entity->set('outstandingBalanceCurrency', $currency);
    }
}
