<?php
require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

foreach (App\Models\Server::whereNull('status')->where('backup_limit', '>', 0)->get() as $server) {
    $daemon = app(App\Repositories\Daemon\DaemonServerRepository::class)->setServer($server);
    $state = $daemon->getDetails()['state'];
    $running = in_array($state, ['running', 'starting']);
    if (!$running && $state !== 'offline') throw new RuntimeException("{$server->name} is busy");
    try {
        if ($running) {
            $daemon->power('stop')->throw();
            $deadline = time() + 180;
            while ($daemon->getDetails()['state'] !== 'offline') {
                if (time() >= $deadline) throw new RuntimeException("{$server->name} did not stop");
                sleep(2);
            }
        }
        $backup = app(App\Services\Backups\InitiateBackupService::class)
            ->setIsScheduled(true)->handle($server, 'Daily backup', true);
        $deadline = time() + 2700;
        while (!$backup->refresh()->completed_at) {
            if (time() >= $deadline) throw new RuntimeException("{$server->name} backup timed out");
            sleep(5);
        }
        if (!$backup->is_successful) throw new RuntimeException("{$server->name} backup failed");
        echo "{$server->name}: backup completed\n";
    } finally {
        if ($running) $daemon->power('start')->throw();
    }
}
