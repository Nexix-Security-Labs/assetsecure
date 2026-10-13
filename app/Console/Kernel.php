<?php

namespace App\Console;

use App\Models\Setting;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     *
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        if (Setting::getSettings()?->alerts_enabled === 1) {
            $schedule->command('assetsecure:inventory-alerts')->daily();
            $schedule->command('assetsecure:expiring-alerts')->daily();
            $schedule->command('assetsecure:expected-checkin')->daily();
            $schedule->command('assetsecure:upcoming-audits')->daily();
        }
        $schedule->command('assetsecure:backup')->weekly();
        $schedule->command('backup:clean')->daily();
        $schedule->command('auth:clear-resets')->everyFifteenMinutes();
        $schedule->command('saml:clear_expired_nonces')->weekly();
        
        $schedule->command('assetsecure:pull-inventory')
            ->daily()
            ->withoutOverlapping();

        // Push runs a few hours offset from the pull so the two
        // don't stack on a single Laravel scheduler tick if a slow
        // adapter's pull runs long.
        $schedule->command('assetsecure:push-inventory')
            ->dailyAt('03:00')
            ->withoutOverlapping();
    }

    /**
     * This method is required by Laravel to handle any console routes
     * that are defined in routes/console.php.
     */
    protected function commands()
    {
        require base_path('routes/console.php');
        $this->load(__DIR__.'/Commands');
    }
}
