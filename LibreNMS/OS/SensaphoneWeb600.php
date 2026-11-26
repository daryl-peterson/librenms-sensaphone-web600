<?php

namespace LibreNMS\OS;

use App\Models\Sensor;
use Illuminate\Support\Collection;
use LibreNMS\OS;
use LibreNMS\Util\UserFuncHelper;
use SnmpQuery;

class SensaphoneWeb600 extends OS
{
    private const string INPUT_TABLE = '.1.3.6.1.4.1.8338.1.1.4.1.1.1';

    /** @return Collection<int, Sensor> */
    protected function discoverOsSensors(): Collection
    {
        $sensors = new Collection;
        $query = SnmpQuery::device($this->getDevice())->numeric();

        // The device puts the input row before the field. Rows 1 and 2 are internal power and battery.
        foreach (range(3, 8) as $row) {
            $input = self::INPUT_TABLE . ".$row";
            if ((string) $query->get("$input.21")->value() !== '2') {
                continue;
            }

            $zone = $row - 2;
            $name = trim((string) $query->get("$input.15")->value()) ?: "Zone $zone";
            $type = (int) $query->get("$input.18")->value();
            $status = $query->get("$input.50")->value();
            $common = [
                'poller_type' => 'snmp',
                'sensor_index' => $zone,
                'sensor_divisor' => 1,
                'sensor_multiplier' => 1,
                'rrd_type' => 'GAUGE',
            ];

            if (in_array((string) $status, ['1', '2', '3'], true)) {
                $contact = in_array($type, [1, 2], true);
                $sensors->push((new Sensor($common + [
                    'sensor_class' => 'state',
                    'sensor_oid' => "$input.50",
                    'sensor_type' => $contact ? 'sensaphone-web600-contact' : 'sensaphone-web600-input',
                    'sensor_descr' => "$name Status",
                    'sensor_current' => (int) $status,
                ]))->withStates([
                    ['value' => 1, 'generic' => 0, 'descr' => 'OK'],
                    ['value' => 2, 'generic' => 2, 'descr' => $contact ? 'Closed Alarm' : 'Low Alarm'],
                    ['value' => 3, 'generic' => 2, 'descr' => $contact ? 'Open Alarm' : 'High Alarm'],
                ]));
            }

            if (! in_array($type, [3, 4, 5, 6], true)) {
                continue;
            }

            $reading = $query->get("$input.48")->value();
            if (is_numeric($reading)) {
                $fahrenheit = in_array($type, [3, 5], true);
                $sensors->push(new Sensor($common + [
                    'sensor_class' => 'temperature',
                    'sensor_oid' => "$input.48",
                    'sensor_type' => 'sensaphone-web600',
                    'sensor_descr' => $name,
                    'sensor_current' => $fahrenheit ? UserFuncHelper::apply('fahrenheit_to_celsius', (float) $reading) : (float) $reading,
                    'user_func' => $fahrenheit ? 'fahrenheit_to_celsius' : null,
                ]));
            }
        }

        return $sensors;
    }
}
