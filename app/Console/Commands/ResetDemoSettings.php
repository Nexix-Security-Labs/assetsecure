<?php

namespace App\Console\Commands;

use App\Models\Setting;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class ResetDemoSettings extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'assetsecure:demo-settings';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'This will reset the AssetSecure demo settings back to default. ';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {

        $this->info('Resetting the demo settings.');
        $settings = Setting::first();
        $settings->per_page = 20;
        $settings->site_name = 'AssetSecure Asset Management Demo';
        $settings->auto_increment_assets = 1;
        $settings->logo = 'assetsecure-logo.png';
        $settings->alert_email = 'admin@example.com';
        $settings->login_note = "Use any of the following credentials to login to the demo:\n\n- `admin` / `password`\n- `assets` / `password`\n- `testuser` / `password`";
        $settings->header_color = '#0096ff';
        $settings->link_dark_color = '#5fa4cc';
        $settings->link_light_color = '#296282;';
        $settings->nav_link_color = '#FFFFFF';
        $settings->label2_2d_type = 'QRCODE';
        $settings->default_currency = 'USD';
        $settings->brand = 2;
        // Enabled so the wizard's return-visitor branch unlocks all 5
        // steps for demo visitors and they can jump straight to the
        // step-3 Test Find User preview against the seeded Forumsys
        // config. Safe on the demo because LoginController skips the
        // LDAP auth branch when config('app.lock_passwords') is on.
        $settings->ldap_enabled = '1';
        $settings->full_multiple_companies_support = 0;
        $settings->label2_1d_type = 'C128';
        $settings->email_domain = 'example.com';
        $settings->email_format = 'filastname';
        $settings->username_format = 'filastname';
        $settings->date_display_format = 'D M d, Y';
        $settings->time_display_format = 'g:iA';
        $settings->thumbnail_max_h = '30';
        $settings->locale = 'en-US';
        $settings->version_footer = 'on';
        $settings->support_footer = 'on';
        $settings->saml_enabled = '0';
        $settings->saml_sp_x509cert = null;
        $settings->saml_idp_metadata = null;
        $settings->saml_attr_mapping_username = null;
        $settings->saml_forcelogin = '0';
        $settings->saml_slo = null;
        $settings->saml_custom_settings = null;
        $settings->default_avatar = 'default.png';

        $settings->save();

        if ($user = User::where('username', '=', 'admin')->first()) {
            $user->locale = 'en-US';
            $user->enable_confetti = 1;
            $user->enable_sounds = 1;
            $user->save();
        }

        $assetsUser = User::updateOrCreate(
            ['username' => 'assets'],
            [
                'first_name' => 'Assets',
                'last_name' => 'User',
                'password' => Hash::make('password'),
                'activated' => 1,
            ]
        );
        $assetsUser->permissions = json_encode([
            'assets.view' => 1,
            'assets.create' => 1,
            'assets.edit' => 1,
            'assets.delete' => 1,
            'assets.checkout' => 1,
            'assets.checkin' => 1,
            'assets.audit' => 1,
            'assets.files' => 1,
            'assets.view.requestable' => 1,
            'assets.view.encrypted_custom_fields' => 1,
        ]);
        $assetsUser->save();

        $testUser = User::updateOrCreate(
            ['username' => 'testuser'],
            [
                'first_name' => 'Test',
                'last_name' => 'User',
                'password' => Hash::make('password'),
                'activated' => 1,
            ]
        );
        $testUser->permissions = json_encode([
            'self.checkout_assets' => 1,
            'assets.view.requestable' => 1,
        ]);
        $testUser->save();

        \Storage::disk('public')->put('assetsecure-logo.png', file_get_contents(public_path('img/demo/assetsecure-logo.png')));
        \Storage::disk('public')->put('assetsecure-logo-lg.png', file_get_contents(public_path('img/demo/assetsecure-logo-lg.png')));

    }
}
