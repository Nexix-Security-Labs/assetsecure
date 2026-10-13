<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Artisan;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        //
        Artisan::call('assetsecure:clean-checkout-acceptances');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
